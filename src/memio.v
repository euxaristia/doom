// Copyright(C) 1993-1996 Id Software, Inc.
// Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// DESCRIPTION:
// Emulates the IO functions in C stdio.h reading and writing to memory.

enum MemFileMode {
	read
	write
}

pub enum MemSeekMode {
	seek_set
	seek_cur
	seek_end
}

// In-memory file structure
pub struct MemFile {
pub mut:
	buf      []u8
	buflen   int
	alloced  int
	position int
	mode     MemFileMode
}

// Open a memory area for reading
pub fn mem_fopen_read(buf []u8) &MemFile {
	return &MemFile{
		buf: buf
		buflen: buf.len
		alloced: buf.len
		position: 0
		mode: .read
	}
}

// Read bytes from memory file
pub fn (mut stream MemFile) fread(size int, nmemb int) []u8 {
	if stream.mode != .read {
		eprintln('not a read stream')
		return []
	}

	mut items := nmemb
	bytes_needed := nmemb * size
	bytes_available := stream.buflen - stream.position

	if bytes_needed > bytes_available {
		items = bytes_available / size
	}

	if items <= 0 {
		return []
	}

	result := stream.buf[stream.position..stream.position + items * size].clone()
	stream.position += items * size

	return result
}

// Open a memory area for writing
pub fn mem_fopen_write() &MemFile {
	return &MemFile{
		buf: []u8{cap: 1024}
		buflen: 0
		alloced: 1024
		position: 0
		mode: .write
	}
}

// Write bytes to memory file
pub fn (mut stream MemFile) fwrite(data []u8) int {
	if stream.mode != .write {
		return -1
	}

	bytes := data.len

	// Expand buffer if needed
	mut alloced := stream.alloced
	for bytes > alloced - stream.position {
		alloced *= 2
	}

	if alloced > stream.alloced {
		mut newbuf := []u8{len: alloced}
		copy(newbuf, stream.buf[..stream.position])
		stream.buf = newbuf
		stream.alloced = alloced
	}

	// Copy data into buffer
	copy(stream.buf[stream.position..stream.position + bytes], data)
	stream.position += bytes

	if stream.position > stream.buflen {
		stream.buflen = stream.position
	}

	return 1
}

// Get internal buffer
pub fn (stream &MemFile) get_buf() []u8 {
	return stream.buf[..stream.buflen]
}

// Close memory file
pub fn (stream &MemFile) fclose() {
	// Nothing to do in V - memory is managed automatically
}

// Get current position
pub fn (stream &MemFile) ftell() int {
	return stream.position
}

// Seek to position
pub fn (mut stream MemFile) fseek(offset int, whence MemSeekMode) int {
	mut newpos := 0

	match whence {
		.seek_set { newpos = offset }
		.seek_cur { newpos = stream.position + offset }
		.seek_end { newpos = stream.buflen + offset }
	}

	if newpos >= 0 && newpos <= stream.buflen {
		stream.position = newpos
		return 0
	}

	eprintln('Error seeking to ${newpos}')
	return -1
}
