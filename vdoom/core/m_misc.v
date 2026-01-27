module core

import os
import strconv

pub fn m_write_file(name string, source []u8) bool {
	os.write_file_array(name, source) or { return false }
	return true
}

pub fn m_read_file(name string) ![]u8 {
	return os.read_bytes(name)
}

pub fn m_make_directory(dir string) {
	os.mkdir_all(dir) or {}
}

pub fn m_temp_file(s string) string {
	return os.join_path(os.temp_dir(), s)
}

pub fn m_file_exists(file string) bool {
	return os.exists(file)
}

pub fn m_file_case_exists(path string) ?string {
	if os.exists(path) {
		return path
	}
	dir := os.dir(path)
	base := os.file_name(path)
	if dir.len == 0 || base.len == 0 {
		return none
	}
	files := os.ls(dir) or { return none }
	for f in files {
		if f.to_lower() == base.to_lower() {
			return os.join_path(dir, f)
		}
	}
	return none
}

pub fn m_file_length(mut handle os.File) i64 {
	pos := handle.tell() or { return 0 }
	handle.seek(0, .end) or { return 0 }
	length := handle.tell() or { return 0 }
	handle.seek(pos, .start) or { return 0 }
	return length
}

pub fn m_str_to_int(str string) ?int {
	s := str.trim_space()
	if s.len == 0 {
		return none
	}
	if s.starts_with('0x') || s.starts_with('0X') {
		return int(strconv.parse_int(s[2..], 16, 32) or { return none })
	}
	if s.starts_with('0') && s.len > 1 {
		return int(strconv.parse_int(s[1..], 8, 32) or { return none })
	}
	return strconv.atoi(s) or { return none }
}

pub fn m_dir_name(path string) string {
	if path.len == 0 {
		return '.'
	}
	return os.dir(path)
}

pub fn m_base_name(path string) string {
	return os.file_name(path)
}

pub fn m_extract_file_base(path string) string {
	base := os.file_name(path)
	mut name := base
	if dot := base.last_index('.') {
		name = base[..dot]
	}
	mut upper := name.to_upper()
	if upper.len > 8 {
		upper = upper[..8]
	}
	return upper
}

pub fn m_force_uppercase(text string) string {
	return text.to_upper()
}

pub fn m_force_lowercase(text string) string {
	return text.to_lower()
}

pub fn m_str_case_str(haystack string, needle string) ?int {
	h := haystack.to_lower()
	n := needle.to_lower()
	return h.index(n)
}

pub fn m_string_duplicate(orig string) string {
	return orig.clone()
}

pub fn m_string_copy(dest string, src string, dest_size int) (string, bool) {
	if dest_size <= 0 {
		return '', false
	}
	mut out := src
	if out.len >= dest_size {
		out = out[..dest_size - 1]
		return out, false
	}
	return out, true
}

pub fn m_string_concat(dest string, src string, dest_size int) (string, bool) {
	if dest_size <= 0 {
		return '', false
	}
	mut out := dest + src
	if out.len >= dest_size {
		out = out[..dest_size - 1]
		return out, false
	}
	return out, true
}

pub fn m_string_replace(haystack string, needle string, replacement string) string {
	return haystack.replace(needle, replacement)
}

pub fn m_string_join(s string, parts []string) string {
	mut out := s
	for part in parts {
		out += part
	}
	return out
}

pub fn m_string_starts_with(s string, prefix string) bool {
	return s.starts_with(prefix)
}

pub fn m_string_ends_with(s string, suffix string) bool {
	return s.ends_with(suffix)
}

pub fn m_vsnprintf(buf_len int, s string) (string, int) {
	if buf_len <= 0 {
		return '', 0
	}
	mut out := s
	if out.len >= buf_len {
		out = out[..buf_len - 1]
		return out, out.len
	}
	return out, out.len
}

pub fn m_snprintf(buf_len int, s string) (string, int) {
	return m_vsnprintf(buf_len, s)
}

pub fn m_oem_to_utf8(oem string) string {
	return oem
}
