@[has_globals]
module core

__global deh_initialized = false
__global deh_file_loaded = false
__global deh_allow_extended_strings = false
__global deh_allow_long_strings = false
__global deh_allow_long_cheats = true
__global deh_apply_cheats = true
__global deh_init_count = 0

pub fn deh_init_system() {
	if deh_initialized {
		return
	}
	deh_init()
	deh_clear_strings()
	deh_mapping_clear()
	deh_reset_io()
	deh_initialized = true
	deh_file_loaded = false
	deh_init_count++
}

pub fn deh_add_substitution(from string, to string) {
	deh_init_system()
	deh_add_string(from, to)
}

pub fn deh_load(path string) bool {
	deh_init_system()
	ok := deh_load_file(path)
	deh_file_loaded = deh_file_loaded || ok
	return ok
}
