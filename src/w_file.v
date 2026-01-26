@[translated]
module main

// WAD file handle structure - this is the abstract interface
struct wad_file_t {
	file_class &wad_file_class_t  // Class of this file
	mapped &u8                     // Pointer to mapped file (NULL if not mapped)
	length u32                     // Length of the file in bytes
	path &char                     // File's location on disk
}

// WAD file class - vtable for file operations
struct wad_file_class_t {
	open_file fn(&char) &wad_file_t
	close_file fn(&wad_file_t)
	read fn(&wad_file_t, u32, voidptr, usize) usize
}

// Standard C library WAD file implementation
struct stdc_wad_file_t {
	wad wad_file_t
	fstream &C.FILE
}

// Forward declarations
fn z_malloc(size int, tag int, user &&void) voidptr
fn z_free(ptr voidptr)
fn m_file_length(fstream &C.FILE) int
fn m_string_duplicate(str &char) &char

// Global WAD file class for standard C file I/O
fn w_stdc_open_file(path &char) &wad_file_t {
	fstream := C.fopen(path, c'rb')

	if fstream == unsafe { nil } {
		return unsafe { nil }
	}

	// Create a new stdc_wad_file_t to hold the file handle
	result := unsafe { z_malloc(sizeof(stdc_wad_file_t), pu_static, unsafe { nil }) as &stdc_wad_file_t }
	result.wad.file_class = unsafe { &stdc_wad_file_class }
	result.wad.mapped = unsafe { nil }
	result.wad.length = u32(m_file_length(fstream))
	result.wad.path = m_string_duplicate(path)
	result.fstream = fstream

	return &result.wad
}

fn w_stdc_close_file(wad &wad_file_t) {
	stdc_wad := unsafe { wad as &stdc_wad_file_t }

	C.fclose(stdc_wad.fstream)
	z_free(unsafe { stdc_wad })
}

fn w_stdc_read(wad &wad_file_t, offset u32, buffer voidptr, buffer_len usize) usize {
	stdc_wad := unsafe { wad as &stdc_wad_file_t }

	// Jump to the specified position in the file
	C.fseek(stdc_wad.fstream, int(offset), C.SEEK_SET)

	// Read into the buffer
	result := C.fread(buffer, 1, buffer_len, stdc_wad.fstream)

	return result
}

// Global WAD file class instance for standard C file I/O
stdc_wad_file_class = wad_file_class_t{
	open_file: w_stdc_open_file,
	close_file: w_stdc_close_file,
	read: w_stdc_read,
}

// W_OpenFile - Open a WAD file
fn w_open_file(path &char) &wad_file_t {
	// Use standard C file I/O implementation
	return w_stdc_open_file(path)
}

// W_CloseFile - Close a WAD file
fn w_close_file(wad &wad_file_t) {
	if wad == unsafe { nil } {
		return
	}

	wad.file_class.close_file(wad)
}

// W_Read - Read data from a WAD file
fn w_read(wad &wad_file_t, offset u32, buffer voidptr, buffer_len usize) usize {
	if wad == unsafe { nil } {
		return 0
	}

	return wad.file_class.read(wad, offset, buffer, buffer_len)
}
