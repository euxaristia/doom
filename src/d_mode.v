@[translated]
module main

struct Valid_mode_t {
	mission GameMission_t
	mode    GameMode_t
	episode int
	map     int
}

const valid_modes = [
	Valid_mode_t{mission: GameMission_t.pack_chex, mode: GameMode_t.retail, episode: 1, map: 5},
	Valid_mode_t{mission: GameMission_t.doom, mode: GameMode_t.shareware, episode: 1, map: 9},
	Valid_mode_t{mission: GameMission_t.doom, mode: GameMode_t.registered, episode: 3, map: 9},
	Valid_mode_t{mission: GameMission_t.doom, mode: GameMode_t.retail, episode: 4, map: 9},
	Valid_mode_t{mission: GameMission_t.doom2, mode: GameMode_t.commercial, episode: 1, map: 32},
	Valid_mode_t{mission: GameMission_t.pack_tnt, mode: GameMode_t.commercial, episode: 1, map: 32},
	Valid_mode_t{mission: GameMission_t.pack_plut, mode: GameMode_t.commercial, episode: 1, map: 32},
	Valid_mode_t{mission: GameMission_t.pack_hacx, mode: GameMode_t.commercial, episode: 1, map: 32},
	Valid_mode_t{mission: GameMission_t.heretic, mode: GameMode_t.shareware, episode: 1, map: 9},
	Valid_mode_t{mission: GameMission_t.heretic, mode: GameMode_t.registered, episode: 3, map: 9},
	Valid_mode_t{mission: GameMission_t.heretic, mode: GameMode_t.retail, episode: 5, map: 9},
	Valid_mode_t{mission: GameMission_t.hexen, mode: GameMode_t.commercial, episode: 1, map: 60},
	Valid_mode_t{mission: GameMission_t.strife, mode: GameMode_t.commercial, episode: 1, map: 34},
]

@[c: 'D_ValidGameMode']
fn d_valid_game_mode(mission GameMission_t, mode GameMode_t) bool {
	for i := 0; i < valid_modes.len; i++ {
		if valid_modes[i].mode == mode && valid_modes[i].mission == mission {
			return true
		}
	}

	return false
}

@[c: 'D_ValidEpisodeMap']
fn d_valid_episode_map(mission GameMission_t, mode GameMode_t, episode int, map int) bool {
	if mission == GameMission_t.heretic {
		if mode == GameMode_t.retail && episode == 6 {
			return map >= 1 && map <= 3
		} else if mode == GameMode_t.registered && episode == 4 {
			return map == 1
		}
	}

	for i := 0; i < valid_modes.len; i++ {
		if mission == valid_modes[i].mission && mode == valid_modes[i].mode {
			return episode >= 1 && episode <= valid_modes[i].episode && map >= 1
				&& map <= valid_modes[i].map
		}
	}

	return false
}

@[c: 'D_GetNumEpisodes']
fn d_get_num_episodes(mission GameMission_t, mode GameMode_t) int {
	mut episode := 1

	for d_valid_episode_map(mission, mode, episode, 1) {
		episode++
	}

	return episode - 1
}

struct Valid_version_t {
	mission GameMission_t
	version GameVersion_t
}

const valid_versions = [
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_doom_1_2},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_doom_1_666},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_doom_1_7},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_doom_1_8},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_doom_1_9},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_hacx},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_ultimate},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_final},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_final2},
	Valid_version_t{mission: GameMission_t.doom, version: GameVersion_t.exe_chex},
	Valid_version_t{mission: GameMission_t.heretic, version: GameVersion_t.exe_heretic_1_3},
	Valid_version_t{mission: GameMission_t.hexen, version: GameVersion_t.exe_hexen_1_1},
	Valid_version_t{mission: GameMission_t.strife, version: GameVersion_t.exe_strife_1_2},
	Valid_version_t{mission: GameMission_t.strife, version: GameVersion_t.exe_strife_1_31},
]

@[c: 'D_ValidGameVersion']
fn d_valid_game_version(mission GameMission_t, version GameVersion_t) bool {
	mut check_mission := mission

	if check_mission == GameMission_t.doom2 || check_mission == GameMission_t.pack_plut
		|| check_mission == GameMission_t.pack_tnt || check_mission == GameMission_t.pack_hacx
		|| check_mission == GameMission_t.pack_chex {
		check_mission = GameMission_t.doom
	}

	for i := 0; i < valid_versions.len; i++ {
		if valid_versions[i].mission == check_mission && valid_versions[i].version == version {
			return true
		}
	}

	return false
}

@[c: 'D_IsEpisodeMap']
fn d_is_episode_map(mission GameMission_t) bool {
	match mission {
		.doom, .heretic, .pack_chex {
			return true
		}
		.none_, .hexen, .doom2, .pack_hacx, .pack_tnt, .pack_plut, .strife {
			return false
		}
	}
}

@[c: 'D_GameMissionString']
fn d_game_mission_string(mission GameMission_t) &i8 {
	match mission {
		.none_ { return c'none' }
		.doom { return c'doom' }
		.doom2 { return c'doom2' }
		.pack_tnt { return c'tnt' }
		.pack_plut { return c'plutonia' }
		.pack_hacx { return c'hacx' }
		.pack_chex { return c'chex' }
		.heretic { return c'heretic' }
		.hexen { return c'hexen' }
		.strife { return c'strife' }
	}
}

@[c: 'D_GameModeString']
fn d_game_mode_string(mode GameMode_t) &i8 {
	match mode {
		.shareware { return c'shareware' }
		.registered { return c'registered' }
		.commercial { return c'commercial' }
		.retail { return c'retail' }
		.indetermined { return c'unknown' }
	}
}
