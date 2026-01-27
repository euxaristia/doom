@[translated]
module main

// Dehacked I/O code: reads from files or lumps.

fn C.fopen(&i8, &i8) &C.FILE
fn C.fclose(&C.FILE) int
fn C.fgetc(&C.FILE) int
fn C.memcpy(voidptr, voidptr, usize) voidptr

@[c: 'W_LumpLength']
fn w_lump_length(lump int) int

fn deh_new_context() &Deh_context_t {
	ctx := &Deh_context_t(z_malloc(int(sizeof(Deh_context_t)), pu_static, unsafe { nil }))
	ctx.readbuffer_size = 128
	ctx.readbuffer = &i8(z_malloc(ctx.readbuffer_size, pu_static, unsafe { nil }))
	ctx.linenum = 0
	ctx.last_was_newline = true
	ctx.had_error = false
	ctx.input_buffer_pos = 0
	ctx.input_buffer_len = 0
	ctx.stream = unsafe { nil }
	ctx.filename = unsafe { nil }
	return ctx
}

@[export: 'DEH_OpenFile']
pub fn deh_open_file(filename &i8) &Deh_context_t {
	if filename == unsafe { nil } {
		return unsafe { nil }
	}
	stream := C.fopen(filename, c'r')
	if stream == unsafe { nil } {
		return unsafe { nil }
	}
	ctx := deh_new_context()
	ctx.type_ = .deh_input_file
	ctx.stream = stream
	ctx.filename = filename
	return ctx
}

@[export: 'DEH_OpenLump']
pub fn deh_open_lump(lumpnum int) &Deh_context_t {
	lump := w_cache_lump_num(lumpnum, pu_static)
	if lump == unsafe { nil } {
		return unsafe { nil }
	}
	ctx := deh_new_context()
	ctx.type_ = .deh_input_lump
	ctx.lumpnum = lumpnum
	ctx.input_buffer = &u8(lump)
	ctx.input_buffer_len = usize(w_lump_length(lumpnum))
	ctx.input_buffer_pos = 0
	return ctx
}

@[export: 'DEH_CloseFile']
pub fn deh_close_file(context &Deh_context_t) {
	if context == unsafe { nil } {
		return
	}
	if context.type_ == .deh_input_file && context.stream != unsafe { nil } {
		C.fclose(context.stream)
	}
	if context.type_ == .deh_input_lump && context.lumpnum >= 0 {
		w_release_lump_num(context.lumpnum)
	}
	if context.readbuffer != unsafe { nil } {
		z_free(context.readbuffer)
	}
	z_free(context)
}

@[export: 'DEH_GetChar']
pub fn deh_get_char(context &Deh_context_t) int {
	if context == unsafe { nil } {
		return -1
	}
	if context.type_ == .deh_input_file {
		if context.stream == unsafe { nil } {
			return -1
		}
		return C.fgetc(context.stream)
	}
	// Lump-backed context.
	if context.input_buffer_pos >= u32(context.input_buffer_len) {
		return -1
	}
	unsafe {
		ch := int(context.input_buffer[context.input_buffer_pos])
		context.input_buffer_pos++
		return ch
	}
}

fn ensure_readbuffer(context &Deh_context_t, need int) {
	if need < context.readbuffer_size {
		return
	}
	mut new_size := context.readbuffer_size
	for new_size <= need {
		new_size *= 2
	}
	new_buf := &i8(z_malloc(new_size, pu_static, unsafe { nil }))
	unsafe {
		C.memcpy(new_buf, context.readbuffer, usize(context.readbuffer_size))
	}
	z_free(context.readbuffer)
	context.readbuffer = new_buf
	context.readbuffer_size = new_size
}

@[export: 'DEH_ReadLine']
pub fn deh_read_line(context &Deh_context_t, extended bool) &i8 {
	_ = extended
	if context == unsafe { nil } {
		return unsafe { nil }
	}
	mut i := 0
	mut saw_any := false
	for {
		ch := deh_get_char(context)
		if ch < 0 {
			break
		}
		saw_any = true
		if ch == `\r` {
			continue
		}
		if ch == `\n` {
			context.linenum++
			context.last_was_newline = true
			break
		}
		context.last_was_newline = false
		ensure_readbuffer(context, i + 2)
		unsafe {
			(&u8(context.readbuffer))[i] = u8(ch)
		}
		i++
	}
	if !saw_any && i == 0 {
		return unsafe { nil }
	}
	ensure_readbuffer(context, i + 1)
	unsafe {
		(&u8(context.readbuffer))[i] = 0
	}
	return context.readbuffer
}

@[export: 'DEH_Error']
pub fn deh_error(context &Deh_context_t, msg &i8) {
	if context != unsafe { nil } {
		context.had_error = true
		eprintln('DEH error (line ${context.linenum}): ${cstring(msg)}')
		return
	}
	eprintln('DEH error: ${cstring(msg)}')
}

@[export: 'DEH_Warning']
pub fn deh_warning(context &Deh_context_t, msg &i8) {
	if context != unsafe { nil } {
		eprintln('DEH warning (line ${context.linenum}): ${cstring(msg)}')
		return
	}
	eprintln('DEH warning: ${cstring(msg)}')
}

@[export: 'DEH_HadError']
pub fn deh_had_error(context &Deh_context_t) bool {
	if context == unsafe { nil } {
		return true
	}
	return context.had_error
}
