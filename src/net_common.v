@[translated]
module main

// Common networking hooks: minimal manual port.

const max_retries = 5

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
	// Minimal port: keep hook present; file logging can be added later.
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
	_ = conn
	_ = packet
	_ = packet_type
	// First-pass: no packet types consumed by common layer.
	return false
}

@[export: 'NET_Conn_Disconnect']
pub fn net_conn_disconnect(conn &Net_connection_t) {
	if conn == unsafe { nil } {
		return
	}
	conn.state = .net_conn_state_disconnected
	conn.disconnect_reason = .net_disconnect_local
}

@[export: 'NET_Conn_Run']
pub fn net_conn_run(conn &Net_connection_t) {
	if conn == unsafe { nil } {
		return
	}
	// Minimal timeout handling.
	if conn.state == .net_conn_state_connected {
		if i_get_time_ms() - conn.keepalive_recv_time > 30000 {
			conn.state = .net_conn_state_disconnected
			conn.disconnect_reason = .net_disconnect_timeout
		}
	}
}

@[export: 'NET_Conn_NewReliable']
pub fn net_conn_new_reliable(conn &Net_connection_t, packet_type int) &Net_packet_t {
	packet := net_new_packet(16)
	net_write_int16(packet, u32(packet_type))
	if conn != unsafe { nil } {
		conn.reliable_send_seq = (conn.reliable_send_seq + 1) & 0xff
		net_write_int8(packet, u32(conn.reliable_send_seq))
	}
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
pub fn net_log(_fmt &i8, ...) {
	_ = _fmt
}

@[export: 'NET_LogPacket']
pub fn net_log_packet(_packet &Net_packet_t) {
	_ = _packet
}
