@[has_globals]
module core

__global vanilla_savegame_limit = 0
__global vanilla_demo_limit = 0
__global oldgamestate = GameState.level
__global timingdemo = false
__global starttime = 0
__global reborn_pending = []bool{len: maxplayers}

fn g_do_reborn(playernum int) {
	if playernum < 0 || playernum >= players.len {
		return
	}
	unsafe {
		players[playernum].playerstate = .live
		players[playernum].health = deh_initial_health
		players[playernum].viewheight = viewheight_fixed
		players[playernum].readyweapon = .pistol
		players[playernum].pendingweapon = .pistol
		players[playernum].ammo[int(AmmoType.clip)] = deh_initial_bullets
	}
	reborn_pending[playernum] = false
}

fn g_do_completed() {
	set_game_state(.intermission)
	wi_start(&wminfo)
	set_game_action(.nothing)
}

fn g_do_world_done() {
	set_game_state(.level)
	set_game_action(.loadlevel)
}

fn g_handle_game_action() {
	// Mirror the vanilla "while gameaction" loop in a minimal way.
	for game_action() != .nothing {
		match game_action() {
			.loadlevel {
				p_setup_level(gameepisode, gamemap, 1, gameskill)
				set_game_action(.nothing)
			}
			.newgame {
				g_init_new(startskill, startepisode, startmap)
				set_game_action(.nothing)
			}
			.completed {
				g_do_completed()
			}
			.victory {
				f_start_finale()
			}
			.worlddone {
				g_do_world_done()
			}
			else {
				set_game_action(.nothing)
			}
		}
	}
}

pub fn g_deathmatch_spawn_player(playernum int) {
	_ = playernum
}

pub fn g_init_new(skill int, episode int, mapnum int) {
	gameskill = skill
	gameepisode = episode
	gamemap = mapnum
	paused = false
	p_init()
	// Vanilla ammo baselines.
	if maxammo.len == numammo {
		maxammo[int(AmmoType.clip)] = 200
		maxammo[int(AmmoType.shell)] = 50
		maxammo[int(AmmoType.cell)] = 300
		maxammo[int(AmmoType.misl)] = 50
	}
	if clipammo.len == numammo {
		clipammo[int(AmmoType.clip)] = 10
		clipammo[int(AmmoType.shell)] = 4
		clipammo[int(AmmoType.cell)] = 20
		clipammo[int(AmmoType.misl)] = 1
	}
	if players.len > 0 && playeringame.len > 0 {
		playeringame[0] = true
		unsafe {
			players[0].health = deh_initial_health
			players[0].readyweapon = .pistol
			players[0].pendingweapon = .pistol
			players[0].ammo[int(AmmoType.clip)] = deh_initial_bullets
			for i in 0 .. numammo {
				players[0].maxammo[i] = maxammo[i]
			}
		}
	}
	if timelimit > 0 {
		p_start_level_timer(timelimit)
	} else {
		p_stop_level_timer()
	}
	p_setup_level(episode, mapnum, 1, skill)
}

pub fn g_defered_init_new(skill int, episode int, mapnum int) {
	set_start_params(skill, episode, mapnum)
	set_game_action(.newgame)
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
	set_game_action(.completed)
}

pub fn g_secret_exit_level() {
	set_intermission_secret(true)
	set_game_action(.completed)
}

pub fn g_world_done() {
	set_game_action(.worlddone)
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
	// Process deferred actions and player reborns before ticking the world.
	for i in 0 .. maxplayers {
		if i < playeringame.len && playeringame[i] && i < players.len {
			if players[i].playerstate == .reborn || reborn_pending[i] {
				reborn_pending[i] = true
				g_do_reborn(i)
			}
		}
	}
	g_handle_game_action()
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
