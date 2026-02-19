@[translated]
module main

// Network client state scaffold.

const net_magic_number = u32(1454104972)
const vdoom_package_string = c'vdoom'

enum Net_clientstate_t {
	client_state_waiting_launch
	client_state_waiting_start
	client_state_in_game
}

@[weak]
__global (
	net_client_connected          bool
	net_client_received_wait_data bool
	net_client_wait_data          Net_waitdata_t
	net_waiting_for_launch        bool
	net_player_name               &i8
	net_client_reject_reason      &i8
	drone                         bool
	client_state                  Net_clientstate_t
	client_settings               Net_gamesettings_t
	client_connection             Net_connection_t
	server_addr                   &Net_addr_t
	client_context                &Net_context_t
	net_local_wad_sha1sum         Sha1_digest_t
	net_local_deh_sha1sum         Sha1_digest_t
	net_local_is_freedoom         u32
	last_gamedata_seq             u32
)

@[export: 'NET_CL_LaunchGame']
pub fn net_cl_launch_game() {
	// First-pass client scaffold: signal the wait loop to continue into gameplay.
	if net_waiting_for_launch {
		net_waiting_for_launch = false
	}
	client_state = .client_state_waiting_start
}

@[export: 'NET_CL_StartGame']
pub fn net_cl_start_game(settings &Net_gamesettings_t) {
	client_settings = *settings
	client_state = .client_state_in_game
	net_waiting_for_launch = false
}

@[export: 'NET_CL_SendTiccmd']
pub fn net_cl_send_ticcmd(_ticcmd &Ticcmd_t, _maketic int) {
	_ = _ticcmd
	_ = _maketic
}

@[export: 'NET_CL_Connect']
pub fn net_cl_connect(_addr &Net_addr_t, _data &Net_connect_data_t) bool {
	if _addr == unsafe { nil } {
		net_client_reject_reason = c'Bad server address'
		return false
	}
	_ = _data
	server_addr = _addr
	net_reference_address(server_addr)
	client_context = net_new_context()
	net_add_module(client_context, _addr.module_)
	if !_addr.module_.initClient() {
		net_client_reject_reason = c'Failed to initialize client module'
		net_release_address(server_addr)
		server_addr = unsafe { nil }
		return false
	}
	net_conn_init_client(&client_connection, server_addr, .net_protocol_unknown)

	net_local_wad_sha1sum = _data.wad_sha1sum
	net_local_deh_sha1sum = _data.deh_sha1sum
	net_local_is_freedoom = u32(_data.is_freedoom)

	net_cl_send_syn(_data)

	// Handshake is not fully translated yet; mark connected for first-pass flow.
	client_connection.state = .net_conn_state_connected
	net_client_connected = true
	net_waiting_for_launch = true
	net_client_received_wait_data = false
	client_state = .client_state_waiting_launch
	net_client_reject_reason = unsafe { nil }
	return true
}

@[export: 'NET_CL_GetSettings']
pub fn net_cl_get_settings(out_settings &Net_gamesettings_t) bool {
	if client_state != .client_state_in_game {
		return false
	}
	unsafe {
		*out_settings = client_settings
	}
	return true
}

@[export: 'NET_CL_Disconnect']
pub fn net_cl_disconnect() {
	net_conn_disconnect(&client_connection)
	if server_addr != unsafe { nil } {
		net_release_address(server_addr)
		server_addr = unsafe { nil }
	}
	net_client_connected = false
	net_waiting_for_launch = false
	net_client_received_wait_data = false
	client_state = .client_state_waiting_launch
}

@[export: 'NET_CL_Init']
pub fn net_cl_init() {
	if net_player_name == unsafe { nil } {
		net_player_name = net_get_random_pet_name()
	}
	net_client_connected = false
	net_waiting_for_launch = false
	net_client_received_wait_data = false
	server_addr = unsafe { nil }
	client_context = unsafe { nil }
	client_connection = Net_connection_t{}
	client_state = .client_state_waiting_launch
}

