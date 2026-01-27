@[has_globals]
module core

__global deh_loaded_files = []string{}
__global deh_last_error = ''

pub fn deh_reset_io() {
	deh_loaded_files = []string{}
	deh_last_error = ''
}

pub fn deh_load_file(path string) bool {
	if path.len == 0 {
		deh_last_error = 'empty path'
		return false
	}
	deh_loaded_files << path
	return true
}

pub fn deh_load_lump(name string) bool {
	if name.len == 0 {
		deh_last_error = 'empty lump'
		return false
	}
	deh_loaded_files << 'lump:${name}'
	return true
}
