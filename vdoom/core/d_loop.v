@[has_globals]
module core

pub type NetgameStartupCallback = fn (ready_players int, num_players int) bool

pub struct LoopInterface {
pub mut:
	process_events fn () = unsafe { nil }
	build_ticcmd   fn (cmd &TicCmd, maketic int) = unsafe { nil }
	run_tic        fn (cmds []TicCmd, ingame []bool) = unsafe { nil }
	run_menu       fn () = unsafe { nil }
}

__global singletics = false
__global gametic = 0
__global ticdup = 0
__global loop_interface = LoopInterface{}
__global maketic = 0
__global game_loop_started = false
pub const max_netgame_stall_tics = 5
__global rendered_frames = 0

pub fn d_register_loop_callbacks(i &LoopInterface) {
	loop_interface = *i
}

pub fn net_update() {
	if loop_interface.process_events != unsafe { nil } {
		loop_interface.process_events()
	}
}

pub fn d_quit_net_game() {
}

pub fn try_run_tics() {
	dup := if ticdup > 0 { ticdup } else { 1 }
	if loop_interface.build_ticcmd != unsafe { nil } {
		for i in 0 .. maxplayers {
			if i < playeringame.len && playeringame[i] {
				loop_interface.build_ticcmd(&netcmds[i], maketic)
			}
		}
	}
	run_count := if singletics { 1 } else { dup }
	if loop_interface.run_tic != unsafe { nil } {
		for _ in 0 .. run_count {
			loop_interface.run_tic(netcmds, playeringame)
			gametic++
		}
		maketic++
	}
	if loop_interface.run_menu != unsafe { nil } {
		loop_interface.run_menu()
	}
	rendered_frames++
}

pub fn d_start_game_loop() {
	game_loop_started = true
	singletics = timingdemo
	if ticdup < 1 {
		ticdup = 1
	}
	maketic = gametic
}

pub fn d_init_net_game(connect_data &NetConnectData) bool {
	_ = connect_data
	return false
}

pub fn d_start_net_game(settings &NetGameSettings, callback NetgameStartupCallback) {
	_ = settings
	_ = callback
}

pub fn d_non_vanilla_record(conditional bool, feature string) bool {
	_ = conditional
	_ = feature
	return false
}

pub fn d_non_vanilla_playback(conditional bool, lumpnum int, feature string) bool {
	_ = conditional
	_ = lumpnum
	_ = feature
	return false
}

pub fn d_rendered_frames() int {
	return rendered_frames
}

pub fn d_reset_rendered_frames() {
	rendered_frames = 0
}

pub fn d_render_stats() (int, int, int) {
	return rendered_frames, i_frame_dump_count(), patch_cache_count()
}
