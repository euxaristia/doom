@[translated]
module main

// Common networking hooks: minimal manual port.

fn C.fopen(&i8, &i8) voidptr
fn C.fclose(voidptr) int
fn C.fputs(&i8, voidptr) int
fn C.fflush(voidptr) int

@[c: 'I_Error']
@[c2v_variadic]
fn i_error(error &i8, ...)

const max_retries = 5
const net_reliable_packet = u32(1 << 15)

enum Net_connstate_t {
	net_conn_state_connecting
	net_conn_state_connected
	net_conn_state_disconnecting
	net_conn_state_disconnected
	net_conn_state_disconnected_sleep
}

enum Net_disconnect_reason_t {
	net_disconnect_local
	net_disconnect_remote
	net_disconnect_timeout
}

struct Net_reliable_packet_t {
mut:
	packet         &Net_packet_t
	last_send_time int
	seq            int
	next           &Net_reliable_packet_t
}

struct Net_connection_t {
mut:
	state               Net_connstate_t
	disconnect_reason   Net_disconnect_reason_t
	addr                &Net_addr_t
	protocol            Net_protocol_t
	last_send_time      int
	num_retries         int
	keepalive_send_time int
	keepalive_recv_time int
	reliable_packets    &Net_reliable_packet_t
	reliable_send_seq   int
	reliable_recv_seq   int
}

@[weak]
__global (
	net_inited bool
	net_debug  voidptr
)

@[export: 'NetUpdate']
pub fn net_update_export() {
	// No-op placeholder.
}

@[export: 'NET_Init']
pub fn net_init_export() {
	net_inited = true
}

@[export: 'NET_OpenLog']
pub fn net_open_log() {
	p := m_check_parm_with_args(c'-netlog', 1)
	if p <= 0 {
		return
	}
	if net_debug != unsafe { nil } {
		C.fclose(net_debug)
		net_debug = unsafe { nil }
	}
	net_debug = C.fopen(&i8(myargv[p + 1]), c'w')
	if net_debug == unsafe { nil } {
		i_error(c'Failed to open %s to write debug log.', &i8(myargv[p + 1]))
	}
}

@[export: 'NET_BindVariables']
pub fn net_bind_variables_export() {
	// No-op placeholder.
}

@[export: 'NET_Conn_SendPacket']
pub fn net_conn_send_packet(conn &Net_connection_t, packet &Net_packet_t) {
	if conn == unsafe { nil } || packet == unsafe { nil } || conn.addr == unsafe { nil } {
		return
	}
	conn.keepalive_send_time = i_get_time_ms()
	net_send_packet(conn.addr, packet)
}

fn net_conn_init(conn &Net_connection_t, addr &Net_addr_t, protocol Net_protocol_t) {
	conn.last_send_time = -1
	conn.num_retries = 0
	conn.addr = addr
	conn.protocol = protocol
	conn.reliable_packets = unsafe { nil }
	conn.reliable_send_seq = 0
	conn.reliable_recv_seq = 0
	conn.keepalive_recv_time = i_get_time_ms()
}

fn net_conn_parse_disconnect(conn &Net_connection_t) {
	reply := net_new_packet(10)
	net_write_int16(reply, u32(Net_packet_type_t.net_packet_type_disconnect_ack))
	net_conn_send_packet(conn, reply)
	net_free_packet(reply)
	conn.last_send_time = i_get_time_ms()
	conn.state = .net_conn_state_disconnected_sleep
	conn.disconnect_reason = .net_disconnect_remote
}

fn net_conn_parse_disconnect_ack(conn &Net_connection_t) {
	if conn.state == .net_conn_state_disconnecting {
		conn.state = .net_conn_state_disconnected
		conn.disconnect_reason = .net_disconnect_local
		conn.last_send_time = -1
	}
}

