@[translated]
module main

import os
import time

// Main/system banner and exit handling helpers.

const package_string = 'Chocolate Doom 3.0.0'

fn C.fflush(voidptr) int

@[export: 'I_PrintStartupBanner']
pub fn i_print_startup_banner(gamedescription &i8) {
	mut desc := cstring(gamedescription)
	if desc.len == 0 {
		desc = package_string
	}
	i_print_divider()
	println(desc)
	i_print_divider()
}

@[export: 'I_PrintBanner']
pub fn i_print_banner(text &i8) {
	println(cstring(text))
}

@[export: 'I_PrintDivider']
pub fn i_print_divider() {
	println('------------------------------------------------------------')
}

@[export: 'I_ConsoleStdout']
pub fn i_console_stdout() {
	// Ensure stdout is flushed for banner/status output.
	C.fflush(voidptr(0))
}

@[export: 'I_GetMemoryValue']
pub fn i_get_memory_value(_key &i8) int {
	_ = _key
	// Minimal implementation: unknown keys return 0.
	return 0
}

@[export: 'I_Error']
pub fn i_error_export(fmt &i8, _args voidptr) {
	_ = _args
	eprintln('I_Error: ${cstring(fmt)}')
	// Match the engine's fatal-error behavior.
	time.sleep(10 * time.millisecond)
	os.exit(1)
}

@[export: 'I_AtExit']
pub fn i_at_exit_export(_func voidptr, _run_if_error bool) {
	_ = _func
	_ = _run_if_error
	// Placeholder: exit hooks are ignored in this minimal port.
}
