@[translated]
module main

//
// Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//   Functions and definitions relating to the game type and operational mode.
//

// The "mission" controls what game we are playing.
enum GameMission {
	doom = 0           // Doom 1
	doom2 = 1          // Doom 2
	pack_tnt = 2       // Final Doom: TNT: Evilution
	pack_plut = 3      // Final Doom: The Plutonia Experiment
	pack_chex = 4      // Chex Quest (modded doom)
	pack_hacx = 5      // Hacx (modded doom2)
	heretic = 6        // Heretic
	hexen = 7          // Hexen
	strife = 8         // Strife
	none = 9
}

// The "mode" allows more accurate specification of the game mode we are
// in: eg. shareware vs. registered.
enum GameMode {
	shareware = 0       // Doom/Heretic shareware
	registered = 1      // Doom/Heretic registered
	commercial = 2      // Doom II/Hexen
	retail = 3          // Ultimate Doom
	indetermined = 4    // Unknown.
}

// What version are we emulating?
enum GameVersion {
	exe_doom_1_2 = 0    // Doom 1.2: shareware and registered
	exe_doom_1_666 = 1  // Doom 1.666: for shareware, registered and commercial
	exe_doom_1_7 = 2    // Doom 1.7/1.7a: "
	exe_doom_1_8 = 3    // Doom 1.8: "
	exe_doom_1_9 = 4    // Doom 1.9: "
	exe_hacx = 5        // Hacx
	exe_ultimate = 6    // Ultimate Doom (retail)
	exe_final = 7       // Final Doom
	exe_final2 = 8      // Final Doom (alternate exe)
	exe_chex = 9        // Chex Quest executable (based on Final Doom)
	exe_heretic_1_3 = 10 // Heretic 1.3
	exe_hexen_1_1 = 11   // Hexen 1.1
	exe_strife_1_2 = 12  // Strife v1.2
	exe_strife_1_31 = 13 // Strife v1.31
}

// What IWAD variant are we using?
enum GameVariant {
	vanilla = 0     // Vanilla Doom
	freedoom = 1    // FreeDoom: Phase 1 + 2
	freedm = 2      // FreeDM
	bfgedition = 3  // Doom Classic (Doom 3: BFG Edition)
}

// Skill level.
enum Skill {
	sk_noitems = -1  // the "-skill 0" hack
	sk_baby = 0
	sk_easy = 1
	sk_medium = 2
	sk_hard = 3
	sk_nightmare = 4
}

// Valid game mode/mission combinations
struct ValidMode {
	mission GameMission
	mode GameMode
	episode int
	map int
}

// Valid game version combinations
struct ValidVersion {
	mission GameMission
	version GameVersion
}

// Static data for valid modes
const valid_modes = [
	ValidMode{pack_chex, retail, 1, 5},
	ValidMode{doom, shareware, 1, 9},
	ValidMode{doom, registered, 3, 9},
	ValidMode{doom, retail, 4, 9},
	ValidMode{doom2, commercial, 1, 32},
	ValidMode{pack_tnt, commercial, 1, 32},
	ValidMode{pack_plut, commercial, 1, 32},
	ValidMode{pack_hacx, commercial, 1, 32},
	ValidMode{heretic, shareware, 1, 9},
	ValidMode{heretic, registered, 3, 9},
	ValidMode{heretic, retail, 5, 9},
	ValidMode{hexen, commercial, 1, 60},
	ValidMode{strife, commercial, 1, 34},
]!

const valid_versions = [
	ValidVersion{doom, exe_doom_1_2},
	ValidVersion{doom, exe_doom_1_666},
	ValidVersion{doom, exe_doom_1_7},
	ValidVersion{doom, exe_doom_1_8},
	ValidVersion{doom, exe_doom_1_9},
	ValidVersion{doom, exe_hacx},
	ValidVersion{doom, exe_ultimate},
	ValidVersion{doom, exe_final},
	ValidVersion{doom, exe_final2},
	ValidVersion{doom, exe_chex},
	ValidVersion{heretic, exe_heretic_1_3},
	ValidVersion{hexen, exe_hexen_1_1},
	ValidVersion{strife, exe_strife_1_2},
	ValidVersion{strife, exe_strife_1_31},
]!

// Check that a gamemode+gamemission received over the network is valid.
fn d_valid_game_mode(mission GameMission, mode GameMode) bool {
	for vm in valid_modes {
		if vm.mode == mode && vm.mission == mission {
			return true
		}
	}

	return false
}

// Check if a given episode/map combination is valid for this mission/mode
fn d_valid_episode_map(mission GameMission, mode GameMode, episode int, map int) bool {
	// Hacks for Heretic secret episodes
	if mission == .heretic {
		if mode == .retail && episode == 6 {
			return map >= 1 && map <= 3
		} else if mode == .registered && episode == 4 {
			return map == 1
		}
	}

	// Find the table entry for this mission/mode combination.
	for vm in valid_modes {
		if mission == vm.mission && mode == vm.mode {
			return episode >= 1 && episode <= vm.episode && map >= 1 && map <= vm.map
		}
	}

	// Unknown mode/mission combination
	return false
}

// Get the number of valid episodes for the specified mission/mode.
fn d_get_num_episodes(mission GameMission, mode GameMode) int {
	mut episode int = 1

	for d_valid_episode_map(mission, mode, episode, 1) {
		episode++
	}

	return episode - 1
}

// Check if a given mission/version combination is valid
fn d_valid_game_version(mission GameMission, version GameVersion) bool {
	mut check_mission GameMission = mission

	// All Doom variants can use the Doom versions.
	if mission == .doom2 || mission == .pack_plut || mission == .pack_tnt ||
	   mission == .pack_hacx || mission == .pack_chex {
		check_mission = .doom
	}

	for vv in valid_versions {
		if vv.mission == check_mission && vv.version == version {
			return true
		}
	}

	return false
}

// Does this mission type use ExMy form, rather than MAPxy form?
fn d_is_episode_map(mission GameMission) bool {
	match mission {
		.doom, .heretic, .pack_chex { return true }
		.none, .hexen, .doom2, .pack_hacx, .pack_tnt, .pack_plut, .strife { return false }
	}
	return false
}

// Get the string name of a game mission
fn d_game_mission_string(mission GameMission) &char {
	match mission {
		.none { return c"none" }
		.doom { return c"doom" }
		.doom2 { return c"doom2" }
		.pack_tnt { return c"tnt" }
		.pack_plut { return c"plutonia" }
		.pack_hacx { return c"hacx" }
		.pack_chex { return c"chex" }
		.heretic { return c"heretic" }
		.hexen { return c"hexen" }
		.strife { return c"strife" }
	}
	return c"none"
}

// Get the string name of a game mode
fn d_game_mode_string(mode GameMode) &char {
	match mode {
		.shareware { return c"shareware" }
		.registered { return c"registered" }
		.commercial { return c"commercial" }
		.retail { return c"retail" }
		.indetermined { return c"unknown" }
	}
	return c"unknown"
}
