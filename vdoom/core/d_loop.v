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

pub fn d_register_loop_callbacks(i &LoopInterface) {
	_ = i
}

pub fn net_update() {
}

pub fn d_quit_net_game() {
}

pub fn try_run_tics() {
}

pub fn d_start_game_loop() {
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
