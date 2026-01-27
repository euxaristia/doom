@[translated]
module main

import os

// GUS emulation config: minimal manual implementation.

__global (
	mut gus_patch_path &i8 = c''
	mut gus_ram_kb int = 1024
)

@[export: 'GUS_WriteConfig']
pub fn gus_write_config(path &i8) bool {
	if gus_patch_path == unsafe { nil } || cstring(gus_patch_path).len == 0 {
		println('You have not configured gus_patch_path.')
		return false
	}
	if path == unsafe { nil } {
		return false
	}
	cfg := 'dir ${cstring(gus_patch_path)}\n\nbank 0\n\n# Instrument mappings omitted in this minimal port.\n\ndrumset 0\n\n'
	os.write_file(cstring(path), cfg) or {
		eprintln('GUS_WriteConfig: failed to write ${cstring(path)}: ${err}')
		return false
	}
	return true
}
