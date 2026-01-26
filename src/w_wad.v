@[translated]
module main

fn C.W_AddFile(&char)
fn C.W_CheckNumForName(&char) int
fn C.W_GetNumForName(&char) int
fn C.W_CacheLumpNum(int, int) voidptr
fn C.W_ReleaseLumpNum(int)
fn C.W_Init()

fn w_add_file(filename &char) { C.W_AddFile(filename) }
fn w_check_num_for_name(name &char) int { return C.W_CheckNumForName(name) }
fn w_get_num_for_name(name &char) int { return C.W_GetNumForName(name) }
fn w_cache_lump_num(lumpnum int, tag int) voidptr { return C.W_CacheLumpNum(lumpnum, tag) }
fn w_release_lump_num(lumpnum int) { C.W_ReleaseLumpNum(lumpnum) }
fn w_init() { C.W_Init() }
