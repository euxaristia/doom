@[translated]
module main

// Video system hooks: minimal framebuffer implementation.

const default_screen_w = 320
const default_screen_h = 200

fn C.memcpy(voidptr, voidptr, usize) voidptr

__global (
	mut grab_mouse_cb voidptr
	mut video_inited bool
)

fn ensure_video_buffer() {
	if video_inited && I_VideoBuffer != unsafe { nil } {
		return
	}
	buf_len := default_screen_w * default_screen_h
	I_VideoBuffer = &Pixel_t(z_malloc(buf_len, pu_static, unsafe { nil }))
	video_inited = true
}

@[export: 'I_InitGraphics']
pub fn i_init_graphics() {
	ensure_video_buffer()
}

@[export: 'I_GraphicsCheckCommandLine']
pub fn i_graphics_check_command_line() {
	// No-op placeholder.
}

@[export: 'I_SetPalette']
pub fn i_set_palette(_palette &u8) {
	_ = _palette
	ensure_video_buffer()
}

@[export: 'I_UpdateNoBlit']
pub fn i_update_no_blit() {
	ensure_video_buffer()
}

@[export: 'I_FinishUpdate']
pub fn i_finish_update() {
	ensure_video_buffer()
}

@[export: 'I_SetWindowTitle']
pub fn i_set_window_title(title &i8) {
	_ = title
}

@[export: 'I_CheckIsScreensaver']
pub fn i_check_is_screensaver() {
	// No-op placeholder.
}

@[export: 'I_SetGrabMouseCallback']
pub fn i_set_grab_mouse_callback(cb voidptr) {
	grab_mouse_cb = cb
}

@[export: 'I_DisplayFPSDots']
pub fn i_display_fps_dots(_dots_on bool) {
	_ = _dots_on
}

@[export: 'I_BindVideoVariables']
pub fn i_bind_video_variables() {
	// No-op placeholder.
}

@[export: 'I_StartFrame']
pub fn i_start_frame() {
	ensure_video_buffer()
}

@[export: 'I_ReadScreen']
pub fn i_read_screen(dest &u8) {
	ensure_video_buffer()
	if dest == unsafe { nil } || I_VideoBuffer == unsafe { nil } {
		return
	}
	unsafe {
		C.memcpy(dest, I_VideoBuffer, usize(default_screen_w * default_screen_h))
	}
}
