@[translated]
module main

// Video system hooks: minimal framebuffer implementation.

const default_screen_w = 320
const default_screen_h = 200

fn C.memcpy(voidptr, voidptr, usize) voidptr

@[weak]
__global (
	grab_mouse_cb      voidptr
	video_inited       bool
	video_window_title &i8
	display_fps_dots   bool
	mut usemouse                  = int(1)
	mut video_driver              = &u8(c'')
	mut window_position           = &u8(c'center')
	mut video_display             int
	mut window_width              = int(800)
	mut window_height             = int(600)
	mut fullscreen_width          int
	mut fullscreen_height         int
	mut max_scaling_buffer_pixels = int(16000000)
	mut aspect_ratio_correct      = int(1)
	mut integer_scaling           int
	mut smooth_pixel_scaling      = int(1)
	mut vga_porch_flash           int
	mut startup_delay             = int(1000)
	mut force_software_renderer   int
	mut grabmouse                 = int(1)
	mut png_screenshots           = int(1)
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
	video_window_title = title
}

@[export: 'I_InitWindowIcon']
pub fn i_init_window_icon() {
	// Icon data is omitted in this minimal port.
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
	display_fps_dots = _dots_on
}

@[export: 'I_BindVideoVariables']
pub fn i_bind_video_variables() {
	m_bind_int_variable(c'use_mouse', &usemouse)
	m_bind_int_variable(c'fullscreen', &fullscreen)
	m_bind_int_variable(c'video_display', &video_display)
	m_bind_int_variable(c'aspect_ratio_correct', &aspect_ratio_correct)
	m_bind_int_variable(c'integer_scaling', &integer_scaling)
	m_bind_int_variable(c'smooth_pixel_scaling', &smooth_pixel_scaling)
	m_bind_int_variable(c'vga_porch_flash', &vga_porch_flash)
	m_bind_int_variable(c'startup_delay', &startup_delay)
	m_bind_int_variable(c'fullscreen_width', &fullscreen_width)
	m_bind_int_variable(c'fullscreen_height', &fullscreen_height)
	m_bind_int_variable(c'force_software_renderer', &force_software_renderer)
	m_bind_int_variable(c'max_scaling_buffer_pixels', &max_scaling_buffer_pixels)
	m_bind_int_variable(c'window_width', &window_width)
	m_bind_int_variable(c'window_height', &window_height)
	m_bind_int_variable(c'grabmouse', &grabmouse)
	m_bind_string_variable(c'video_driver', &video_driver)
	m_bind_string_variable(c'window_position', &window_position)
	m_bind_int_variable(c'usegamma', &usegamma)
	m_bind_int_variable(c'png_screenshots', &png_screenshots)
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
