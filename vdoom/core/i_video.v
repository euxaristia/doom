@[has_globals]
module core

import os

pub const screenwidth = 320
pub const screenheight = 200
pub const screenheight_4_3 = 240

pub type GrabMouseCallback = fn () bool

__global video_driver = ''
__global screenvisible = true
__global screensaver_mode = false
__global usegamma = 0
__global i_video_buffer = []u8{}
__global screen_width = 800
__global screen_height = 600
__global fullscreen = true
__global aspect_ratio_correct = true
__global integer_scaling = false
__global vga_porch_flash = false
__global force_software_renderer = false
__global window_position = 'center'
__global joywait = u32(0)
__global grabmouse_callback = GrabMouseCallback(unsafe { nil })
__global i_palette = []u8{}
__global palette_rgb = []u8{}
__global frame_dump_count = 0
__global dump_frames = true
__global palette_loaded = false

pub fn i_init_graphics() {
	if i_video_buffer.len == 0 {
		i_video_buffer = []u8{len: screenwidth * screenheight}
	}
	if i_palette.len == 0 {
		i_palette = []u8{len: 256 * 3}
		palette_rgb = i_palette.clone()
	}
	env := os.getenv('VDOOM_DUMP_FRAMES')
	if env.len > 0 {
		dump_frames = env != '0'
	}
	screenvisible = true
}

pub fn i_graphics_check_command_line() {
}

pub fn i_shutdown_graphics() {
}

pub fn i_set_palette(palette []u8) {
	if palette.len >= 256 * 3 {
		i_palette = palette[..256 * 3].clone()
		palette_rgb = i_palette.clone()
		palette_loaded = true
	}
}

pub fn i_get_palette_index(r int, g int, b int) int {
	_ = r
	_ = g
	_ = b
	return 0
}

pub fn i_update_no_blit() {
}

pub fn i_finish_update() {
	if !dump_frames || i_video_buffer.len == 0 || palette_rgb.len < 256 * 3 {
		return
	}
	// Dump a few frames to PPM so rendering is visible without SDL.
	if frame_dump_count >= 5 {
		return
	}
	frame_dump_count++
	mut rgb := []u8{len: screenwidth * screenheight * 3}
	for i in 0 .. i_video_buffer.len {
		idx := int(i_video_buffer[i]) * 3
		if idx + 2 >= palette_rgb.len {
			continue
		}
		base := i * 3
		rgb[base] = palette_rgb[idx]
		rgb[base + 1] = palette_rgb[idx + 1]
		rgb[base + 2] = palette_rgb[idx + 2]
	}
	header := 'P6\n${screenwidth} ${screenheight}\n255\n'.bytes()
	mut out := []u8{cap: header.len + rgb.len}
	out << header
	out << rgb
	os.mkdir_all('out') or {}
	path := os.join_path('out', 'vdoom_frame_${frame_dump_count}.ppm')
	os.write_file_array(path, out) or {}
	println('rendered frame -> ${path}')
}

pub fn i_set_dump_frames(enabled bool) {
	dump_frames = enabled
}

pub fn i_palette_ready() bool {
	return palette_loaded
}

pub fn i_reset_frame_dumps() {
	frame_dump_count = 0
}

pub fn i_frame_dump_count() int {
	return frame_dump_count
}

pub fn i_read_screen(mut scr []u8) {
	if i_video_buffer.len == 0 || scr.len == 0 {
		return
	}
	mut max := i_video_buffer.len
	if scr.len < max {
		max = scr.len
	}
	for i in 0 .. max {
		scr[i] = i_video_buffer[i]
	}
}

pub fn i_begin_read() {
}

pub fn i_set_window_title(title string) {
	_ = title
}

pub fn i_check_is_screensaver() {
}

pub fn i_set_grab_mouse_callback(func GrabMouseCallback) {
	grabmouse_callback = func
}

pub fn i_display_fps_dots(dots_on bool) {
	_ = dots_on
}

pub fn i_bind_video_variables() {
}

pub fn i_init_window_title() {
}

pub fn i_init_window_icon() {
}

pub fn i_start_frame() {
}

pub fn i_start_tic() {
}

pub fn i_enable_loading_disk(xoffs int, yoffs int) {
	_ = xoffs
	_ = yoffs
}

pub struct WindowPosition {
pub:
	x int
	y int
}

pub fn i_get_window_position(w int, h int) WindowPosition {
	_ = w
	_ = h
	return WindowPosition{
		x: 0
		y: 0
	}
}
