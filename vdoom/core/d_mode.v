module core

pub enum GameMode {
	shareware
	registered
	commercial
	retail
	indetermined
}

pub enum GameMission {
	none
	doom
	doom2
	pack_tnt
	pack_plut
	pack_chex
	pack_hacx
	heretic
	hexen
	strife
}

pub enum GameVersion {
	exe_doom_1_2
	exe_doom_1_666
	exe_doom_1_7
	exe_doom_1_8
	exe_doom_1_9
	exe_hacx
	exe_ultimate
	exe_final
	exe_final2
	exe_chex
	exe_heretic_1_3
	exe_hexen_1_1
	exe_strife_1_2
	exe_strife_1_31
}

pub enum GameVariant {
	vanilla
	freedoom
	freedm
	bfgedition
}

struct ValidMode {
	mission GameMission
	mode    GameMode
	episode int
	map     int
}

const valid_modes = [
	ValidMode{mission: .pack_chex, mode: .retail, episode: 1, map: 5},
	ValidMode{mission: .doom, mode: .shareware, episode: 1, map: 9},
	ValidMode{mission: .doom, mode: .registered, episode: 3, map: 9},
	ValidMode{mission: .doom, mode: .retail, episode: 4, map: 9},
	ValidMode{mission: .doom2, mode: .commercial, episode: 1, map: 32},
	ValidMode{mission: .pack_tnt, mode: .commercial, episode: 1, map: 32},
	ValidMode{mission: .pack_plut, mode: .commercial, episode: 1, map: 32},
	ValidMode{mission: .pack_hacx, mode: .commercial, episode: 1, map: 32},
	ValidMode{mission: .heretic, mode: .shareware, episode: 1, map: 9},
	ValidMode{mission: .heretic, mode: .registered, episode: 3, map: 9},
	ValidMode{mission: .heretic, mode: .retail, episode: 5, map: 9},
	ValidMode{mission: .hexen, mode: .commercial, episode: 1, map: 60},
	ValidMode{mission: .strife, mode: .commercial, episode: 1, map: 34},
]

pub fn d_valid_game_mode(mission GameMission, mode GameMode) bool {
	for entry in valid_modes {
		if entry.mission == mission && entry.mode == mode {
			return true
		}
	}
	return false
}

pub fn d_valid_episode_map(mission GameMission, mode GameMode, episode int, mapnum int) bool {
	// Heretic secret episode quirks.
	if mission == .heretic {
		if mode == .retail && episode == 6 {
			return mapnum >= 1 && mapnum <= 3
		}
		if mode == .registered && episode == 4 {
			return mapnum == 1
		}
	}
	for entry in valid_modes {
		if entry.mission == mission && entry.mode == mode {
			return episode >= 1 && episode <= entry.episode && mapnum >= 1 && mapnum <= entry.map
		}
	}
	return false
}

pub fn d_get_num_episodes(mission GameMission, mode GameMode) int {
	mut episode := 1
	for d_valid_episode_map(mission, mode, episode, 1) {
		episode++
	}
	return episode - 1
}

struct ValidVersion {
	mission GameMission
	version GameVersion
}

const valid_versions = [
	ValidVersion{mission: .doom, version: .exe_doom_1_2},
	ValidVersion{mission: .doom, version: .exe_doom_1_666},
	ValidVersion{mission: .doom, version: .exe_doom_1_7},
	ValidVersion{mission: .doom, version: .exe_doom_1_8},
	ValidVersion{mission: .doom, version: .exe_doom_1_9},
	ValidVersion{mission: .doom, version: .exe_hacx},
	ValidVersion{mission: .doom, version: .exe_ultimate},
	ValidVersion{mission: .doom, version: .exe_final},
	ValidVersion{mission: .doom, version: .exe_final2},
	ValidVersion{mission: .doom, version: .exe_chex},
	ValidVersion{mission: .heretic, version: .exe_heretic_1_3},
	ValidVersion{mission: .hexen, version: .exe_hexen_1_1},
	ValidVersion{mission: .strife, version: .exe_strife_1_2},
	ValidVersion{mission: .strife, version: .exe_strife_1_31},
]

pub fn d_valid_game_version(mission GameMission, version GameVersion) bool {
	logical := d_logical_mission(mission)
	for entry in valid_versions {
		if entry.mission == logical && entry.version == version {
			return true
		}
	}
	return false
}

pub fn d_logical_mission(mission GameMission) GameMission {
	return if mission in [.doom2, .pack_plut, .pack_tnt, .pack_hacx, .pack_chex] { .doom } else { mission }
}

pub fn d_is_episode_map(mission GameMission) bool {
	return mission in [.doom, .heretic, .pack_chex]
}

pub fn d_game_mission_string(mission GameMission) string {
	return match mission {
		.none { 'none' }
		.doom { 'doom' }
		.doom2 { 'doom2' }
		.pack_tnt { 'tnt' }
		.pack_plut { 'plutonia' }
		.pack_hacx { 'hacx' }
		.pack_chex { 'chex' }
		.heretic { 'heretic' }
		.hexen { 'hexen' }
		.strife { 'strife' }
	}
}

pub fn d_game_mode_string(mode GameMode) string {
	return match mode {
		.shareware { 'shareware' }
		.registered { 'registered' }
		.commercial { 'commercial' }
		.retail { 'retail' }
		.indetermined { 'unknown' }
	}
}

// C-style entrypoints used by some upstream modules.
pub fn d_valid_game_mode_c(mission GameMission, mode GameMode) bool {
	return d_valid_game_mode(mission, mode)
}

pub fn d_valid_game_version_c(mission GameMission, version GameVersion) bool {
	return d_valid_game_version(mission, version)
}

pub fn d_episode_map_limits(mission GameMission, mode GameMode) (int, int) {
	for entry in valid_modes {
		if entry.mission == mission && entry.mode == mode {
			return entry.episode, entry.map
		}
	}
	return 1, 1
}
