@[translated]
module main

import os

// Default RAM amounts
const default_ram_mib = 16  // MiB
const min_ram_mib = 4       // MiB
const dos_mem_dump_size = 10

// Exit function callback type
type AtexitFunc = fn()

struct atexit_listentry_t {
	func AtexitFunc
	run_on_error bool
	next &atexit_listentry_t
}

// Global exit function list
mut exit_funcs &atexit_listentry_t = unsafe { nil }

// Static variables for DOS memory emulation
const mem_dump_dos622 = [u8(0x57), 0x92, 0x19, 0x00, 0xF4, 0x06, 0x70, 0x00, 0x16, 0x00]
const mem_dump_win98 = [u8(0x9E), 0x0F, 0xC9, 0x00, 0x65, 0x04, 0x70, 0x00, 0x16, 0x00]
const mem_dump_dosbox = [u8(0x00), 0x00, 0x00, 0xF1, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00]

mut mem_dump_custom [dos_mem_dump_size]u8
mut dos_mem_dump &u8 = unsafe { &mem_dump_dos622[0] }
mut mem_dump_firsttime = true

// Forward declarations for external dependencies
fn m_check_parm_with_args(check &char, num_args int) int
fn m_parm_exists(check &char) bool
fn m_v_snprintf(buf &char, buf_len usize, format &char, ap &C.va_list) int
fn m_str_to_int(str &char, value &int) bool

// I_Tactile - Tactile feedback function (stub for Logitech Cyberman)
fn i_tactile(on int, off int, total int) {
	// stub - no implementation needed
}

// auto_alloc_memory - Auto-allocate zone memory with fallback sizes
fn auto_alloc_memory(size &int, default_ram int, min_ram int) &u8 {
	mut zonemem := unsafe { nil as &u8 }
	mut ram_size := default_ram

	for zonemem == unsafe { nil } {
		// We need a reasonable minimum amount of RAM to start
		if ram_size < min_ram {
			i_error(c'Unable to allocate %i MiB of RAM for zone', ram_size)
		}

		// Try to allocate the zone memory
		size_bytes := ram_size * 1024 * 1024
		unsafe {
			zonemem = C.malloc(size_bytes) as &u8
		}

		// Failed to allocate? Reduce zone size until we reach a size that is acceptable
		if zonemem == unsafe { nil } {
			ram_size -= 1
		} else {
			unsafe {
				*size = size_bytes
			}
		}
	}

	return zonemem
}

// I_ZoneBase - Get the zone memory base and size
fn i_zone_base(size &int) &u8 {
	mut zonemem := unsafe { nil as &u8 }
	mut min_ram := min_ram_mib
	mut default_ram := default_ram_mib

	// Check for -mb command line parameter to specify heap size
	p := m_check_parm_with_args(c'-mb', 1)

	if p > 0 {
		// Get heap size from command line
		// Note: myargv would be defined elsewhere
		default_ram = 16 // Placeholder - would need myargv access
		min_ram = default_ram
	}

	zonemem = auto_alloc_memory(size, default_ram, min_ram)

	C.printf(c'zone memory: %p, %x allocated for zone\n', zonemem, unsafe { *size })

	return zonemem
}

// I_PrintBanner - Print a centered banner message
fn i_print_banner(msg &char) {
	msg_len := C.strlen(msg)
	spaces := 35 - (msg_len / 2)

	for _ in 0 .. spaces {
		C.putchar(` `)
	}

	C.puts(msg)
}

// I_PrintDivider - Print a dividing line for startup banners
fn i_print_divider() {
	for _ in 0 .. 75 {
		C.putchar(`=`)
	}
	C.putchar(`\n`)
}

// I_PrintStartupBanner - Print startup banner with copyright and license info
fn i_print_startup_banner(gamedescription &char) {
	i_print_divider()
	i_print_banner(gamedescription)
	i_print_divider()

	C.printf(c' %s is free software, covered by the GNU General Public\n', c'DOOM')
	C.printf(c' License.  There is NO warranty; not even for MERCHANTABILITY or FITNESS\n')
	C.printf(c' FOR A PARTICULAR PURPOSE. You are welcome to change and distribute\n')
	C.printf(c' copies under certain conditions. See the source for more information.\n')

	i_print_divider()
}

// I_ConsoleStdout - Check if stdout is a real console
fn i_console_stdout() bool {
	$if windows {
		// SDL "helpfully" always redirects stdout to a file on Windows
		return false
	} $else {
		// On Unix-like systems, check if stdout is a TTY
		fd := C.fileno(C.stdout)
		return C.isatty(fd) != 0
	}
}

