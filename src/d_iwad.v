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
//     Find IWAD and initialize according to IWAD type.
//

// IWAD mask constants for determining which games we support
const iwad_mask_doom = (1 << int(.doom) |
                        1 << int(.doom2) |
                        1 << int(.pack_tnt) |
                        1 << int(.pack_plut) |
                        1 << int(.pack_chex) |
                        1 << int(.pack_hacx))

const iwad_mask_heretic = 1 << int(.heretic)
const iwad_mask_hexen = 1 << int(.hexen)
const iwad_mask_strife = 1 << int(.strife)

// IWAD description structure
struct IWad {
	name &char
	mission GameMission
	mode GameMode
	description &char
}

// Static IWAD list
const iwads = [
	IWad{c"doom2.wad", .doom2, .commercial, c"Doom II"},
	IWad{c"plutonia.wad", .pack_plut, .commercial, c"Final Doom: Plutonia Experiment"},
	IWad{c"tnt.wad", .pack_tnt, .commercial, c"Final Doom: TNT: Evilution"},
	IWad{c"doom.wad", .doom, .retail, c"Doom"},
	IWad{c"doom1.wad", .doom, .shareware, c"Doom Shareware"},
	IWad{c"chex.wad", .pack_chex, .retail, c"Chex Quest"},
	IWad{c"hacx.wad", .pack_hacx, .commercial, c"Hacx"},
	IWad{c"freedoom2.wad", .doom2, .commercial, c"Freedoom: Phase 2"},
	IWad{c"freedoom1.wad", .doom, .retail, c"Freedoom: Phase 1"},
	IWad{c"freedm.wad", .doom2, .commercial, c"FreeDM"},
	IWad{c"heretic.wad", .heretic, .retail, c"Heretic"},
	IWad{c"heretic1.wad", .heretic, .shareware, c"Heretic Shareware"},
	IWad{c"hexen.wad", .hexen, .commercial, c"Hexen"},
	IWad{c"strife1.wad", .strife, .commercial, c"Strife"},
]!

// IWAD search directories
const max_iwad_dirs = 128

mut iwad_dirs_built bool = false
mut iwad_dirs [max_iwad_dirs]&char
mut num_iwad_dirs int = 0

// D_IsIWADName
fn d_is_iwad_name(name &char) bool {
	for iwad in iwads {
		if C.strcasecmp(name, iwad.name) == 0 {
			return true
		}
	}

	return false
}

// D_FindWADByName
// Searches WAD search paths for a WAD with a specific filename.
fn d_find_wad_by_name(name &char) &char {
	mut path &char
	mut probe &char
	mut i int

	// Absolute path?
	probe = m_file_case_exists(name)
	if probe != unsafe { nil } {
		return probe
	}

	d_build_iwad_dir_list()

	// Search through all IWAD paths for a file with the given name.
	for i = 0; i < num_iwad_dirs; i++ {
		// Construct a string for the full path
		path = m_string_join(iwad_dirs[i], dir_separator_s, name, unsafe { nil })

		probe = m_file_case_exists(path)
		if probe != unsafe { nil } {
			return probe
		}

		C.free(unsafe { path })
	}

	// File not found
	return unsafe { nil }
}

// D_TryFindWADByName
// Searches for a WAD by its filename, or returns a copy of the filename if not found.
fn d_try_find_wad_by_name(filename &char) &char {
	mut result &char = d_find_wad_by_name(filename)

	if result != unsafe { nil } {
		return result
	} else {
		return m_string_duplicate(filename)
	}
}

// D_FindIWAD
// Checks availability of IWAD files by name,
// to determine whether registered/commercial features should be executed.
fn d_find_iwad(mask int, mission &GameMission) &char {
	mut result &char
	mut iwadfile &char
	mut iwadparm int
	mut i int

	// Check for the -iwad parameter
	iwadparm = m_check_parm_with_args(c"-iwad", 1)

	if iwadparm != 0 {
		// Search through IWAD dirs for an IWAD with the given name.
		iwadfile = myargv[iwadparm + 1]

		result = d_find_wad_by_name(iwadfile)

		if result == unsafe { nil } {
			i_error(c"IWAD file '%s' not found!", iwadfile)
		}

		unsafe { *mission } = d_identify_iwad_by_name(result, mask)
	} else {
		// Search through the list and look for an IWAD
		result = unsafe { nil }

		d_build_iwad_dir_list()

		for i = 0; result == unsafe { nil } && i < num_iwad_dirs; i++ {
			result = d_search_directory_for_iwad(iwad_dirs[i], mask, mission)
		}
	}

	return result
}

// D_FindAllIWADs
// Find all IWADs in the IWAD search path matching the given mask.
fn d_find_all_iwads(mask int) []&IWad {
	mut result []&IWad
	mut filename &char
	mut i int

	result = []&IWad{}

	// Try to find all IWADs
	for iwad in iwads {
		if ((1 << int(iwad.mission)) & mask) == 0 {
			continue
		}

		filename = d_find_wad_by_name(iwad.name)

		if filename != unsafe { nil } {
			result << &iwad
		}
	}

	return result
}

// D_SaveGameIWADName
// Get the IWAD name used for savegames.
fn d_save_game_iwad_name(gamemission GameMission) &char {
	mut i int

	// Determine the IWAD name to use for savegames.
	// This determines the directory the savegame files get put into.
	// Note that we match on gamemission rather than on IWAD name.
	// This ensures that doom1.wad and doom.wad saves are stored in the same place.

	for iwad in iwads {
		if gamemission == iwad.mission {
			return iwad.name
		}
	}

	// Default fallback:
	return c"unknown.wad"
}

// D_SuggestIWADName
fn d_suggest_iwad_name(mission GameMission, mode GameMode) &char {
	for iwad in iwads {
		if iwad.mission == mission && iwad.mode == mode {
			return iwad.name
		}
	}

	return c"unknown.wad"
}

// D_SuggestGameName
fn d_suggest_game_name(mission GameMission, mode GameMode) &char {
	for iwad in iwads {
		if iwad.mission == mission && (mode == .indetermined || iwad.mode == mode) {
			return iwad.description
		}
	}

	return c"Unknown game?"
}

// D_CheckCorrectIWAD
fn d_check_correct_iwad(mission GameMission) {
	// Placeholder for Windows-specific checks
	// This function performs platform-specific IWAD validation
}

// Forward declarations for functions defined elsewhere

fn d_build_iwad_dir_list()
fn d_search_directory_for_iwad(dir &char, mask int, mission &GameMission) &char
fn d_identify_iwad_by_name(filename &char, mask int) GameMission

fn m_check_parm_with_args(parm &char, num_args int) int
fn m_file_case_exists(path &char) &char
fn m_string_join(s &char, ...rest any) &char
fn m_string_duplicate(orig &char) &char
fn m_dir_name(path &char) &char

fn i_error(msg &char, ...any)
