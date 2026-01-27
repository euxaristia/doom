@[translated]
module main

import strconv

// Parses Text substitution sections in dehacked files.

fn txt_max_string_length(len int) int {
	mut l := len + 1
	l += (4 - (l % 4)) % 4
	return l - 1
}

fn read_n_chars(context &Deh_context_t, n int) &i8 {
	buf := &u8(z_malloc(n + 1, pu_static, unsafe { nil }))
	unsafe {
		for i := 0; i < n; i++ {
			ch := deh_get_char(context)
			buf[i] = if ch < 0 { u8(0) } else { u8(ch) }
		}
		buf[n] = 0
	}
	return &i8(buf)
}

@[c: 'DEH_TextStart']
fn deh_text_start(context &Deh_context_t, line &i8) voidptr {
	parts := cstring(line).split_any(' \t').filter(it.len > 0)
	if parts.len < 3 || parts[0].to_lower() != 'text' {
		deh_warning(context, c'Parse error on section start')
		return unsafe { nil }
	}
	fromlen := strconv.atoi(parts[1]) or {
		deh_warning(context, c'Parse error on section start')
		return unsafe { nil }
	}
	tolen := strconv.atoi(parts[2]) or {
		deh_warning(context, c'Parse error on section start')
		return unsafe { nil }
	}
	if !deh_allow_long_strings && tolen > txt_max_string_length(fromlen) {
		deh_error(context, c'Replacement string is longer than the maximum possible in doom.exe')
		return unsafe { nil }
	}
	from_text := read_n_chars(context, fromlen)
	to_text := read_n_chars(context, tolen)
	deh_add_string_replacement(from_text, to_text)
	z_free(from_text)
	z_free(to_text)
	return unsafe { nil }
}

@[c: 'DEH_TextParseLine']
fn deh_text_parse_line(_context &Deh_context_t, _line &i8, _tag voidptr) {
	// Not used.
	_ = _context
	_ = _line
	_ = _tag
}

__global (
	deh_section_text = Deh_section_t{
		name: c'Text'
		init: unsafe { nil }
		start: deh_text_start
		line_parser: deh_text_parse_line
		end: unsafe { nil }
		sha1_hash: unsafe { nil }
	}
)
