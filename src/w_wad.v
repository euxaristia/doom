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
//	WAD I/O functions.
//

// WAD file type alias
type WadFile = C.wad_file_t
type LumpIndex = int

// WADFILE I/O related structures
struct LumpInfo {
	name [8]u8
	wad_file &WadFile
	position int
	size int
	cache voidptr
	// Used for hash table lookups
	next LumpIndex
}

// Global lump directory
mut lumpinfo []&LumpInfo
mut numlumps u32

// Local hash table for fast lookups
mut lumphash []LumpIndex = []

// Variables for the reload hack
mut reloadhandle &WadFile
mut reloadlumps &LumpInfo
mut reloadname &char
mut reloadlump int

// Packed structures for WAD file format
[packed]
struct WadInfo {
	identification [4]u8
	numlumps int
	infotableofs int
}

[packed]
struct FileLump {
	filepos int
	size int
	name [8]u8
}

// Hash function used for lump names (djb2 algorithm)
fn w_lump_name_hash(s &char) u32 {
	mut result u32 = 5381
	mut i u32

	for i = 0; i < 8 && s[i] != 0; i++ {
		result = ((result << 5) ^ result) ^ C.toupper(s[i])
	}

	return result
}

// W_AddFile
// All files are optional, but at least one file must be found (PWAD, if all required lumps are present).
// Files with a .wad extension are wadlink files with multiple lumps.
// Other files are single lumps with the base filename for the lump name.
fn w_add_file(filename &char) &WadFile {
	mut header WadInfo
	mut i LumpIndex
	mut wad_file &WadFile
	mut length int
	mut startlump int
	mut fileinfo &FileLump
	mut filerover &FileLump
	mut filelumps &LumpInfo
	mut numfilelumps int

	// If the filename begins with a ~, it indicates that we should use the reload hack.
	if filename[0] == `~` {
		if reloadname != unsafe { nil } {
			i_error(c"Prefixing a WAD filename with '~' indicates that the WAD should be reloaded\non each level restart, for use by level authors for rapid development. You\ncan only reload one WAD file, and it must be the last file in the -file list.")
		}

		reloadname = C.strdup(filename)
		reloadlump = int(numlumps)
		filename = unsafe { filename + 1 }
	}

	// Open the file and add to directory
	wad_file = w_open_file(filename)

	if wad_file == unsafe { nil } {
		C.printf(c" couldn't open %s\n", filename)
		return unsafe { nil }
	}

	if C.strcasecmp(filename + C.strlen(filename) - 3, c"wad") != 0 {
		// single lump file
		fileinfo = z_malloc(sizeof(FileLump), pu_static, unsafe { nil })
		fileinfo.filepos = int(C.LONG(0))
		fileinfo.size = int(C.LONG(wad_file.length))

		// Name the lump after the base of the filename (without the extension).
		m_extract_file_base(filename, &fileinfo.name[0])
		numfilelumps = 1
	} else {
		// WAD file
		w_read(wad_file, 0, &header, sizeof(WadInfo))

		if C.strncmp(unsafe { &header.identification[0] }, c"IWAD", 4) != 0 {
			// Homebrew levels?
			if C.strncmp(unsafe { &header.identification[0] }, c"PWAD", 4) != 0 {
				w_close_file(wad_file)
				i_error(c"Wad file %s doesn't have IWAD or PWAD id\n", filename)
			}
		}

		header.numlumps = int(C.LONG(u32(header.numlumps)))

		// Vanilla Doom doesn't like WADs with more than 4046 lumps
		if C.strncmp(unsafe { &header.identification[0] }, c"PWAD", 4) == 0 && header.numlumps > 4046 {
			w_close_file(wad_file)
			i_error(c"Error: Vanilla limit for lumps in a WAD is 4046, PWAD %s has %d", filename, header.numlumps)
		}

		header.infotableofs = int(C.LONG(u32(header.infotableofs)))
		length = header.numlumps * sizeof(FileLump)
		fileinfo = z_malloc(length, pu_static, unsafe { nil })

		w_read(wad_file, header.infotableofs, fileinfo, length)
		numfilelumps = header.numlumps
	}

	// Increase size of numlumps array to accommodate the new file.
	filelumps = C.calloc(u32(numfilelumps), sizeof(LumpInfo))
	if filelumps == unsafe { nil } {
		w_close_file(wad_file)
		i_error(c"Failed to allocate array for lumps from new file.")
	}

	startlump = int(numlumps)
	numlumps += u32(numfilelumps)
	lumpinfo = i_realloc(unsafe { lumpinfo }, int(numlumps) * sizeof(&LumpInfo))
	filerover = fileinfo

	for i = LumpIndex(startlump); i < LumpIndex(numlumps); i++ {
		mut lump_p &LumpInfo = &filelumps[i - LumpIndex(startlump)]
		lump_p.wad_file = wad_file
		lump_p.position = int(C.LONG(u32(filerover.filepos)))
		lump_p.size = int(C.LONG(u32(filerover.size)))
		lump_p.cache = unsafe { nil }
		C.strncpy(unsafe { &lump_p.name[0] }, unsafe { &filerover.name[0] }, 8)
		lumpinfo[i] = lump_p

		filerover = unsafe { filerover + 1 }
	}

	z_free(unsafe { fileinfo })

	if lumphash.len > 0 {
		z_free(unsafe { lumphash.data })
		lumphash = []
	}

	// If this is the reload file, we need to save some details about the file
	if reloadname != unsafe { nil } {
		reloadhandle = wad_file
		reloadlumps = filelumps
	}

	return wad_file
}

