@[translated]
module main

//
// Copyright(C) 1993-1996 Id Software, Inc.
// Copyright(C) 1993-2008 Raven Software
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
//      Miscellaneous utility functions
//

// Create a directory
fn m_make_directory(path &char) {
	$if windows {
		C.mkdir(path)
	} $else {
		C.mkdir(path, 0o755)
	}
}

// Check if a file exists
fn m_file_exists(filename &char) bool {
	mut fstream &C.FILE = C.fopen(filename, c"r")

	if fstream != unsafe { nil } {
		C.fclose(fstream)
		return true
	} else {
		// If we can't open because the file is a directory, the "file" exists at least!
		return C.errno == C.EISDIR
	}
}

// Check if a file exists by probing for common case variation of its filename.
// Returns a newly allocated string that the caller is responsible for freeing.
fn m_file_case_exists(path &char) &char {
	mut path_dup &char = m_string_duplicate(path)
	mut filename &char
	mut ext &char

	// 0: actual path
	if m_file_exists(path_dup) {
		return path_dup
	}

	filename = unsafe { C.strrchr(path_dup, dir_separator) }
	if filename != unsafe { nil } {
		filename = unsafe { filename + 1 }
	} else {
		filename = path_dup
	}

	// 1: lowercase filename, e.g. doom2.wad
	m_force_lowercase(filename)

	if m_file_exists(path_dup) {
		return path_dup
	}

	// 2: uppercase filename, e.g. DOOM2.WAD
	m_force_uppercase(filename)

	if m_file_exists(path_dup) {
		return path_dup
	}

	// 3. uppercase basename with lowercase extension, e.g. DOOM2.wad
	ext = unsafe { C.strrchr(path_dup, `.`) }
	if ext != unsafe { nil } && ext > filename {
		m_force_lowercase(unsafe { ext + 1 })

		if m_file_exists(path_dup) {
			return path_dup
		}
	}

	// 4. lowercase filename with uppercase first letter, e.g. Doom2.wad
	if C.strlen(filename) > 1 {
		m_force_lowercase(unsafe { filename + 1 })

		if m_file_exists(path_dup) {
			return path_dup
		}
	}

	// 5. no luck
	C.free(unsafe { path_dup })
	return unsafe { nil }
}

// Determine the length of an open file.
fn m_file_length(handle &C.FILE) i64 {
	mut savedpos i64 = C.ftell(handle)
	mut length i64

	// jump to the end and find the length
	C.fseek(handle, 0, C.SEEK_END)
	length = C.ftell(handle)

	// go back to the old location
	C.fseek(handle, savedpos, C.SEEK_SET)

	return length
}

// M_WriteFile
fn m_write_file(name &char, source &u8, length int) bool {
	mut handle &C.FILE
	mut count int

	handle = C.fopen(name, c"wb")

	if handle == unsafe { nil } {
		return false
	}

	count = C.fwrite(unsafe { source }, 1, length, handle)
	C.fclose(handle)

	if count < length {
		return false
	}

	return true
}

// M_ReadFile
fn m_read_file(name &char, buffer &&u8) int {
	mut handle &C.FILE
	mut count int
	mut length int
	mut buf &u8

	handle = C.fopen(name, c"rb")
	if handle == unsafe { nil } {
		i_error(c"Couldn't read file %s", name)
	}

	// find the size of the file by seeking to the end and reading the current position
	length = int(m_file_length(handle))

	buf = z_malloc(length + 1, pu_static, unsafe { nil })
	count = C.fread(buf, 1, length, handle)
	C.fclose(handle)

	if count < length {
		i_error(c"Couldn't read file %s", name)
	}

	unsafe {
		buf[length] = u8(0)
	}
	unsafe {
		*buffer = buf
	}
	return length
}

// Returns the path to a temporary file of the given name, stored
// inside the system temporary directory.
fn m_temp_file(s &char) &char {
	mut tempdir &char

	$if windows {
		// Check the TEMP environment variable to find the location.
		tempdir = C.getenv(c"TEMP")

		if tempdir == unsafe { nil } {
			tempdir = c"."
		}
	} $else {
		// In Unix, just use /tmp.
		tempdir = c"/tmp"
	}

	return m_string_join(tempdir, dir_separator_s, s, unsafe { nil })
}

// M_StrToInt
fn m_str_to_int(str &char, result &int) bool {
	mut val int
	mut res1 int = C.sscanf(str, c" 0x%x", &val)
	mut res2 int = C.sscanf(str, c" 0X%x", &val)
	mut res3 int = C.sscanf(str, c" 0%o", &val)
	mut res4 int = C.sscanf(str, c" %d", &val)

	if res1 == 1 || res2 == 1 || res3 == 1 || res4 == 1 {
		unsafe { *result = val }
		return true
	}
	return false
}

// Returns the directory portion of the given path, without the trailing
// slash separator character. If no directory is described in the path,
// the string "." is returned.
fn m_dir_name(path &char) &char {
	mut p &char = unsafe { C.strrchr(path, dir_separator) }
	mut result &char

	if p == unsafe { nil } {
		return m_string_duplicate(c".")
	} else {
		result = m_string_duplicate(path)
		unsafe {
			result[p - path] = 0
		}
		return result
	}
}

