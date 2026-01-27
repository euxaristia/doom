@[has_globals]
module core

__global netcmds_ptr = []TicCmd{}

fn player_quit_game(player_num int) {
	if player_num < 0 || player_num >= playeringame.len {
		return
	}
	playeringame[player_num] = false
	if consoleplayer >= 0 && consoleplayer < players.len {
		players[consoleplayer].message = deh_string('Player ${player_num + 1} left the game')
	}
}

fn d_net_run_tic(cmds []TicCmd, ingame []bool) {
	// Mirror the vanilla flow: detect quits, then run the game tick.
	for i in 0 .. maxplayers {
		if i < playeringame.len && playeringame[i] {
			if i < ingame.len && !ingame[i] && !demoplayback {
				player_quit_game(i)
			}
		}
	}
	netcmds_ptr = cmds.clone()
	if advancedemo {
		d_do_advance_demo()
	}
	g_ticker()
}

// Networking init wires the loop callbacks similar to d_net.c.
pub fn d_net_init() {
	mut iface := LoopInterface{}
	iface.process_events = d_process_events
	iface.build_ticcmd = g_build_ticcmd
	iface.run_tic = d_net_run_tic
	iface.run_menu = m_ticker
	d_register_loop_callbacks(&iface)
}

pub fn d_net_shutdown() {}

pub fn d_net_connect() bool {
	return false
}

pub fn d_net_disconnect() {}
