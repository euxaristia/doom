@[translated]
module main

//
// Copyright(C) 1993-1996 Id Software, Inc.
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
//       Generate a checksum of the WAD directory.
//

// Forward declarations for external types
type WadFile = C.wad_file_t
type Sha1Context = C.sha1_context_t
type Sha1Digest = C.sha1_digest_t

// Type alias for LumpInfo (from w_wad.v)
type LumpInfo = C.lumpinfo_t

// Global state
mut open_wadfiles []&WadFile = []
mut num_open_wadfiles = 0

// External globals from w_wad module
@[extern]
fn extern_numlumps() u32
@[extern]
fn extern_lumpinfo() []&LumpInfo

// Get the file number for a WAD file handle
fn get_file_number(handle &WadFile) int {
	mut i int
	mut result int

	for i = 0; i < num_open_wadfiles; i++ {
		if open_wadfiles[i] == handle {
			return i
		}
	}

	// Not found in list. This is a new file we haven't seen yet.
	// Allocate another slot for this file.
	open_wadfiles << handle

	result = num_open_wadfiles
	num_open_wadfiles++

	return result
}

// Add lump information to the SHA1 hash
fn checksum_add_lump(sha1_context &Sha1Context, lump &LumpInfo) {
	mut buf [9]u8

	// Copy lump name to buffer
	C.strcpy(&char(buf[0]), &char(lump.name[0]))

	// Update SHA1 hash with lump data
	C.SHA1_UpdateString(sha1_context, &char(buf[0]))
	C.SHA1_UpdateInt32(sha1_context, get_file_number(lump.wad_file))
	C.SHA1_UpdateInt32(sha1_context, lump.position)
	C.SHA1_UpdateInt32(sha1_context, lump.size)
}

// Calculate WAD directory checksum
pub fn w_checksum(digest &Sha1Digest) {
	mut sha1_context Sha1Context
	mut i u32
	mut numlumps u32

	C.SHA1_Init(&sha1_context)

	num_open_wadfiles = 0

	// Go through each entry in the WAD directory, adding information
	// about each entry to the SHA1 hash.

	numlumps = extern_numlumps()
	mut lumpinfo_arr = extern_lumpinfo()

	for i = 0; i < numlumps; i++ {
		checksum_add_lump(&sha1_context, lumpinfo_arr[i])
	}

	C.SHA1_Final(digest, &sha1_context)
}
