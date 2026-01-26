module core

import os

pub struct WadFile {
pub:
	path   string
	stream bool
pub mut:
	file   os.File
	data   []u8
	length int
}

pub fn open_file(path string) !WadFile {
	data := os.read_bytes(path) or {
		return error('failed to read wad: $err')
	}
	return WadFile{
		path: path
		length: data.len
		data: data
		stream: false
	}
}

pub fn open_file_stream(path string) !WadFile {
	file := os.open_file(path, 'rb') or {
		return error('failed to open wad: $err')
	}
	length := int(os.file_size(path))
	return WadFile{
		path: path
		length: length
		stream: true
		file: file
	}
}

pub fn close_file(mut file WadFile) {
	if file.stream {
		file.file.close()
	}
	file.data = []u8{}
	file.length = 0
}

pub fn read(mut file WadFile, offset int, mut buffer []u8) int {
	if offset < 0 || offset >= file.length || buffer.len == 0 {
		return 0
	}
	mut max := file.length - offset
	if buffer.len < max {
		max = buffer.len
	}
	if file.stream {
		return file.file.read_bytes_into(u64(offset), mut buffer[..max]) or { 0 }
	}
	for i in 0 .. max {
		buffer[i] = file.data[offset + i]
	}
	return max
}

pub fn read_bytes(mut file WadFile, offset int, len int) ![]u8 {
	if offset < 0 || len < 0 || offset + len > file.length {
		return error('read out of bounds')
	}
	mut out := []u8{len: len}
	read_len := read(mut file, offset, mut out)
	if read_len != len {
		return error('short read')
	}
	return out
}
