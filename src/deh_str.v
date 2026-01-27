@[translated]
module main

// Dehacked string substitution. Minimal manual implementation.

@[export: 'DEH_String']
pub fn deh_string(s &i8) &i8 {
	// No substitutions yet: return the original string.
	return s
}

@[export: 'DEH_AddStringReplacement']
pub fn deh_add_string_replacement(from_text &i8, to_text &i8) {
	_ = from_text
	_ = to_text
	// Placeholder: substitution table can be added later.
}

@[export: 'DEH_printf']
pub fn deh_printf(fmt &i8) {
	// Varargs are not modeled here; print the format string as-is.
	print(cstring(fmt))
}

@[export: 'DEH_fprintf']
pub fn deh_fprintf(_fstream &C.FILE, fmt &i8) {
	_ = _fstream
	print(cstring(fmt))
}

@[export: 'DEH_snprintf']
pub fn deh_snprintf(buffer &i8, len usize, fmt &i8) {
	if buffer == unsafe { nil } || len == 0 {
		return
	}
	unsafe {
		mut i := usize(0)
		for i + 1 < len {
			ch := (&u8(fmt))[i]
			(&u8(buffer))[i] = ch
			i++
			if ch == 0 {
				return
			}
		}
		(&u8(buffer))[len - 1] = 0
	}
}
