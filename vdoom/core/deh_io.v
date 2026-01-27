@[has_globals]
module core

__global deh_loaded_files = []string{}
__global deh_last_error = ''
__global deh_input_buffer = ''
__global deh_input_pos = 0
__global deh_last_loaded = ''

pub fn deh_reset_io() {
	deh_loaded_files = []string{}
	deh_last_error = ''
	deh_input_buffer = ''
	deh_input_pos = 0
	deh_last_loaded = ''
}

pub fn deh_load_file(path string) bool {
	if path.len == 0 {
		deh_last_error = 'empty path'
		return false
	}
	deh_loaded_files << path
	deh_last_loaded = path
	deh_last_error = ''
	return true
}

pub fn deh_load_lump(name string) bool {
	if name.len == 0 {
		deh_last_error = 'empty lump'
		return false
	}
	entry := 'lump:${name}'
	deh_loaded_files << entry
	deh_last_loaded = entry
	deh_last_error = ''
	return true
}

pub fn deh_set_input_buffer(data string) {
	deh_input_buffer = data
	deh_input_pos = 0
}

pub fn deh_input_remaining() int {
	if deh_input_pos >= deh_input_buffer.len {
		return 0
	}
	return deh_input_buffer.len - deh_input_pos
}

pub fn deh_get_char() u8 {
	if deh_input_pos >= deh_input_buffer.len {
		return u8(0)
	}
	ch := deh_input_buffer[deh_input_pos]
	deh_input_pos++
	return ch
}
