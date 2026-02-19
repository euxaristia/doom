@[translated]
module main

// Network client state scaffold.

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
		.net_packet_type_waiting_data {
			mut wait := Net_waitdata_t{}
			if net_read_wait_data(packet, &wait) {
				net_client_wait_data = wait
				net_client_received_wait_data = true
			}
		}
		.net_packet_type_launch {
			net_waiting_for_launch = false
			if client_state == .client_state_waiting_launch {
				client_state = .client_state_waiting_start
			}
		}
		.net_packet_type_gamestart {
			mut settings := Net_gamesettings_t{}
			if net_read_settings(packet, &settings) {
				net_cl_start_game(&settings)
			}
		}
		.net_packet_type_console_message {
			msg := net_read_safe_string(packet)
			if msg != unsafe { nil } {
				println('Message from server:\n${cstring(msg)}')
			}
		}
		else {}
	}
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
