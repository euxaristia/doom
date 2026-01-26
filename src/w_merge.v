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
// Handles merging of PWADs, similar to deutex's -merge option
//

const w_nwt_merge_sprites = 0x1
const w_nwt_merge_flats = 0x2

// Section types for WAD merging
enum SectionType {
	section_normal = 0
	section_flats = 1
	section_sprites = 2
}

// Sprite frame structure for tracking replacements
struct SpriteFrame {
	sprname [4]u8
	frame u8
	angle_lumps [8]&LumpInfo
}

// Search list structure
struct SearchList {
	mut lumps []&LumpInfo
	mut numlumps int
}

// Forward declaration of external types
type LumpInfo = C.lumpinfo_t

// Global search lists
mut iwad SearchList
mut iwad_sprites SearchList
mut pwad SearchList

mut iwad_flats SearchList
mut pwad_sprites SearchList
mut pwad_flats SearchList

// Sprite frame tracking
mut sprite_frames []SpriteFrame = []
mut num_sprite_frames = 0
mut sprite_frames_alloced = 0

// External globals and functions
@[extern]
fn extern_numlumps() u32
@[extern]
fn extern_set_numlumps(count u32)
@[extern]
fn extern_lumpinfo() []&LumpInfo
@[extern]
fn extern_set_lumpinfo(lumps []&LumpInfo)
@[extern]
fn extern_w_add_file(filename &char) &C.wad_file_t
@[extern]
fn extern_w_close_file(wad_file &C.wad_file_t)

// Search in a list to find a lump with a particular name
// Returns -1 if not found
fn find_in_list(list &SearchList, name &char) int {
	mut i int

	for i = 0; i < list.numlumps; i++ {
		if C.strncasecmp(&char(list.lumps[i].name[0]), name, 8) == 0 {
			return i
		}
	}

	return -1
}

// Setup a search list from a source list with start/end markers
fn setup_list(list &SearchList, src_list &SearchList, startname &char, endname &char,
	startname2 &char, endname2 &char) bool {
	mut startlump int
	mut endlump int

	list.numlumps = 0
	startlump = find_in_list(src_list, startname)

	if startname2 != nil && startlump < 0 {
		startlump = find_in_list(src_list, startname2)
	}

	if startlump >= 0 {
		endlump = find_in_list(src_list, endname)

		if endname2 != nil && endlump < 0 {
			endlump = find_in_list(src_list, endname2)
		}

		if endlump > startlump {
			list.lumps = src_list.lumps[startlump + 1..endlump]
			list.numlumps = endlump - startlump - 1
			return true
		}
	}

	return false
}

// Setup the sprite/flat search lists
fn setup_lists() {
	// IWAD

	if !setup_list(&iwad_flats, &iwad, "F_START", "F_END", nil, nil) {
		C.I_Error("Flats section not found in IWAD")
	}

	if !setup_list(&iwad_sprites, &iwad, "S_START", "S_END", nil, nil) {
		C.I_Error("Sprites section not found in IWAD")
	}

	// PWAD

	setup_list(&pwad_flats, &pwad, "F_START", "F_END", "FF_START", "FF_END")
	setup_list(&pwad_sprites, &pwad, "S_START", "S_END", "SS_START", "SS_END")
}

// Initialize the replace list
fn init_sprite_list() {
	if sprite_frames.len == 0 {
		sprite_frames_alloced = 128
		sprite_frames = []SpriteFrame{len: 128}
	}

	num_sprite_frames = 0
}

// Check if sprite lump name is valid
fn valid_sprite_lump_name(name &char) bool {
	if name[0] == 0 || name[1] == 0 || name[2] == 0 || name[3] == 0 {
		return false
	}

	// First frame:
	if name[4] == 0 || !C.isdigit(name[5]) {
		return false
	}

	// Second frame (optional):
	if name[6] != 0 && !C.isdigit(name[7]) {
		return false
	}

	return true
}