fn net_conn_parse_reliable_ack(conn &Net_connection_t, packet &Net_packet_t) {
	mut seq := u32(0)
	if !net_read_int8(packet, &seq) {
		return
	}
	if conn.reliable_packets == unsafe { nil } {
		return
	}
	if seq == u32((conn.reliable_packets.seq + 1) & 0xff) {
		rp := conn.reliable_packets
		conn.reliable_packets = rp.next
		net_free_packet(rp.packet)
	}
}

@[export: 'NET_Conn_InitClient']
pub fn net_conn_init_client(conn &Net_connection_t, addr &Net_addr_t, protocol Net_protocol_t) {
	net_conn_init(conn, addr, protocol)
	conn.state = .net_conn_state_connecting
}

@[export: 'NET_Conn_InitServer']
pub fn net_conn_init_server(conn &Net_connection_t, addr &Net_addr_t, protocol Net_protocol_t) {
	net_conn_init(conn, addr, protocol)
	conn.state = .net_conn_state_connected
}

@[export: 'NET_Conn_Packet']
pub fn net_conn_packet(conn &Net_connection_t, packet &Net_packet_t, packet_type &u32) bool {
	conn.keepalive_recv_time = i_get_time_ms()
	if ((*packet_type) & net_reliable_packet) != 0 {
		mut seq := u32(0)
		if !net_read_int8(packet, &seq) {
			return true
		}
		if seq != u32(conn.reliable_recv_seq & 0xff) {
			reply := net_new_packet(10)
			net_write_int16(reply, u32(Net_packet_type_t.net_packet_type_reliable_ack))
			net_write_int8(reply, u32(conn.reliable_recv_seq & 0xff))
			net_conn_send_packet(conn, reply)
			net_free_packet(reply)
			return true
		}
		conn.reliable_recv_seq = (conn.reliable_recv_seq + 1) & 0xff
		reply := net_new_packet(10)
		net_write_int16(reply, u32(Net_packet_type_t.net_packet_type_reliable_ack))
		net_write_int8(reply, u32(conn.reliable_recv_seq & 0xff))
		net_conn_send_packet(conn, reply)
		net_free_packet(reply)
		unsafe {
			*packet_type &= ~net_reliable_packet
		}
	}
	match Net_packet_type_t(*packet_type) {
		.net_packet_type_disconnect {
			net_conn_parse_disconnect(conn)
			return true
		}
		.net_packet_type_disconnect_ack {
			net_conn_parse_disconnect_ack(conn)
			return true
		}
		.net_packet_type_keepalive {
			return true
		}
		.net_packet_type_reliable_ack {
			net_conn_parse_reliable_ack(conn, packet)
			return true
		}
		else {}
	}
	return false
}

@[export: 'NET_Conn_Disconnect']
pub fn net_conn_disconnect(conn &Net_connection_t) {
	if conn == unsafe { nil } {
		return
	}
	if conn.state != .net_conn_state_disconnected && conn.state != .net_conn_state_disconnecting
		&& conn.state != .net_conn_state_disconnected_sleep {
		conn.state = .net_conn_state_disconnecting
		conn.disconnect_reason = .net_disconnect_local
		conn.last_send_time = -1
		conn.num_retries = 0
	}
}

