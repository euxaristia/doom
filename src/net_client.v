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
)

@[export: 'NET_CL_LaunchGame']
pub fn net_cl_launch_game() {
	// First-pass client scaffold: signal the wait loop to continue into gameplay.
	if net_waiting_for_launch {
		net_waiting_for_launch = false
	}
	client_state = .client_state_waiting_start
}