// Find a sprite frame, creating if necessary
fn find_sprite_frame(name &char, frame u8) &SpriteFrame {
	mut result &SpriteFrame
	mut i int
	mut cur &SpriteFrame

	// Search the list and try to find the frame

	for i = 0; i < num_sprite_frames; i++ {
		cur = &sprite_frames[i]

		if C.strncasecmp(&char(cur.sprname[0]), name, 4) == 0 && cur.frame == frame {
			return cur
		}
	}

	// Not found in list; Need to add to the list

	// Grow list?

	if num_sprite_frames >= sprite_frames_alloced {
		mut newframes []SpriteFrame
		mut j int

		newframes = []SpriteFrame{len: sprite_frames_alloced * 2}
		for j = 0; j < sprite_frames_alloced; j++ {
			newframes[j] = sprite_frames[j]
		}
		sprite_frames = newframes
		sprite_frames_alloced *= 2
	}

	// Add to end of list

	result = &sprite_frames[num_sprite_frames]
	C.memcpy(&char(result.sprname[0]), name, 4)
	result.frame = frame

	for i = 0; i < 8; i++ {
		result.angle_lumps[i] = nil
	}

	num_sprite_frames++

	return result
}

// Check if sprite lump is needed in the new wad
fn sprite_lump_needed(lump &LumpInfo) bool {
	mut sprite &SpriteFrame
	mut angle_num int
	mut i int

	if !valid_sprite_lump_name(&char(lump.name[0])) {
		return true
	}

	// check the first frame

	sprite = find_sprite_frame(&char(lump.name[0]), lump.name[4])
	angle_num = int(lump.name[5]) - int('0')

	if angle_num == 0 {
		// must check all frames

		for i = 0; i < 8; i++ {
			if sprite.angle_lumps[i] == lump {
				return true
			}
		}
	} else {
		// check if this lump is being used for this frame

		if sprite.angle_lumps[angle_num - 1] == lump {
			return true
		}
	}

	// second frame if any

	// no second frame?
	if lump.name[6] == 0 {
		return false
	}

	sprite = find_sprite_frame(&char(lump.name[0]), lump.name[6])
	angle_num = int(lump.name[7]) - int('0')

	if angle_num == 0 {
		// must check all frames

		for i = 0; i < 8; i++ {
			if sprite.angle_lumps[i] == lump {
				return true
			}
		}
	} else {
		// check if this lump is being used for this frame

		if sprite.angle_lumps[angle_num - 1] == lump {
			return true
		}
	}

	return false
}

// Add sprite lump to tracking list
fn add_sprite_lump(lump &LumpInfo) {
	mut sprite &SpriteFrame
	mut angle_num int
	mut i int

	if !valid_sprite_lump_name(&char(lump.name[0])) {
		return
	}

	// first angle

	sprite = find_sprite_frame(&char(lump.name[0]), lump.name[4])
	angle_num = int(lump.name[5]) - int('0')

	if angle_num == 0 {
		for i = 0; i < 8; i++ {
			sprite.angle_lumps[i] = lump
		}
	} else {
		sprite.angle_lumps[angle_num - 1] = lump
	}

	// second angle

	// no second angle?

	if lump.name[6] == 0 {
		return
	}

	sprite = find_sprite_frame(&char(lump.name[0]), lump.name[6])
	angle_num = int(lump.name[7]) - int('0')

	if angle_num == 0 {
		for i = 0; i < 8; i++ {
			sprite.angle_lumps[i] = lump
		}
	} else {
		sprite.angle_lumps[angle_num - 1] = lump
	}
}

// Generate the list. Run at the start, before merging
fn generate_sprite_list() {
	mut i int

	init_sprite_list()

	// Add all sprites from the IWAD

	for i = 0; i < iwad_sprites.numlumps; i++ {
		add_sprite_lump(iwad_sprites.lumps[i])
	}

	// Add all sprites from the PWAD
	// (replaces IWAD sprites)

	for i = 0; i < pwad_sprites.numlumps; i++ {
		add_sprite_lump(pwad_sprites.lumps[i])
	}
}

