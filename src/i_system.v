@[translated]
module main

fn C.I_Init()
fn C.I_Quit()
fn C.I_Error(&char, voidptr)
fn C.I_ZoneBase(&int) voidptr
fn C.I_Realloc(voidptr, int) voidptr
fn C.I_AtExit(voidptr, bool)
fn C.I_Tactile(int, int, int)

fn i_init() { C.I_Init() }
fn i_quit() { C.I_Quit() }
fn i_error(fmt &char, args voidptr) { C.I_Error(fmt, args) }
fn i_zone_base(size &int) voidptr { return C.I_ZoneBase(size) }
fn i_realloc(ptr voidptr, size int) voidptr { return C.I_Realloc(ptr, size) }
fn i_at_exit(func voidptr, run_on_error bool) { C.I_AtExit(func, run_on_error) }
fn i_tactile(on int, off int, total int) { C.I_Tactile(on, off, total) }
