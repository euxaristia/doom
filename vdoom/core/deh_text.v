module core

fn txt_max_string_length(len int) int {
	mut n := len + 1
	n += (4 - (n % 4)) % 4
	return n - 1
}

pub fn deh_text_replace(from string, to string) bool {
	if !deh_allow_long_strings && to.len > txt_max_string_length(from.len) {
		return false
	}
	return deh_replace_string(from, to)
}

// Minimal parser for "Text <fromlen> <tolen>" blocks.
pub fn deh_text_start(line string) bool {
	parts := line.split_any(' \t').filter(it.len > 0)
	if parts.len < 3 || parts[0].to_lower() != 'text' {
		return false
	}
	fromlen := parts[1].int()
	tolen := parts[2].int()
	from := deh_read_bytes(fromlen)
	to := deh_read_bytes(tolen)
	if from.len != fromlen || to.len != tolen {
		return false
	}
	return deh_text_replace(from, to)
}
