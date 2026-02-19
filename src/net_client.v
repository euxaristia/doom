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
	_ = _addr
	_ = _data
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
	net_client_connected = false
	net_waiting_for_launch = false
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
	client_state = .client_state_waiting_launch
}