// W_NumLumps
fn w_num_lumps() int {
	return int(numlumps)
}

// W_CheckNumForName
// Returns -1 if name not found.
fn w_check_num_for_name(name &char) LumpIndex {
	mut i LumpIndex
	mut hash int

	// Do we have a hash table yet?
	if lumphash.len > 0 {
		// We do! Excellent.
		hash = int(w_lump_name_hash(name)) % int(numlumps)

		for i = lumphash[hash]; i != -1; i = lumpinfo[i].next {
			if C.strncasecmp(unsafe { &lumpinfo[i].name[0] }, name, 8) == 0 {
				return i
			}
		}
	} else {
		// We don't have a hash table yet. Linear search :-(
		// Scan backwards so patch lump files take precedence
		for i = LumpIndex(numlumps) - 1; i >= 0; i-- {
			if C.strncasecmp(unsafe { &lumpinfo[i].name[0] }, name, 8) == 0 {
				return i
			}
		}
	}

	// TFB. Not found.
	return -1
}

// W_GetNumForName
// Calls W_CheckNumForName, but bombs out if not found.
fn w_get_num_for_name(name &char) LumpIndex {
	mut i LumpIndex = w_check_num_for_name(name)

	if i < 0 {
		i_error(c"W_GetNumForName: %s not found!", name)
	}

	return i
}

// W_LumpLength
// Returns the buffer size needed to load the given lump.
fn w_lump_length(lump LumpIndex) int {
	if lump >= LumpIndex(numlumps) {
		i_error(c"W_LumpLength: %i >= numlumps", lump)
	}

	return lumpinfo[lump].size
}

// W_ReadLump
// Loads the lump into the given buffer, which must be >= W_LumpLength().
fn w_read_lump(lump LumpIndex, dest voidptr) {
	mut c int
	mut l &LumpInfo

	if lump >= LumpIndex(numlumps) {
		i_error(c"W_ReadLump: %i >= numlumps", lump)
	}

	l = lumpinfo[lump]

	v_begin_read(l.size)

	c = w_read(l.wad_file, l.position, dest, l.size)

	if c < l.size {
		i_error(c"W_ReadLump: only read %i of %i on lump %i", c, l.size, lump)
	}
}

// W_CacheLumpNum
// Load a lump into memory and return a pointer to a buffer containing
// the lump data.
fn w_cache_lump_num(lumpnum LumpIndex, tag int) voidptr {
	mut result &u8
	mut lump &LumpInfo

	if u32(lumpnum) >= numlumps {
		i_error(c"W_CacheLumpNum: %i >= numlumps", lumpnum)
	}

	lump = lumpinfo[lumpnum]

	// Get the pointer to return. If the lump is in a memory-mapped
	// file, we can just return a pointer to within the memory-mapped
	// region. If the lump is in an ordinary file, we may already
	// have it cached; otherwise, load it into memory.

	if lump.wad_file.mapped != unsafe { nil } {
		// Memory mapped file, return from the mmapped region.
		result = unsafe { &lump.wad_file.mapped[lump.position] }
	} else if lump.cache != unsafe { nil } {
		// Already cached, so just switch the zone tag.
		result = unsafe { &u8(lump.cache) }
		z_change_tag(lump.cache, tag)
	} else {
		// Not yet loaded, so load it now
		lump.cache = z_malloc(w_lump_length(lumpnum), tag, unsafe { &lump.cache })
		w_read_lump(lumpnum, lump.cache)
		result = unsafe { &u8(lump.cache) }
	}

	return unsafe { result }
}