// Perform the merge
fn do_merge() {
	mut current_section SectionType
	mut newlumps []&LumpInfo
	mut num_newlumps int
	mut lumpindex int
	mut i int
	mut n int
	mut numlumps u32
	mut lumpinfo_arr []&LumpInfo

	// Get current lump info
	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()

	// Can't ever have more lumps than we already have
	newlumps = []&LumpInfo{len: int(numlumps)}
	num_newlumps = 0

	// Add IWAD lumps
	current_section = .section_normal

	for i = 0; i < iwad.numlumps; i++ {
		mut lump &LumpInfo = iwad.lumps[i]

		match current_section {
			.section_normal {
				if C.strncasecmp(&char(lump.name[0]), "F_START", 8) == 0 {
					current_section = .section_flats
				} else if C.strncasecmp(&char(lump.name[0]), "S_START", 8) == 0 {
					current_section = .section_sprites
				}

				newlumps[num_newlumps] = lump
				num_newlumps++
			}
			.section_flats {
				// Have we reached the end of the section?

				if C.strncasecmp(&char(lump.name[0]), "F_END", 8) == 0 {
					// Add all new flats from the PWAD to the end
					// of the section

					for n = 0; n < pwad_flats.numlumps; n++ {
						newlumps[num_newlumps] = pwad_flats.lumps[n]
						num_newlumps++
					}

					newlumps[num_newlumps] = lump
					num_newlumps++

					// back to normal reading
					current_section = .section_normal
				} else {
					// If there is a flat in the PWAD with the same name,
					// do not add it now. All PWAD flats are added to the
					// end of the section. Otherwise, if it is only in the
					// IWAD, add it now

					lumpindex = find_in_list(&pwad_flats, &char(lump.name[0]))

					if lumpindex < 0 {
						newlumps[num_newlumps] = lump
						num_newlumps++
					}
				}
			}
			.section_sprites {
				// Have we reached the end of the section?

				if C.strncasecmp(&char(lump.name[0]), "S_END", 8) == 0 {
					// add all the PWAD sprites

					for n = 0; n < pwad_sprites.numlumps; n++ {
						if sprite_lump_needed(pwad_sprites.lumps[n]) {
							newlumps[num_newlumps] = pwad_sprites.lumps[n]
							num_newlumps++
						}
					}

					// copy the ending
					newlumps[num_newlumps] = lump
					num_newlumps++

					// back to normal reading
					current_section = .section_normal
				} else {
					// Is this lump holding a sprite to be replaced in the
					// PWAD? If so, wait until the end to add it.

					if sprite_lump_needed(lump) {
						newlumps[num_newlumps] = lump
						num_newlumps++
					}
				}
			}
		}
	}

	// Add PWAD lumps
	current_section = .section_normal

	for i = 0; i < pwad.numlumps; i++ {
		mut lump &LumpInfo = pwad.lumps[i]

		match current_section {
			.section_normal {
				if C.strncasecmp(&char(lump.name[0]), "F_START", 8) == 0 ||
					C.strncasecmp(&char(lump.name[0]), "FF_START", 8) == 0 {
					current_section = .section_flats
				} else if C.strncasecmp(&char(lump.name[0]), "S_START", 8) == 0 ||
					C.strncasecmp(&char(lump.name[0]), "SS_START", 8) == 0 {
					current_section = .section_sprites
				} else {
					// Don't include the headers of sections

					newlumps[num_newlumps] = lump
					num_newlumps++
				}
			}
			.section_flats {
				// PWAD flats are ignored (already merged)

				if C.strncasecmp(&char(lump.name[0]), "FF_END", 8) == 0 ||
					C.strncasecmp(&char(lump.name[0]), "F_END", 8) == 0 {
					// end of section
					current_section = .section_normal
				}
			}
			.section_sprites {
				// PWAD sprites are ignored (already merged)

				if C.strncasecmp(&char(lump.name[0]), "SS_END", 8) == 0 ||
					C.strncasecmp(&char(lump.name[0]), "S_END", 8) == 0 {
					// end of section
					current_section = .section_normal
				}
			}
		}
	}

	// Switch to the new lumpinfo, and free the old one

	extern_set_lumpinfo(newlumps[0..num_newlumps])
	extern_set_numlumps(u32(num_newlumps))
}

// Print WAD directory (debug function)
pub fn w_print_directory() {
	mut i u32
	mut n u32
	mut numlumps u32
	mut lumpinfo_arr []&LumpInfo

	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()

	// debug
	for i = 0; i < numlumps; i++ {
		for n = 0; n < 8 && lumpinfo_arr[i].name[n] != 0; n++ {
			C.putchar(int(lumpinfo_arr[i].name[n]))
		}
		C.putchar(int('\n'))
	}
}

