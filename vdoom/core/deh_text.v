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