// W_CacheLumpName
fn w_cache_lump_name(name &char, tag int) voidptr {
	return w_cache_lump_num(w_get_num_for_name(name), tag)
}

// Release a lump back to the cache
fn w_release_lump_num(lumpnum LumpIndex) {
	mut lump &LumpInfo

	if u32(lumpnum) >= numlumps {
		i_error(c"W_ReleaseLumpNum: %i >= numlumps", lumpnum)
	}

	lump = lumpinfo[lumpnum]

	if lump.wad_file.mapped != unsafe { nil } {
		// Memory-mapped file, so nothing needs to be done here.
	} else {
		z_change_tag(lump.cache, pu_cache)
	}
}

// W_ReleaseLumpName
fn w_release_lump_name(name &char) {
	w_release_lump_num(w_get_num_for_name(name))
}

// W_GenerateHashTable
fn w_generate_hash_table() {
	mut i LumpIndex

	// Free the old hash table, if there is one:
	if lumphash.len > 0 {
		z_free(unsafe { lumphash.data })
	}

	// Generate hash table
	if numlumps > 0 {
		lumphash = []LumpIndex{len: int(numlumps), cap: int(numlumps)}

		for i = 0; i < LumpIndex(numlumps); i++ {
			lumphash[i] = -1
		}

		for i = 0; i < LumpIndex(numlumps); i++ {
			mut hash u32 = w_lump_name_hash(unsafe { &lumpinfo[i].name[0] }) % u32(numlumps)

			// Hook into the hash table
			lumpinfo[i].next = lumphash[hash]
			lumphash[hash] = i
		}
	}
}

// W_Reload
// The Doom reload hack. The idea here is that if you give a WAD file to -file
// prefixed with the ~ hack, that WAD file will be reloaded each time a new
// level is loaded. This lets you use a level editor in parallel and make
// incremental changes to the level you're working on without having to restart
// the game after every change.
fn w_reload() {
	mut filename &char
	mut i LumpIndex

	if reloadname == unsafe { nil } {
		return
	}

	// We must free any lumps being cached from the PWAD we're about to reload:
	for i = LumpIndex(reloadlump); i < LumpIndex(numlumps); i++ {
		if lumpinfo[i].cache != unsafe { nil } {
			z_free(lumpinfo[i].cache)
		}
	}

	// Reset numlumps to remove the reload WAD file:
	numlumps = u32(reloadlump)

	// Now reload the WAD file.
	filename = reloadname

	w_close_file(reloadhandle)
	C.free(unsafe { reloadlumps })

	reloadname = unsafe { nil }
	reloadlump = -1
	reloadhandle = unsafe { nil }
	w_add_file(filename)
	C.free(unsafe { filename })

	// The WAD directory has changed, so we have to regenerate the fast lookup hashtable:
	w_generate_hash_table()
}

// W_WadNameForLump
fn w_wad_name_for_lump(lump &LumpInfo) &char {
	return m_base_name(lump.wad_file.path)
}

// W_IsIWADLump
fn w_is_iwad_lump(lump &LumpInfo) bool {
	return lump.wad_file == lumpinfo[0].wad_file
}

// Forward declarations for external functions
fn w_open_file(filename &char) &WadFile
fn w_close_file(wad &WadFile)
fn w_read(wad &WadFile, offset int, dest voidptr, count int) int

fn i_error(msg &char, ...any)
fn i_realloc(ptr voidptr, size int) voidptr

fn z_malloc(size int, tag int, user voidptr) voidptr
fn z_free(ptr voidptr)
fn z_change_tag(ptr voidptr, tag int)

fn m_extract_file_base(path &char, dest &u8)
fn m_base_name(path &char) &char

fn v_begin_read(size int)

const pu_static = 1
const pu_cache = 20
