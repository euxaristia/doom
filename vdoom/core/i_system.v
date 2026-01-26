@[has_globals]
module core

import os

#include <stdlib.h>

const default_ram_mb = 16
const min_ram_mb = 4
const package_name = 'DOOM.v'
const dos_mem_dump_size = 10
const mem_dump_dos622 = [u8(0x57), 0x92, 0x19, 0x00, 0xF4, 0x06, 0x70, 0x00, 0x16, 0x00]
const mem_dump_win98 = [u8(0x9E), 0x0F, 0xC9, 0x00, 0x65, 0x04, 0x70, 0x00, 0x16, 0x00]
const mem_dump_dosbox = [u8(0x00), 0x00, 0x00, 0xF1, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00]

pub type ExitFunc = fn ()

struct ExitEntry {
	func         ExitFunc = unsafe { nil }
	run_on_error bool
}

__global exit_funcs = []ExitEntry{}
__global already_quitting = false
__global mem_dump_initialized = false
__global mem_dump = []u8{}

pub fn i_init() {
}

pub struct ZoneMemory {
pub:
	data []u8
	size int
}

pub fn i_zone_base() ZoneMemory {
	mut default_ram := default_ram_mb
	mut min_ram := min_ram_mb
	env_mb := os.getenv('VDoomZoneMB')
	if env_mb.len > 0 {
		default_ram = env_mb.int()
		min_ram = default_ram
	} else if mb := arg_value('-mb') {
		default_ram = mb.int()
		min_ram = default_ram
	}
	if default_ram < min_ram {
		i_error('Unable to allocate ${default_ram} MiB of RAM for zone')
		return ZoneMemory{}
	}
	size := default_ram * 1024 * 1024
	zonemem := []u8{len: size}
	println('zone memory: ${zonemem.data} ${size:x} allocated for zone')
	return ZoneMemory{
		data: zonemem
		size: size
	}
}

pub fn i_console_stdout() bool {
	return os.is_atty(1) > 0
}

pub fn i_base_ticcmd() voidptr {
	return unsafe { nil }
}

pub fn i_quit() {
	for entry in exit_funcs {
		entry.func()
	}
	exit(0)
}

pub fn i_error(msg string) {
	if already_quitting {
		eprintln('Warning: recursive call to i_error detected.')
		exit(-1)
	}
	already_quitting = true

	eprintln(msg)

	for entry in exit_funcs {
		if entry.run_on_error {
			entry.func()
		}
	}

	exit(-1)
}

pub fn i_tactile(on int, off int, total int) {
	_ = on
	_ = off
	_ = total
}

pub fn i_realloc(ptr voidptr, size usize) voidptr {
	unsafe {
		new_ptr := C.realloc(ptr, size)
		if size != 0 && new_ptr == 0 {
			i_error('i_realloc: failed on reallocation of ${size} bytes')
		}
		return new_ptr
	}
}

pub fn i_get_memory_value(offset u32, value voidptr, size int) bool {
	init_mem_dump()
	if offset + u32(size) > u32(mem_dump.len) {
		return false
	}
	unsafe {
		base := int(offset)
		match size {
			1 { *(&u8(value)) = mem_dump[base] }
			2 {
				*(&u16(value)) = u16(mem_dump[base]) |
					(u16(mem_dump[base + 1]) << 8)
			}
			4 {
				*(&u32(value)) = u32(mem_dump[base]) |
					(u32(mem_dump[base + 1]) << 8) |
					(u32(mem_dump[base + 2]) << 16) |
					(u32(mem_dump[base + 3]) << 24)
			}
			else { return false }
		}
	}
	return true
}

pub fn i_at_exit(func ExitFunc, run_on_error bool) {
	exit_funcs << ExitEntry{
		func: func
		run_on_error: run_on_error
	}
}

pub fn i_bind_variables() {
}

pub fn i_print_startup_banner(game_description string) {
	i_print_divider()
	i_print_banner(game_description)
	i_print_divider()
	println(' ${package_name} is free software, covered by the GNU General Public')
	println(' License. There is NO warranty; not even for MERCHANTABILITY or FITNESS')
	println(' FOR A PARTICULAR PURPOSE. You are welcome to change and distribute')
	println(' copies under certain conditions. See the source for more information.')
	i_print_divider()
}

pub fn i_print_banner(text string) {
	spaces := 35 - (text.len / 2)
	if spaces > 0 {
		println('${' '.repeat(spaces)}${text}')
	} else {
		println(text)
	}
}

pub fn i_print_divider() {
	println('='.repeat(75))
}

fn init_mem_dump() {
	if mem_dump_initialized {
		return
	}
	mem_dump_initialized = true
	mem_dump = mem_dump_win98.clone()
	if arg := arg_value('-setmem') {
		match arg {
			'dos622' { mem_dump = mem_dump_dos622.clone() }
			'dos71' { mem_dump = mem_dump_win98.clone() }
			'dosbox' { mem_dump = mem_dump_dosbox.clone() }
			else {
				mut custom := []u8{len: dos_mem_dump_size}
				custom[0] = u8(arg.int())
				mut idx := 1
				mut i := 0
				for i = 0; i < os.args.len; i++ {
					if os.args[i] == '-setmem' {
						i++
						for i < os.args.len && idx < custom.len {
							if os.args[i].starts_with('-') {
								break
							}
							custom[idx] = u8(os.args[i].int())
							idx++
							i++
						}
						break
					}
				}
				mem_dump = custom.clone()
			}
		}
	}
}

fn arg_value(flag string) ?string {
	for i in 0 .. os.args.len {
		if os.args[i] == flag && i + 1 < os.args.len {
			return os.args[i + 1]
		}
	}
	return none
}
