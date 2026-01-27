@[has_globals]
module core

__global vanilla_savegame_limit = 0
__global vanilla_demo_limit = 0
__global oldgamestate = GameState.level
__global timingdemo = false
__global starttime = 0

pub fn g_deathmatch_spawn_player(playernum int) {
	_ = playernum
}

pub fn g_init_new(skill int, episode int, mapnum int) {
	_ = skill
	_ = episode
	_ = mapnum
}

pub fn g_defered_init_new(skill int, episode int, mapnum int) {
	_ = skill
	_ = episode
	_ = mapnum
}

pub fn g_defered_play_demo(demo string) {
	_ = demo
}

pub fn g_load_game(name string) {
	_ = name
}

pub fn g_do_load_game() {
}

pub fn g_save_game(slot int, description string) {
	_ = slot
	_ = description
}

pub fn g_record_demo(name string) {
	_ = name
}

pub fn g_begin_recording() {
}

pub fn g_play_demo(name string) {
	_ = name
}

pub fn g_time_demo(name string) {
	_ = name
}

pub fn g_check_demo_status() bool {
	return false
}

pub fn g_exit_level() {
}

pub fn g_secret_exit_level() {
}

pub fn g_world_done() {
}

pub fn g_build_ticcmd(cmd &TicCmd, maketic int) {
	unsafe {
		cmd.forwardmove = 0
		cmd.sidemove = 0
		cmd.angleturn = 0
		cmd.chatchar = 0
		cmd.buttons = 0
		cmd.consistancy = u8(maketic & 0xff)
		cmd.buttons2 = 0
		cmd.inventory = 0
		cmd.lookfly = 0
		cmd.arti = 0
	}
}

pub fn g_ticker() {
	oldgamestate = gamestate
	if paused {
		return
	}
	if timingdemo && starttime == 0 {
		starttime = i_get_time_ms()
	}
	p_ticker()
	gametic++
	// Update positional audio using the console player's mobj when present.
	if consoleplayer >= 0 && consoleplayer < players.len {
		if voidptr(players[consoleplayer].mo) != unsafe { nil } {
			s_update_sounds(players[consoleplayer].mo)
		}
	}
}

pub fn g_responder(ev &Event) bool {
	_ = ev
	return false
}

pub fn g_screen_shot() {
}

pub fn g_draw_mouse_speed_box() {
}

pub fn g_vanilla_version_code() int {
	return doom_version
}
