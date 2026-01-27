@[has_globals]
module core

__global deh_strings = map[string]string{}
__global deh_string_replacements = 0

pub fn deh_clear_strings() {
	deh_strings = map[string]string{}
	deh_string_replacements = 0
}

pub fn deh_add_string(from string, to string) {
	deh_strings[from] = to
	deh_string_replacements++
}

pub fn deh_string(s string) string {
	if s in deh_strings {
		return deh_strings[s]
	}
	return s
}

pub fn deh_replace_string(from string, to string) bool {
	if from.len == 0 {
		return false
	}
	deh_add_string(from, to)
	return true
}