// Returns the base filename described by the given path (without the
// directory name). The result points inside path and nothing new is allocated.
fn m_base_name(path &char) &char {
	mut p &char = unsafe { C.strrchr(path, dir_separator) }

	if p == unsafe { nil } {
		return path
	} else {
		return unsafe { p + 1 }
	}
}

// M_ExtractFileBase
fn m_extract_file_base(path &char, dest &u8) {
	mut src &char = unsafe { path + C.strlen(path) - 1 }
	mut filename &char
	mut length int

	// back up until a \ or the start
	for src != unsafe { path } && unsafe { *(src - 1) } != dir_separator {
		src = unsafe { src - 1 }
	}

	filename = src

	// Copy up to eight characters
	length = 0
	C.memset(unsafe { dest }, 0, 8)

	for unsafe { *src } != 0 && unsafe { *src } != `.` {
		if length >= 8 {
			C.printf(c"Warning: Truncated '%s' lump name to '%.8s'.\n", filename, dest)
			break
		}

		unsafe {
			dest[length] = u8(C.toupper(int(*src)))
		}
		length++
		src = unsafe { src + 1 }
	}
}

// M_ForceUppercase
fn m_force_uppercase(text &char) {
	mut p &char = text

	for unsafe { *p } != 0 {
		unsafe {
			*p = u8(C.toupper(int(*p)))
		}
		p = unsafe { p + 1 }
	}
}

// M_ForceLowercase
fn m_force_lowercase(text &char) {
	mut p &char = text

	for unsafe { *p } != 0 {
		unsafe {
			*p = u8(C.tolower(int(*p)))
		}
		p = unsafe { p + 1 }
	}
}

// M_StrCaseStr
// Case-insensitive version of strstr()
fn m_str_case_str(haystack &char, needle &char) &char {
	mut haystack_len u32 = C.strlen(haystack)
	mut needle_len u32 = C.strlen(needle)
	mut len u32
	mut i u32

	if haystack_len < needle_len {
		return unsafe { nil }
	}

	len = haystack_len - needle_len

	for i = 0; i <= len; i++ {
		if C.strncasecmp(unsafe { haystack + i }, needle, needle_len) == 0 {
			return unsafe { haystack + i }
		}
	}

	return unsafe { nil }
}

// Safe version of strdup() that checks the string was successfully allocated.
fn m_string_duplicate(orig &char) &char {
	mut result &char = C.strdup(orig)

	if result == unsafe { nil } {
		i_error(c"Failed to duplicate string (length %zu)", C.strlen(orig))
	}

	return result
}

// Safe string copy function that works like OpenBSD's strlcpy().
// Returns true if the string was not truncated.
fn m_string_copy(dest &char, src &char, dest_size int) bool {
	mut len int

	if dest_size >= 1 {
		unsafe {
			dest[dest_size - 1] = 0
		}
		C.strncpy(dest, src, dest_size - 1)
	} else {
		return false
	}

	len = int(C.strlen(dest))
	return unsafe { src[len] } == 0
}

// Safe string concat function that works like OpenBSD's strlcat().
// Returns true if string not truncated.
fn m_string_concat(dest &char, src &char, dest_size int) bool {
	mut offset int = int(C.strlen(dest))

	if offset > dest_size {
		offset = dest_size
	}

	return m_string_copy(unsafe { dest + offset }, src, dest_size - offset)
}

// Returns true if 's' begins with the specified prefix.
fn m_string_starts_with(s &char, prefix &char) bool {
	mut s_len int = int(C.strlen(s))
	mut prefix_len int = int(C.strlen(prefix))
	return s_len >= prefix_len && C.strncmp(s, prefix, prefix_len) == 0
}

// Returns true if 's' ends with the specified suffix.
fn m_string_ends_with(s &char, suffix &char) bool {
	mut s_len int = int(C.strlen(s))
	mut suffix_len int = int(C.strlen(suffix))
	return s_len >= suffix_len && C.strcmp(unsafe { s + s_len - suffix_len }, suffix) == 0
}

// Return a newly-allocated string with all the strings given as arguments
// concatenated together.
fn m_string_join(s &char, ...rest any) &char {
	mut result &char
	mut result_len int = int(C.strlen(s)) + 1

	// Count total length needed
	for v in rest {
		if v == unsafe { nil } {
			break
		}
		result_len += int(C.strlen(v))
	}

	result = unsafe { C.malloc(u32(result_len)) }

	if result == unsafe { nil } {
		i_error(c"M_StringJoin: Failed to allocate new string.")
		return unsafe { nil }
	}

	m_string_copy(result, s, result_len)

	for v in rest {
		if v == unsafe { nil } {
			break
		}
		m_string_concat(result, v, result_len)
	}

	return result
}

// Safe, portable vsnprintf().
fn m_vsnprintf(buf &char, buf_len int, s &char, args C.va_list) int {
	mut result int

	if buf_len < 1 {
		return 0
	}

	// Windows (and other OSes?) has a vsnprintf() that doesn't always append a trailing \0.
	result = C.vsnprintf(buf, buf_len, s, args)

	// If truncated, change the final char in the buffer to a \0.
	if result < 0 || result >= buf_len {
		unsafe {
			buf[buf_len - 1] = 0
		}
		result = buf_len - 1
	}

	return result
}

// Forward declarations for external functions
fn i_error(msg &char, ...any)
fn z_malloc(size int, tag int, user voidptr) voidptr

// Constants
const dir_separator = `/`
const dir_separator_s = c"/"
const pu_static = 1
