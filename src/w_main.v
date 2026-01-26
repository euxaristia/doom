@[translated]
module main

// WAD file merging mode flags for NWT-style operations
const w_nwt_merge_flats = 1    // Merge flats
const w_nwt_merge_sprites = 2  // Merge sprites

// Forward declarations for external dependencies
fn m_check_parm_with_args(check &char, num_args int) int
fn d_try_find_wad_by_name(name &char) &char
fn w_merge_file(filename &char)
fn w_nwt_dash_merge(filename &char)
fn w_nwt_merge_file(filename &char, flags int)
fn w_add_file(filename &char)
fn w_check_num_for_name(lumpname &char) int
fn d_suggest_game_name(mission int, variant int) &char
fn d_game_mission_string(mission int) &char
fn i_error(error &char, args ...voidptr)

// Game mission types
const game_mission_doom = 0
const game_mission_heretic = 1
const game_mission_hexen = 2
const game_mission_strife = 3

// Unique lumps for different game missions
struct unique_lump_t {
	mission int
	lumpname &char
}

const unique_lumps = [
	unique_lump_t{ mission: game_mission_doom, lumpname: c'POSSA1' },
	unique_lump_t{ mission: game_mission_heretic, lumpname: c'IMPXA1' },
	unique_lump_t{ mission: game_mission_hexen, lumpname: c'ETTNA1' },
	unique_lump_t{ mission: game_mission_strife, lumpname: c'AGRDA1' },
]

// W_ParseCommandLine - Parse command line arguments and load WAD files
fn w_parse_command_line() bool {
	mut modified_game := false
	mut p := 0

	// Merged PWADs are loaded first, because they are supposed to be
	// modified IWADs

	// Check for -merge option
	p = m_check_parm_with_args(c'-merge', 1)

	if p > 0 {
		mut idx := p + 1
		for idx < myargc && unsafe { myargv[idx][0] } != `-` {
			filename := d_try_find_wad_by_name(unsafe { myargv[idx] })

			modified_game = true

			C.printf(c' merging %s\n', filename)
			w_merge_file(filename)
			C.free(filename)

			idx++
		}
	}

	// NWT-style merging - NWT's -merge option
	p = m_check_parm_with_args(c'-nwtmerge', 1)

	if p > 0 {
		mut idx := p + 1
		for idx < myargc && unsafe { myargv[idx][0] } != `-` {
			filename := d_try_find_wad_by_name(unsafe { myargv[idx] })

			modified_game = true

			C.printf(c' performing NWT-style merge of %s\n', filename)
			w_nwt_dash_merge(filename)
			C.free(filename)

			idx++
		}
	}

	// Add flats - Simulates NWT's -af option
	p = m_check_parm_with_args(c'-af', 1)

	if p > 0 {
		mut idx := p + 1
		for idx < myargc && unsafe { myargv[idx][0] } != `-` {
			filename := d_try_find_wad_by_name(unsafe { myargv[idx] })

			modified_game = true

			C.printf(c' merging flats from %s\n', filename)
			w_nwt_merge_file(filename, w_nwt_merge_flats)
			C.free(filename)

			idx++
		}
	}

	// Add sprites - Simulates NWT's -as option
	p = m_check_parm_with_args(c'-as', 1)

	if p > 0 {
		mut idx := p + 1
		for idx < myargc && unsafe { myargv[idx][0] } != `-` {
			filename := d_try_find_wad_by_name(unsafe { myargv[idx] })

			modified_game = true

			C.printf(c' merging sprites from %s\n', filename)
			w_nwt_merge_file(filename, w_nwt_merge_sprites)
			C.free(filename)

			idx++
		}
	}

	// Add sprites and flats - Equivalent to "-af <files> -as <files>"
	p = m_check_parm_with_args(c'-aa', 1)

	if p > 0 {
		mut idx := p + 1
		for idx < myargc && unsafe { myargv[idx][0] } != `-` {
			filename := d_try_find_wad_by_name(unsafe { myargv[idx] })

			modified_game = true

			C.printf(c' merging sprites and flats from %s\n', filename)
			w_nwt_merge_file(filename, w_nwt_merge_sprites | w_nwt_merge_flats)
			C.free(filename)

			idx++
		}
	}

	// Load PWADs - Load specified PWAD files (vanilla option)
	p = m_check_parm_with_args(c'-file', 1)

	if p > 0 {
		// the parms after p are wadfile/lump names,
		// until end of parms or another - preceded parm
		modified_game = true // homebrew levels
		mut idx := p + 1
		for idx < myargc && unsafe { myargv[idx][0] } != `-` {
			filename := d_try_find_wad_by_name(unsafe { myargv[idx] })

			C.printf(c' adding %s\n', filename)
			w_add_file(filename)
			C.free(filename)

			idx++
		}
	}

	return modified_game
}

// W_AutoLoadWADs - Load all WAD files from the given directory
fn w_auto_load_wads(path &char) {
	// Note: This would require i_glob functions to be ported
	// For now, this is a placeholder stub
	C.printf(c' [autoload] Path: %s\n', path)
}

// W_CheckCorrectIWAD - Check that the IWAD is correct for the game mission
fn w_check_correct_iwad(mission int) {
	for i := 0; i < unique_lumps.len; i++ {
		if mission != unique_lumps[i].mission {
			lumpnum := w_check_num_for_name(unique_lumps[i].lumpname)

			if lumpnum >= 0 {
				i_error(
					c'\nYou are trying to use a %s IWAD file with the %s%s binary.\nThis isn\'t going to work.\nYou probably want to use the %s%s binary.',
					d_suggest_game_name(unique_lumps[i].mission, 0),
					c'DOOM',
					d_game_mission_string(mission),
					c'DOOM',
					d_game_mission_string(unique_lumps[i].mission))
			}
		}
	}
}
