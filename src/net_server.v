@[translated]
module main

// Network server support (first-pass translated scaffold).

const net_magic_number = u32(1454104972)
const net_old_magic_number = u32(3436803284)

@[weak]
__global (
	server_context      &Net_context_t
	server_master       &Net_addr_t
	server_state        int
	last_master_refresh int
	server_clients      []&Net_addr_t
	last_activity_ms    int
)

const master_refresh_period_secs = 30
const server_waiting_launch = 0
const server_waiting_start = 1
const server_in_game = 2

@[export: 'NET_SV_Init']
pub fn net_sv_init() {
	if server_context == unsafe { nil } {
		server_context = net_new_context()
	}
	server_state = server_waiting_launch
	server_clients = []&Net_addr_t{}
}

@[export: 'NET_SV_AddModule']
pub fn net_sv_add_module(module_ &Net_module_t) {
	if server_context == unsafe { nil } {
		net_sv_init()
	}
	net_add_module(server_context, module_)
	module_.initServer()
}

@[export: 'NET_SV_RegisterWithMaster']
pub fn net_sv_register_with_master() {
	if server_context == unsafe { nil } {
		return
	}
	if server_master != unsafe { nil } {
		net_release_address(server_master)
		server_master = unsafe { nil }
	}
	server_master = net_query_resolve_master(server_context)
	if server_master != unsafe { nil } {
		net_query_add_to_master(server_master)
	}
}

@[export: 'NET_SV_SendQueryResponse']
pub fn net_sv_send_query_response(addr &Net_addr_t) {
	if server_context == unsafe { nil } {
		return
	}
	mut query := Net_querydata_t{}
	query.version = c'vdoom'
	query.server_state = server_state
	query.num_players = server_clients.len
	query.max_players = 8
	query.gamemode = int(GameMode_t.indetermined)
	query.gamemission = int(GameMission_t.none_)
	query.description = c'V DOOM server'
	query.protocol = .net_protocol_chocolate_doom_0
	packet := net_new_packet(96)
	net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_query_response))
	net_write_query_data(packet, &query)
	net_send_packet(addr, packet)
	net_free_packet(packet)
}

fn net_sv_send_reject(addr &Net_addr_t, msg &i8) {
	packet := net_new_packet(64)
	net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_rejected))
	net_write_string(packet, msg)
	net_send_packet(addr, packet)
	net_free_packet(packet)
}

fn net_sv_client_index(addr &Net_addr_t) int {
	for i, a in server_clients {
		if a == addr {
			return i
		}
	}
	return -1
}

fn net_sv_add_client(addr &Net_addr_t) {
	if addr == unsafe { nil } {
		return
	}
	if net_sv_client_index(addr) >= 0 {
		return
	}
	net_reference_address(addr)
	server_clients << addr
}

fn net_sv_parse_launch(addr &Net_addr_t) {
	if server_clients.len == 0 || addr != server_clients[0] {
		return
	}
	if server_state != server_waiting_launch {
		return
	}
	server_state = server_waiting_start
	for client_addr in server_clients {
		packet := net_new_packet(8)
		net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_launch))
		net_write_int8(packet, u32(server_clients.len))
		net_send_packet(client_addr, packet)
		net_free_packet(packet)
	}

	// First-pass start broadcast immediately after launch.
	mut settings := Net_gamesettings_t{}
	settings.num_players = server_clients.len
	settings.consoleplayer = 0
	settings.gameversion = int(GameVersion_t.exe_final2)
	settings.skill = int(Skill_t.sk_medium)
	settings.episode = 1
	settings.map_ = 1
	settings.ticdup = 1
	for client_addr in server_clients {
		packet := net_new_packet(96)
		net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_gamestart))
		net_write_settings(packet, &settings)
		net_send_packet(client_addr, packet)
		net_free_packet(packet)
	}
	server_state = server_in_game
}

fn net_sv_parse_gamedata(addr &Net_addr_t, packet &Net_packet_t) {
	mut recv_seq_low := u32(0)
	mut start_low := u32(0)
	mut num_tics := u32(0)
	if !net_read_int8(packet, &recv_seq_low) || !net_read_int8(packet, &start_low)
		|| !net_read_int8(packet, &num_tics) {
		return
	}
	for _ in 0 .. int(num_tics) {
		mut latency := u32(0)
		if !net_read_int16(packet, &latency) {
			return
		}
		mut diff := Net_ticdiff_t{}
		if !net_read_ticcmd_diff(packet, &diff, false) {
			return
		}
	}
	_ = recv_seq_low
	_ = start_low
	_ = addr
}

fn net_sv_parse_gamedata_ack(packet &Net_packet_t) {
	mut ack_low := u32(0)
	if !net_read_int8(packet, &ack_low) {
		return
	}
	_ = ack_low
}

fn net_sv_parse_resend_request(packet &Net_packet_t) {
	mut start := u32(0)
	mut num_tics := u32(0)
	if !net_read_int32(packet, &start) || !net_read_int8(packet, &num_tics) {
		return
	}
	_ = start
	_ = num_tics
}