@[export: 'NET_Conn_Run']
pub fn net_conn_run(conn &Net_connection_t) {
	if conn == unsafe { nil } {
		return
	}
	nowtime := i_get_time_ms()
	if conn.state == .net_conn_state_connected {
		if nowtime - conn.keepalive_recv_time > 30000 {
			conn.state = .net_conn_state_disconnected
			conn.disconnect_reason = .net_disconnect_timeout
		}
		if nowtime - conn.keepalive_send_time > 1000 {
			packet := net_new_packet(10)
			net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_keepalive))
			net_conn_send_packet(conn, packet)
			net_free_packet(packet)
		}
		if conn.reliable_packets != unsafe { nil } {
			if conn.reliable_packets.last_send_time < 0
				|| nowtime - conn.reliable_packets.last_send_time > 1000 {
				net_conn_send_packet(conn, conn.reliable_packets.packet)
				conn.reliable_packets.last_send_time = nowtime
			}
		}
	} else if conn.state == .net_conn_state_disconnecting {
		if conn.last_send_time < 0 || nowtime - conn.last_send_time > 1000 {
			if conn.num_retries < max_retries {
				packet := net_new_packet(10)
				net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_disconnect))
				net_conn_send_packet(conn, packet)
				net_free_packet(packet)
				conn.last_send_time = nowtime
				conn.num_retries++
			} else {
				conn.state = .net_conn_state_disconnected
				conn.disconnect_reason = .net_disconnect_local
			}
		}
	} else if conn.state == .net_conn_state_disconnected_sleep {
		if nowtime - conn.last_send_time > 5000 {
			conn.state = .net_conn_state_disconnected
			conn.disconnect_reason = .net_disconnect_remote
		}
	}
}

@[export: 'NET_Conn_NewReliable']
pub fn net_conn_new_reliable(conn &Net_connection_t, packet_type int) &Net_packet_t {
	packet := net_new_packet(100)
	net_write_int16(packet, u32(packet_type) | net_reliable_packet)
	seq := conn.reliable_send_seq
	net_write_int8(packet, u32(seq & 0xff))
	rp := &Net_reliable_packet_t{
		packet:         packet
		next:           unsafe { nil }
		seq:            seq
		last_send_time: -1
	}
	if conn.reliable_packets == unsafe { nil } {
		conn.reliable_packets = rp
	} else {
		mut cur := conn.reliable_packets
		for cur.next != unsafe { nil } {
			cur = cur.next
		}
		cur.next = rp
	}
	conn.reliable_send_seq = (conn.reliable_send_seq + 1) & 0xff
	return packet
}

@[export: 'NET_ExpandTicNum']
pub fn net_expand_tic_num(relative u32, b u32) u32 {
	h := relative & ~u32(0xff)
	l := relative & u32(0xff)
	mut result := h | (b & u32(0xff))
	if l < 0x40 && b > 0xb0 {
		result -= 0x100
	}
	if l > 0xb0 && b < 0x40 {
		result += 0x100
	}
	return result
}

@[export: 'NET_ValidGameSettings']
pub fn net_valid_game_settings(mode GameMode_t, mission GameMission_t, settings &Net_gamesettings_t) bool {
	if settings.ticdup <= 0 {
		return false
	}
	if settings.extratics < 0 {
		return false
	}
	if settings.deathmatch < 0 || settings.deathmatch > 3 {
		return false
	}
	if settings.skill < int(Skill_t.sk_noitems) || settings.skill > int(Skill_t.sk_nightmare) {
		return false
	}
	if !d_valid_game_version(mission, GameVersion_t(settings.gameversion)) {
		return false
	}
	if !d_valid_episode_map(mission, mode, settings.episode, settings.map_) {
		return false
	}
	return true
}

@[export: 'NET_Log']
@[c2v_variadic]
pub fn net_log(fmt &i8, ...) {
	if net_debug == unsafe { nil } {
		return
	}
	line := '${i_get_time_ms():8}: ${cstring(fmt)}\n'
	C.fputs(line.str, net_debug)
	C.fflush(net_debug)
}

@[export: 'NET_LogPacket']
pub fn net_log_packet(packet &Net_packet_t) {
	if net_debug == unsafe { nil } {
		return
	}
	bytes := int(packet.len) - int(packet.pos)
	if bytes <= 0 {
		return
	}
	mut line := '\t'
	for i := 0; i < bytes; i++ {
		if i > 0 {
			if (i % 16) == 0 {
				line += '\n\t'
			} else {
				line += ' '
			}
		}
		b := unsafe { packet.data[packet.pos + u32(i)] }
		line += '${b:02x}'
	}
	line += '\n'
	C.fputs(line.str, net_debug)
	C.fflush(net_debug)
}
