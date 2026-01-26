@[translated]
module main

const pu_static = 1
const pu_sound = 2
const pu_music = 3
const pu_free = 4
const pu_level = 5
const pu_levspec = 6
const pu_purgelevel = 7
const pu_cache = 8

fn C.Z_Init()
fn C.Z_Malloc(int, int, voidptr) voidptr
fn C.Z_Free(voidptr)
fn C.Z_FreeTags(int, int)
fn C.Z_ChangeTag2(voidptr, int, &char, int)
fn C.Z_ChangeUser(voidptr, voidptr)
fn C.Z_CheckHeap()
fn C.Z_FreeMemory() int
fn C.Z_ZoneSize() u32

fn z_init() { C.Z_Init() }
fn z_malloc(size int, tag int, user voidptr) voidptr { return C.Z_Malloc(size, tag, user) }
fn z_free(ptr voidptr) { C.Z_Free(ptr) }
fn z_free_tags(lowtag int, hightag int) { C.Z_FreeTags(lowtag, hightag) }
fn z_change_tag(ptr voidptr, tag int) { C.Z_ChangeTag2(ptr, tag, c"", 0) }
fn z_change_user(ptr voidptr, user voidptr) { C.Z_ChangeUser(ptr, user) }
fn z_check_heap() { C.Z_CheckHeap() }
fn z_free_memory() int { return C.Z_FreeMemory() }
fn z_zone_size() u32 { return C.Z_ZoneSize() }