// Merge in a file by name
pub fn w_merge_file(filename &char) {
	mut old_numlumps u32
	mut numlumps u32
	mut lumpinfo_arr []&LumpInfo

	// Get current state
	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()
	old_numlumps = numlumps

	// Load PWAD

	if extern_w_add_file(filename) == nil {
		return
	}

	// IWAD is at the start, PWAD was appended to the end

	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()

	iwad.lumps = lumpinfo_arr[0..old_numlumps]
	iwad.numlumps = int(old_numlumps)

	pwad.lumps = lumpinfo_arr[old_numlumps..numlumps]
	pwad.numlumps = int(numlumps - old_numlumps)

	// Setup sprite/flat lists

	setup_lists()

	// Generate list of sprites to be replaced by the PWAD

	generate_sprite_list()

	// Perform the merge

	do_merge()
}

// Replace lumps in the given list with lumps from the PWAD
fn w_nwt_add_lumps(list &SearchList) {
	mut i int
	mut index int

	// Go through the IWAD list given, replacing lumps with lumps of
	// the same name from the PWAD
	for i = 0; i < list.numlumps; i++ {
		index = find_in_list(&pwad, &char(list.lumps[i].name[0]))

		if index > 0 {
			mut dst &LumpInfo = list.lumps[i]
			mut src &LumpInfo = pwad.lumps[index]
			C.memcpy(dst, src, sizeof(LumpInfo))
		}
	}
}

// Merge sprites and flats in the way NWT does with its -af and -as
// command-line options.
pub fn w_nwt_merge_file(filename &char, flags int) {
	mut old_numlumps u32
	mut numlumps u32
	mut lumpinfo_arr []&LumpInfo

	// Get current state
	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()
	old_numlumps = numlumps

	// Load PWAD

	if extern_w_add_file(filename) == nil {
		return
	}

	// IWAD is at the start, PWAD was appended to the end

	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()

	iwad.lumps = lumpinfo_arr[0..old_numlumps]
	iwad.numlumps = int(old_numlumps)

	pwad.lumps = lumpinfo_arr[old_numlumps..numlumps]
	pwad.numlumps = int(numlumps - old_numlumps)

	// Setup sprite/flat lists

	setup_lists()

	// Merge in flats?

	if flags & w_nwt_merge_flats != 0 {
		w_nwt_add_lumps(&iwad_flats)
	}

	// Sprites?

	if flags & w_nwt_merge_sprites != 0 {
		w_nwt_add_lumps(&iwad_sprites)
	}

	// Discard the PWAD

	extern_set_numlumps(old_numlumps)
}

// Simulates the NWT -merge command line parameter. What this does is load
// a PWAD, then search the IWAD sprites, removing any sprite lumps that also
// exist in the PWAD.
pub fn w_nwt_dash_merge(filename &char) {
	mut wad_file &C.wad_file_t
	mut old_numlumps u32
	mut numlumps u32
	mut lumpinfo_arr []&LumpInfo
	mut i int

	// Get current state
	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()
	old_numlumps = numlumps

	// Load PWAD

	wad_file = extern_w_add_file(filename)

	if wad_file == nil {
		return
	}

	// IWAD is at the start, PWAD was appended to the end

	numlumps = extern_numlumps()
	lumpinfo_arr = extern_lumpinfo()

	iwad.lumps = lumpinfo_arr[0..old_numlumps]
	iwad.numlumps = int(old_numlumps)

	pwad.lumps = lumpinfo_arr[old_numlumps..numlumps]
	pwad.numlumps = int(numlumps - old_numlumps)

	// Setup sprite/flat lists

	setup_lists()

	// Search through the IWAD sprites list.

	for i = 0; i < iwad_sprites.numlumps; i++ {
		if find_in_list(&pwad, &char(iwad_sprites.lumps[i].name[0])) >= 0 {
			// Replace this entry with an empty string. This is what
			// nwt -merge does.

			C.memset(&char(iwad_sprites.lumps[i].name[0]), 0, 8)
		}
	}

	// Discard PWAD
	// The PWAD must now be added in again with -file.

	extern_set_numlumps(old_numlumps)

	extern_w_close_file(wad_file)
}
