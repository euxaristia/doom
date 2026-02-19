@[translated]
module main

// Networking wait-for-launch flow (headless first pass).

fn C.atoi(&i8) int

@[c: 'I_Error']
@[c2v_variadic]
fn i_error(error &i8, ...)

@[c: 'NET_CL_Run']
fn net_cl_run()

@[c: 'NET_CL_LaunchGame']
fn net_cl_launch_game()

@[c: 'NET_SV_Run']
fn net_sv_run()

@[weak]
__global (
	net_client_wait_data          Net_waitdata_t
	net_client_received_wait_data bool
	net_waiting_for_launch        bool
	net_client_connected          bool
	expected_nodes                int
)

fn start_game() {
	net_cl_launch_game()
}

fn parse_command_line_args() {
	i := m_check_parm_with_args(c'-nodes', 1)
	if i > 0 {
		expected_nodes = C.atoi(myargv[i + 1])
	}
}

fn check_auto_launch() {
	if net_client_received_wait_data && net_client_wait_data.is_controller != 0
		&& expected_nodes > 0 {
		nodes := net_client_wait_data.num_players + net_client_wait_data.num_drones
		if nodes >= expected_nodes {
			start_game()
			expected_nodes = 0
		}
	}
}

@[export: 'NET_WaitForLaunch']
pub fn net_wait_for_launch() {
	parse_command_line_args()
	for net_waiting_for_launch {
		check_auto_launch()
		net_cl_run()
		net_sv_run()
		if !net_client_connected {
			i_error(c'Lost connection to server')
		}
		i_sleep(100)
	}
}
