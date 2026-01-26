@[translated]
module main

fn C.W_OpenFile(&char, &char) voidptr
fn C.W_CloseFile(voidptr) int
fn C.W_FileLength(voidptr) int
fn C.W_FileRead(voidptr, voidptr, int) int
fn C.W_FileSeek(voidptr, int, int) int

fn w_open_file(filename &char, mode &char) voidptr { return C.W_OpenFile(filename, mode) }
fn w_close_file(handle voidptr) int { return C.W_CloseFile(handle) }
fn w_file_length(handle voidptr) int { return C.W_FileLength(handle) }
fn w_file_read(handle voidptr, buf voidptr, count int) int { return C.W_FileRead(handle, buf, count) }
fn w_file_seek(handle voidptr, offset int, whence int) int { return C.W_FileSeek(handle, offset, whence) }
