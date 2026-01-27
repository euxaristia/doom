@[has_globals]
module core

import os
import math

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
__global last_rgb = []u8{}
__global window_enabled = false
__global animate_enabled = false
__global window_scale = 2
__global gamma_value = f32(1.2)
__global aspect_mode = 'native'
__global colormap_data = []u8{}
__global colormap_level = 0

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
		// Doom palettes are typically 0..63; scale to 0..255 and apply gamma.
		mut scaled := []u8{len: i_palette.len}
		for i, v in i_palette {
			vv := int(v)
			// If values are in 0..63, scale precisely; otherwise clamp.
			mut sv := if vv <= 63 { (vv * 255 + 31) / 63 } else { vv }
			if sv < 0 {
				sv = 0
			} else if sv > 255 {
				sv = 255
			}
			// Apply a simple gamma curve to better match Doom's look.
			if gamma_value != 1.0 {
				norm := f32(sv) / 255.0
				// gamma_value > 1.0 darkens; < 1.0 brightens.
				corrected := math.powf(norm, gamma_value)
				sv = int(corrected * 255.0 + 0.5)
				if sv < 0 {
					sv = 0
				} else if sv > 255 {
					sv = 255
				}
			}
			scaled[i] = u8(sv)
		}
		palette_rgb = scaled.clone()
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
	if i_video_buffer.len == 0 || palette_rgb.len < 256 * 3 {
		return
	}
	mut rgb := []u8{len: screenwidth * screenheight * 3}
	for i in 0 .. i_video_buffer.len {
		pal_idx := apply_colormap(int(i_video_buffer[i]))
		idx := pal_idx * 3
		if idx < 0 || idx + 2 >= palette_rgb.len {
			continue
		}
		base := i * 3
		rgb[base] = palette_rgb[idx]
		rgb[base + 1] = palette_rgb[idx + 1]
		rgb[base + 2] = palette_rgb[idx + 2]
	}
	// Always keep the most recent RGB frame for window display.
	last_rgb = rgb.clone()
	// Optionally dump a few frames to PPM so rendering is visible without SDL.
	if !dump_frames || frame_dump_count >= 5 {
		return
	}
	frame_dump_count++
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

pub fn i_last_rgb() []u8 {
	return last_rgb
}

pub fn i_set_window_enabled(enabled bool) {
	window_enabled = enabled
}

pub fn i_window_enabled() bool {
	return window_enabled
}

pub fn i_set_animate_enabled(enabled bool) {
	animate_enabled = enabled
}

pub fn i_animate_enabled() bool {
	return animate_enabled
}

pub fn i_set_window_scale(scale int) {
	if scale > 0 {
		window_scale = scale
	}
}

pub fn i_window_scale() int {
	return window_scale
}

pub fn i_set_gamma(value f32) {
	if value > 0.0 {
		gamma_value = value
	}
}

pub fn i_gamma() f32 {
	return gamma_value
}

pub fn i_set_aspect_mode(mode string) {
	m := mode.to_lower()
	if m == 'native' || m == 'doom43' {
		aspect_mode = m
	}
}

pub fn i_aspect_mode() string {
	return aspect_mode
}

pub fn i_set_colormap(data []u8) {
	colormap_data = data.clone()
}

pub fn i_set_colormap_level(level int) {
	if level >= 0 {
		colormap_level = level
	}
}

fn apply_colormap(idx int) int {
	if colormap_data.len < 256 {
		return idx
	}
	maps := colormap_data.len / 256
	if maps <= 0 {
		return idx
	}
	mut level := colormap_level
	if level < 0 {
		level = 0
	} else if level >= maps {
		level = maps - 1
	}
	base := level * 256
	if idx < 0 || idx >= 256 || base + idx >= colormap_data.len {
		return idx
	}
	return int(colormap_data[base + idx])
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
