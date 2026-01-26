@[translated]
module main

fn C.Z_Init()
fn C.Z_Malloc(int, int, voidptr) voidptr
fn C.Z_Free(voidptr)
fn C.Z_FreeTags(int, int)
fn C.Z_CheckHeap()
fn C.Z_DumpHeap(int, int)
fn C.Z_FreeMemory() int
fn C.Z_ZoneSize() u32

fn z_init() { C.Z_Init() }
fn z_malloc(size int, tag int, user voidptr) voidptr { return C.Z_Malloc(size, tag, user) }
fn z_free(ptr voidptr) { C.Z_Free(ptr) }
fn z_free_tags(lowtag int, hightag int) { C.Z_FreeTags(lowtag, hightag) }
fn z_check_heap() { C.Z_CheckHeap() }
fn z_dump_heap(lowtag int, hightag int) { C.Z_DumpHeap(lowtag, hightag) }
fn z_free_memory() int { return C.Z_FreeMemory() }
fn z_zone_size() u32 { return C.Z_ZoneSize() }