fn net_sv_parse_hole_punch(packet &Net_packet_t) {
	addr_string := net_read_string(packet)
	if addr_string == unsafe { nil } {
		return
	}
	addr := net_resolve_address(server_context, addr_string)
	if addr == unsafe { nil } {
		return
	}
	sendpacket := net_new_packet(16)
	net_write_int16(sendpacket, u32(Net_packet_type_t.net_packet_type_nat_hole_punch))
	net_send_packet(addr, sendpacket)
	net_free_packet(sendpacket)
	net_release_address(addr)
}

fn net_sv_master_packet(packet &Net_packet_t) {
	mut packet_type := u32(0)
	if !net_read_int16(packet, &packet_type) {
		return
	}
	match Net_master_packet_type_t(packet_type) {
		.net_master_packet_type_add_response {
			net_query_add_response(packet)
		}
		.net_master_packet_type_nat_hole_punch {
			net_sv_parse_hole_punch(packet)
		}
		else {}
	}
}

fn net_sv_parse_syn(addr &Net_addr_t, packet &Net_packet_t) {
	mut magic := u32(0)
	if !net_read_int32(packet, &magic) {
		return
	}
	if magic == net_old_magic_number {
		net_sv_send_reject(addr, c'You are using an old client version that is not supported by this server.')
		return
	}
	if magic != net_magic_number {
		return
	}
	client_version := net_read_string(packet)
	if client_version == unsafe { nil } {
		return
	}
	protocol := net_read_protocol_list(packet)
	if protocol == .net_protocol_unknown {
		net_sv_send_reject(addr, c'Version mismatch: no common compatible protocol.')
		return
	}
	mut data := Net_connect_data_t{}
	if !net_read_connect_data(packet, &data) {
		return
	}
	if !d_valid_game_mode(GameMission_t(data.gamemission), GameMode_t(data.gamemode))
		|| data.max_players > 8 {
		net_sv_send_reject(addr, c'Invalid game parameters.')
		return
	}
	player_name := net_read_string(packet)
	if player_name == unsafe { nil } {
		return
	}
	_ = player_name
	reply := net_new_packet(64)
	net_write_int16(reply, u32(Net_packet_type_t.net_packet_type_syn))
	net_write_string(reply, c'vdoom')
	net_write_protocol(reply, protocol)
	net_send_packet(addr, reply)
	net_free_packet(reply)
	net_sv_add_client(addr)
}

@[export: 'NET_SV_Run']
pub fn net_sv_run() {
	if server_context == unsafe { nil } {
		return
	}
	// Keep master registration alive.
	now := i_get_time_ms()
	if last_activity_ms == 0 {
		last_activity_ms = now
	}
	if server_master != unsafe { nil }
		&& (now - last_master_refresh) > (master_refresh_period_secs * 1000) {
		net_query_add_to_master(server_master)
		last_master_refresh = now
	}
	for {
		mut addr := &Net_addr_t(unsafe { nil })
		mut packet := &Net_packet_t(unsafe { nil })
		if !net_recv_packet(server_context, &addr, &packet) {
			break
		}
		last_activity_ms = now
		if addr == server_master {
			net_sv_master_packet(packet)
		} else {
			mut packet_type := u32(0)
			if net_read_int16(packet, &packet_type) {
				match Net_packet_type_t(packet_type) {
					.net_packet_type_query {
						net_sv_send_query_response(addr)
					}
					.net_packet_type_syn {
						net_sv_parse_syn(addr, packet)
					}
					.net_packet_type_launch {
						net_sv_parse_launch(addr)
					}
					.net_packet_type_gamedata {
						net_sv_parse_gamedata(addr, packet)
					}
					.net_packet_type_gamedata_ack {
						net_sv_parse_gamedata_ack(packet)
					}
					.net_packet_type_gamedata_resend {
						net_sv_parse_resend_request(packet)
					}
					else {}
				}
			}
		}
		net_release_address(addr)
		net_free_packet(packet)
	}

	// Deadlock nudge: if no traffic for a while, keepalive-run all connections.
	if now - last_activity_ms > 1000 {
		for client_addr in server_clients {
			_ = client_addr
			// Placeholder hook for per-client deadlock checks.
			net_sv_check_deadlock(unsafe { nil })
		}
		last_activity_ms = now
	}
}

@[export: 'NET_SV_Shutdown']
pub fn net_sv_shutdown() {
	if server_master != unsafe { nil } {
		net_release_address(server_master)
		server_master = unsafe { nil }
	}
	for addr in server_clients {
		net_release_address(addr)
	}
	server_clients = []&Net_addr_t{}
	server_context = unsafe { nil }
	server_state = 0
	last_activity_ms = 0
}

@[export: 'NET_SV_CheckDeadlock']
pub fn net_sv_check_deadlock(_client voidptr) {
	_ = _client
	// Full deadlock algorithm depends on full recv/send windows;
	// first pass keeps the symbol and call path present.
}
