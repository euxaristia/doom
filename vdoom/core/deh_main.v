@[has_globals]
module core

__global deh_initialized = false

pub fn deh_init_system() {
	if deh_initialized {
		return
	}
	deh_init()
	deh_clear_strings()
	deh_initialized = true
}

pub fn deh_add_substitution(from string, to string) {
	deh_init_system()
	deh_add_string(from, to)
}

