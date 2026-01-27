@[translated]
module main

import os

// System-specific file globbing interface: minimal manual implementation.

const glob_flag_nocase = 0x01
const glob_flag_sorted = 0x02

struct Glob_t {
	directory     string
	patterns      []string
	flags         int
	files         []string
	mut:
	idx           int
	last_filename &i8
}

fn glob_char_eq(a u8, b u8, nocase bool) bool {
	if !nocase {
		return a == b
	}
	return u8(a.ascii_str().to_lower()[0]) == u8(b.ascii_str().to_lower()[0])
}

fn glob_match(pattern string, name string, nocase bool) bool {
	// Simple wildcard matcher supporting '*' and '?'.
	mut pi := 0
	mut ni := 0
	mut star := -1
	mut match := 0
	for ni < name.len {
		if pi < pattern.len && (pattern[pi] == `?` || glob_char_eq(pattern[pi], name[ni], nocase)) {
			pi++
			ni++
			continue
		}
		if pi < pattern.len && pattern[pi] == `*` {
			star = pi
			match = ni
			pi++
			continue
		}
		if star != -1 {
			pi = star + 1
			match++
			ni = match
			continue
		}
		return false
	}
	for pi < pattern.len && pattern[pi] == `*` {
		pi++
	}
	return pi == pattern.len
}

fn glob_any_match(patterns []string, name string, nocase bool) bool {
	for pat in patterns {
		if glob_match(pat, name, nocase) {
			return true
		}
	}
	return false
}

fn to_cstring(s string) &i8 {
	buf := &u8(z_malloc(s.len + 1, pu_static, unsafe { nil }))
	unsafe {
		for i := 0; i < s.len; i++ {
			buf[i] = s[i]
		}
		buf[s.len] = 0
	}
	return &i8(buf)
}

fn collect_files(directory string, patterns []string, flags int) []string {
	nocase := (flags & glob_flag_nocase) != 0
	mut out := []string{}
	entries := os.ls(directory) or { return out }
	for name in entries {
		if glob_any_match(patterns, name, nocase) {
			out << os.join_path(directory, name)
		}
	}
	if (flags & glob_flag_sorted) != 0 {
		out.sort()
	}
	return out
}

@[export: 'I_StartMultiGlob']
pub fn i_start_multi_glob(directory &i8, flags int, glob &i8, _more ...&i8) &Glob_t {
	if directory == unsafe { nil } || glob == unsafe { nil } {
		return unsafe { nil }
	}
	mut patterns := []string{}
	patterns << cstring(glob)
	for p in _more {
		if p == unsafe { nil } {
			break
		}
		patterns << cstring(p)
	}
	dir := cstring(directory)
	mut g := &Glob_t{
		directory: dir
		patterns: patterns
		flags: flags
		files: collect_files(dir, patterns, flags)
		idx: 0
		last_filename: unsafe { nil }
	}
	return g
}

@[export: 'I_StartGlob']
pub fn i_start_glob(directory &i8, glob &i8, flags int) &Glob_t {
	return i_start_multi_glob(directory, flags, glob)
}

@[export: 'I_EndGlob']
pub fn i_end_glob(glob &Glob_t) {
	if glob == unsafe { nil } {
		return
	}
	if glob.last_filename != unsafe { nil } {
		z_free(glob.last_filename)
		glob.last_filename = unsafe { nil }
	}
}

@[export: 'I_NextGlob']
pub fn i_next_glob(glob &Glob_t) &i8 {
	if glob == unsafe { nil } {
		return unsafe { nil }
	}
	if glob.idx >= glob.files.len {
		return unsafe { nil }
	}
	if glob.last_filename != unsafe { nil } {
		z_free(glob.last_filename)
		glob.last_filename = unsafe { nil }
	}
	glob.last_filename = to_cstring(glob.files[glob.idx])
	glob.idx++
	return glob.last_filename
}