fn net_cl_parse_packet(packet &Net_packet_t) {
	mut packet_type := u32(0)
	if !net_read_int16(packet, &packet_type) {
		return
	}
	_ = net_conn_packet(&client_connection, packet, &packet_type)
	match Net_packet_type_t(packet_type) {
		.net_packet_type_syn {
			net_cl_parse_syn(packet)
		}
		.net_packet_type_rejected {
			net_cl_parse_reject(packet)
		}
		.net_packet_type_waiting_data {
			if client_state == .client_state_in_game {
				return
			}
			mut wait := Net_waitdata_t{}
			if net_read_wait_data(packet, &wait) {
				if wait.num_players <= wait.max_players && wait.ready_players <= wait.num_players
					&& wait.max_players <= 8 {
					net_client_wait_data = wait
					net_client_received_wait_data = true
				}
			}
		}
		.net_packet_type_launch {
			mut num_players := u32(0)
			if !net_read_int8(packet, &num_players) {
				return
			}
			net_client_wait_data.num_players = int(num_players)
			net_waiting_for_launch = false
			if client_state == .client_state_waiting_launch {
				client_state = .client_state_waiting_start
			}
		}
		.net_packet_type_gamestart {
			mut settings := Net_gamesettings_t{}
			if net_read_settings(packet, &settings) {
				if client_state == .client_state_waiting_start
					|| client_state == .client_state_waiting_launch {
					net_cl_start_game(&settings)
				}
			}
		}
		.net_packet_type_console_message {
			msg := net_read_safe_string(packet)
			if msg != unsafe { nil } {
				println('Message from server:\n${cstring(msg)}')
			}
		}
		.net_packet_type_gamedata {
			net_cl_parse_gamedata(packet)
		}
		.net_packet_type_gamedata_resend {
			net_cl_parse_resend_request(packet)
		}
		else {}
	}
}

fn net_cl_send_gamedata_ack(seq_low u32) {
	packet := net_new_packet(16)
	net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_gamedata_ack))
	net_write_int8(packet, seq_low & 0xff)
	net_conn_send_packet(&client_connection, packet)
	net_free_packet(packet)
}

fn net_cl_parse_gamedata(packet &Net_packet_t) {
	mut seq_low := u32(0)
	mut num_tics := u32(0)
	if !net_read_int8(packet, &seq_low) || !net_read_int8(packet, &num_tics) {
		return
	}
	last_gamedata_seq = net_expand_tic_num(last_gamedata_seq, seq_low)
	for _ in 0 .. int(num_tics) {
		mut cmd := Net_full_ticcmd_t{}
		if !net_read_full_ticcmd(packet, &cmd, client_settings.lowres_turn != 0) {
			return
		}
	}
	net_cl_send_gamedata_ack(seq_low)
}

fn net_cl_parse_resend_request(packet &Net_packet_t) {
	mut start := u32(0)
	mut num_tics := u32(0)
	if !net_read_int32(packet, &start) || !net_read_int8(packet, &num_tics) {
		return
	}
	net_log(c'client: resend request start=%d num_tics=%d', int(start), int(num_tics))
}

fn set_reject_reason(s &i8) {
	if s == unsafe { nil } {
		net_client_reject_reason = unsafe { nil }
		return
	}
	net_client_reject_reason = m_string_duplicate(&char(s))
}

fn net_cl_parse_syn(packet &Net_packet_t) {
	server_version := net_read_safe_string(packet)
	if server_version == unsafe { nil } {
		return
	}
	protocol := net_read_protocol(packet)
	if protocol == .net_protocol_unknown {
		set_reject_reason(c'No common network protocol')
		return
	}
	client_connection.state = .net_conn_state_connected
	client_connection.protocol = protocol
	if cstring(server_version) != cstring(vdoom_package_string) {
		eprintln("NET_CL_ParseSYN: local '${cstring(vdoom_package_string)}', server '${cstring(server_version)}'; mismatch may desync.")
	}
}

fn net_cl_parse_reject(packet &Net_packet_t) {
	msg := net_read_safe_string(packet)
	if msg == unsafe { nil } {
		return
	}
	if client_connection.state == .net_conn_state_connecting {
		client_connection.state = .net_conn_state_disconnected
		client_connection.disconnect_reason = .net_disconnect_remote
		set_reject_reason(msg)
	}
}

fn net_cl_send_syn(data &Net_connect_data_t) {
	if client_context == unsafe { nil } || server_addr == unsafe { nil } {
		return
	}
	packet := net_new_packet(64)
	net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_syn))
	net_write_int32(packet, net_magic_number)
	net_write_string(packet, vdoom_package_string)
	net_write_protocol_list(packet)
	net_write_connect_data(packet, data)
	if net_player_name == unsafe { nil } {
		net_player_name = c'Player'
	}
	net_write_string(packet, net_player_name)
	net_conn_send_packet(&client_connection, packet)
	net_free_packet(packet)
}

@[export: 'NET_CL_Run']
pub fn net_cl_run() {
	if !net_client_connected || client_context == unsafe { nil } {
		return
	}
	for {
		mut addr := &Net_addr_t(unsafe { nil })
		mut packet := &Net_packet_t(unsafe { nil })
		if !net_recv_packet(client_context, &addr, &packet) {
			break
		}
		if addr == server_addr {
			net_cl_parse_packet(packet)
		}
		net_free_packet(packet)
		net_release_address(addr)
	}
	net_conn_run(&client_connection)
	if client_connection.state == .net_conn_state_disconnected
		|| client_connection.state == .net_conn_state_disconnected_sleep {
		net_cl_disconnect()
		return
	}
	net_waiting_for_launch = client_connection.state == .net_conn_state_connected
		&& client_state == .client_state_waiting_launch
}
