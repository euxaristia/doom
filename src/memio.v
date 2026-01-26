@[translated]
module main

fn C.MemoryRead_Create(&u8, int) voidptr
fn C.MemoryRead_Read(voidptr, voidptr, int) int
fn C.MemoryRead_Seek(voidptr, int, int) int
fn C.MemoryRead_Tell(voidptr) int
fn C.MemoryRead_Close(voidptr)

fn mem_fopen_read(buf &u8, len int) voidptr { return C.MemoryRead_Create(buf, len) }
fn mem_fread(ptr voidptr, size int, nmemb int, stream voidptr) int {
	return C.MemoryRead_Read(stream, ptr, size * nmemb)
}
fn mem_fseek(stream voidptr, offset int, whence int) int { return C.MemoryRead_Seek(stream, offset, whence) }
fn mem_ftell(stream voidptr) int { return C.MemoryRead_Tell(stream) }
fn mem_fclose(stream voidptr) { C.MemoryRead_Close(stream) }
