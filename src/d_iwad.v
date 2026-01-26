@[translated]
module main

fn C.D_IsIWADName(&char) bool
fn C.D_FindIWAD(&char) &char
fn C.D_AddIWADSearchDir(&char)

fn d_is_iwad_name(name &char) bool { return C.D_IsIWADName(name) }
fn d_find_iwad(basedir &char) &char { return C.D_FindIWAD(basedir) }
fn d_add_iwad_search_dir(dir &char) { C.D_AddIWADSearchDir(dir) }
