@[has_globals]
module core

__global deh_strings = map[string]string{}

pub fn deh_clear_strings() {
	deh_strings = map[string]string{}
}

pub fn deh_add_string(from string, to string) {
	deh_strings[from] = to
}

pub fn deh_string(s string) string {
	if s in deh_strings {
		return deh_strings[s]
	}
	return s
}

