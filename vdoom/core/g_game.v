@[has_globals]
module core

import os

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

pub fn g_handle_game_action() {
	// Mirror the vanilla "while gameaction" loop in a minimal way.
	mut loop_count := 0
	for game_action() != .nothing {
		loop_count++
		println('g_handle_game_action: iteration ${loop_count}, gameaction=${game_action()}')
		match game_action() {
			.loadlevel {
				println('g_handle_game_action: calling p_setup_level')
				p_setup_level(gameepisode, gamemap, 1, gameskill)
				set_game_action(.nothing)
			}
			.newgame {
				println('g_handle_game_action: calling g_init_new')
				g_init_new(startskill, startepisode, startmap)
				// g_init_new already calls p_setup_level, so go to nothing
				// (not .loadlevel which would double-load the level)
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
				println('g_handle_game_action: unknown gameaction')
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
	render_show_menu = false
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
	mission := logical_game_mission()
	ep, mp := d_clamp_episode_map(mission, game_mode(), episode, mapnum)
	set_start_params(skill, ep, mp)
	set_game_action(.newgame)
}

pub fn g_defered_play_demo(demo string) {
	_ = demo
}

pub fn g_load_game(name string) {
	if !os.exists(name) {
		println('save file not found: ${name}')
		return
	}
	data := os.read_file(name) or {
		println('failed to read save: ${err}')
		return
	}
	lines := data.split('\n')
	mut save_episode := 1
	mut save_map := 1
	mut save_skill := 2
	mut save_health := 100
	mut save_armor := 0
	mut save_armortype := 0
	mut save_weapon := 0
	mut save_ammo_clip := 0
	mut save_ammo_shell := 0
	mut save_ammo_cell := 0
	mut save_ammo_misl := 0
	
	for line in lines {
		if line.starts_with('episode=') {
			save_episode = line[8..].int()
		}
		if line.starts_with('map=') {
			save_map = line[4..].int()
		}
		if line.starts_with('skill=') {
			save_skill = line[6..].int()
		}
		if line.starts_with('health=') {
			save_health = line[7..].int()
		}
		if line.starts_with('armor=') {
			save_armor = line[6..].int()
		}
		if line.starts_with('armortype=') {
			save_armortype = line[10..].int()
		}
		if line.starts_with('weapon=') {
			save_weapon = line[7..].int()
		}
		if line.starts_with('ammo_clip=') {
			save_ammo_clip = line[10..].int()
		}
		if line.starts_with('ammo_shell=') {
			save_ammo_shell = line[11..].int()
		}
		if line.starts_with('ammo_cell=') {
			save_ammo_cell = line[10..].int()
		}
		if line.starts_with('ammo_misl=') {
			save_ammo_misl = line[10..].int()
		}
	}
	println('loaded game: episode ${save_episode}, map ${save_map}, skill ${save_skill}')
	gameepisode = save_episode
	gamemap = save_map
	gameskill = save_skill
	p_setup_level(gameepisode, gamemap, 1, gameskill)
	
	// Restore player state
	if players.len > 0 {
		unsafe {
			players[0].health = save_health
			players[0].armorpoints = save_armor
			players[0].armortype = save_armortype
			players[0].readyweapon = WeaponType(save_weapon)
		}
		players[0].ammo[int(AmmoType.clip)] = save_ammo_clip
		players[0].ammo[int(AmmoType.shell)] = save_ammo_shell
		players[0].ammo[int(AmmoType.cell)] = save_ammo_cell
		players[0].ammo[int(AmmoType.misl)] = save_ammo_misl
	}
	
	render_show_menu = false
	v_clear_screen(0)
	i_finish_update()
}

pub fn g_do_load_game() {
}

pub fn g_save_game(slot int, description string) {
	save_dir := os.join_path(os.home_dir(), '.vdoom')
	os.mkdir_all(save_dir) or {}
	save_path := os.join_path(save_dir, 'save${slot}.dsg')
	
	mut content := ' Doom V Save Game\n'
	content += 'description=${description}\n'
	content += 'version=2\n'
	content += 'episode=${gameepisode}\n'
	content += 'map=${gamemap}\n'
	content += 'skill=${gameskill}\n'
	
	if players.len > 0 {
		p := &players[0]
		content += 'player_x=${p.mo.x}\n'
		content += 'player_y=${p.mo.y}\n'
		content += 'player_z=${p.mo.z}\n'
		content += 'player_angle=${p.mo.angle}\n'
		content += 'health=${p.health}\n'
		content += 'armor=${p.armorpoints}\n'
		content += 'armortype=${p.armortype}\n'
		content += 'weapon=${int(p.readyweapon)}\n'
		content += 'ammo_clip=${p.ammo[int(AmmoType.clip)]}\n'
		content += 'ammo_shell=${p.ammo[int(AmmoType.shell)]}\n'
		content += 'ammo_cell=${p.ammo[int(AmmoType.cell)]}\n'
		content += 'ammo_misl=${p.ammo[int(AmmoType.misl)]}\n'
	}
	
	os.write_file(save_path, content) or {
		println('failed to save game: ${err}')
		return
	}
	println('game saved to ${save_path}')
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

pub fn g_build_ticcmd(mut cmd &TicCmd, maketic int) {
	if unsafe { cmd == 0 } {
		return
	}
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

	// If game_ctx is nil, we are in headless mode or window not yet created
	if game_ctx == unsafe { nil } {
		return
	}

	// Standard Doom key layout:
	// Left/Right = turn, Up/Down = forward/back
	// Alt+Left/Right = strafe, Space = use, Ctrl = shoot
	mut turn_speed := i16(1280)
	mut forward_speed := i8(50)
	if game_ctx.is_key_down(.left_shift) || game_ctx.is_key_down(.right_shift) {
		turn_speed = 2560
		forward_speed = 127
	}

	// Forward/backward
	if game_ctx.is_key_down(.up) || game_ctx.is_key_down(.w) {
		cmd.forwardmove = forward_speed
	} else if game_ctx.is_key_down(.down) || game_ctx.is_key_down(.s) {
		cmd.forwardmove = -forward_speed
	}

	// Turn or strafe
	strafe := game_ctx.is_key_down(.left_alt) || game_ctx.is_key_down(.right_alt)
	if game_ctx.is_key_down(.left) {
		if strafe {
			cmd.sidemove = -forward_speed
		} else {
			cmd.angleturn = turn_speed
		}
	} else if game_ctx.is_key_down(.right) {
		if strafe {
			cmd.sidemove = forward_speed
		} else {
			cmd.angleturn = -turn_speed
		}
	}

	// WASD strafe
	if game_ctx.is_key_down(.a) {
		cmd.sidemove = -forward_speed
	} else if game_ctx.is_key_down(.d) {
		cmd.sidemove = forward_speed
	}

	// Use (space) and attack (ctrl)
	if game_ctx.is_key_down(.space) {
		cmd.buttons = 2 // BT_USE
	}
	if game_ctx.is_key_down(.left_control) || game_ctx.is_key_down(.right_control) {
		cmd.buttons |= 1 // BT_ATTACK
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
	
	// Render the view if game is running
	if !render_show_menu && gamestate == .level && consoleplayer >= 0 && consoleplayer < players.len {
		r_render_player_view(voidptr(&players[consoleplayer]))
	}
	
	gametic++
	// Update positional audio using the console player's mobj when present.
	if consoleplayer >= 0 && consoleplayer < players.len {
		if voidptr(players[consoleplayer].mo) != unsafe { nil } {
			s_update_sounds(players[consoleplayer].mo)
		}
	}
}

pub fn g_responder(ev &Event) bool {
	if gamestate != .level {
		return false
	}
	if ev.typ == .keydown {
		// Weapon switching via number keys
		weapon := match ev.data1 {
			int(`1`) { int(WeaponType.fist) }
			int(`2`) { int(WeaponType.pistol) }
			int(`3`) { int(WeaponType.shotgun) }
			int(`4`) { int(WeaponType.chaingun) }
			int(`5`) { int(WeaponType.missile) }
			int(`6`) { int(WeaponType.plasma) }
			int(`7`) { int(WeaponType.bfg) }
			int(`8`) { int(WeaponType.chainsaw) }
			else { -1 }
		}
		if weapon >= 0 && consoleplayer >= 0 && consoleplayer < players.len {
			if weapon < numweapons && players[consoleplayer].weaponowned[weapon] != 0 {
				players[consoleplayer].pendingweapon = unsafe { WeaponType(weapon) }
				return true
			}
		}
		// Pause
		if ev.data1 == key_pause {
			paused = !paused
			return true
		}
		// Escape opens menu
		if ev.data1 == key_escape {
			if menuactive {
				m_close_control_panel()
			} else {
				m_start_control_panel()
			}
			return true
		}
	}
	return false
}

pub fn g_screen_shot() {
}

pub fn g_draw_mouse_speed_box() {
}

pub fn g_vanilla_version_code() int {
	return doom_version
}