// I_AtExit - Schedule a function to be called when the program exits
fn i_at_exit(func AtexitFunc, run_on_error bool) {
	entry := unsafe { C.malloc(sizeof(atexit_listentry_t)) as &atexit_listentry_t }

	entry.func = func
	entry.run_on_error = run_on_error
	entry.next = exit_funcs
	exit_funcs = entry
}

// I_Quit - Exit the program, running exit functions
fn i_quit() {
	mut entry := exit_funcs

	// Run through all exit functions
	for entry != unsafe { nil } {
		entry.func()
		entry = entry.next
	}

	C.SDL_Quit()
	C.exit(0)
}

// I_Error - Fatal error handler with cleanup
mut already_quitting = false

fn i_error(error &char, args ...voidptr) {
	mut msgbuf := [512]u8{}
	mut entry := atexit_listentry_t{}

	if already_quitting {
		C.fprintf(C.stderr, c'Warning: recursive call to I_Error detected.\n')
		C.exit(-1)
	}

	already_quitting = true

	// Print error to stderr
	mut ap := C.va_list{}
	C.va_start(ap, error)
	C.vfprintf(C.stderr, error, ap)
	C.fprintf(C.stderr, c'\n\n')
	C.va_end(ap)
	C.fflush(C.stderr)

	// Write a copy of the message into buffer
	C.va_start(ap, error)
	C.memset(unsafe { &msgbuf[0] }, 0, sizeof(msgbuf))
	m_v_snprintf(unsafe { &msgbuf[0] as &char }, sizeof(msgbuf), error, &ap)
	C.va_end(ap)

	// Run error-specific exit functions
	entry = unsafe { *exit_funcs }
	for entry.next != unsafe { nil } {
		if entry.run_on_error {
			entry.func()
		}
		entry = unsafe { *entry.next }
	}

	// Show GUI error dialog if not in console
	if !i_console_stdout() {
		C.SDL_ShowSimpleMessageBox(C.SDL_MESSAGEBOX_ERROR,
			c'DOOM Error', unsafe { &msgbuf[0] as &char }, unsafe { nil })
	}

	C.SDL_Quit()
	C.exit(-1)
}

// I_Realloc - Reallocate memory, error on failure
fn i_realloc(ptr voidptr, size usize) voidptr {
	new_ptr := unsafe { C.realloc(ptr, size) }

	if size != 0 && new_ptr == unsafe { nil } {
		i_error(c'I_Realloc: failed on reallocation of %zu bytes', size)
	}

	return new_ptr
}

// I_GetMemoryValue - Get memory value for DOS compatibility mode
fn i_get_memory_value(offset u32, value voidptr, size int) bool {
	if mem_dump_firsttime {
		mem_dump_firsttime = false

		// Check for -setmem command line parameter
		p := m_check_parm_with_args(c'-setmem', 1)

		if p > 0 {
			// Would set dos_mem_dump based on parameter
			// This is a simplified version - full implementation would access myargv
			dos_mem_dump = unsafe { &mem_dump_dos622[0] }
		}
	}

	match size {
		1 {
			unsafe {
				*(value as &u8) = unsafe { *(dos_mem_dump + int(offset)) }
			}
			return true
		}
		2 {
			unsafe {
				*(value as &u16) = unsafe {
					u16(*(dos_mem_dump + int(offset))) |
					(u16(*(dos_mem_dump + int(offset) + 1)) << 8)
				}
			}
			return true
		}
		4 {
			unsafe {
				*(value as &u32) = unsafe {
					u32(*(dos_mem_dump + int(offset))) |
					(u32(*(dos_mem_dump + int(offset) + 1)) << 8) |
					(u32(*(dos_mem_dump + int(offset) + 2)) << 16) |
					(u32(*(dos_mem_dump + int(offset) + 3)) << 24)
				}
			}
			return true
		}
		else {
			return false
		}
	}
}

// I_Init - Initialize system-specific code (stub)
fn i_init() {
	// Placeholder - would initialize various subsystems
	// I_CheckIsScreensaver()
	// I_InitTimer()
	// I_InitJoystick()
}

// I_BindVariables - Bind system-specific config variables (stub)
fn i_bind_variables() {
	// Placeholder - would bind various configuration variables
	// I_BindVideoVariables()
	// I_BindJoystickVariables()
	// I_BindSoundVariables()
}
