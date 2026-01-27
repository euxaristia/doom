@[has_globals]
module core

__global deh_loaded_files = []string{}

pub fn deh_load_file(path string) bool {
	if path.len == 0 {
		return false
	}
	deh_loaded_files << path
	return true
}

