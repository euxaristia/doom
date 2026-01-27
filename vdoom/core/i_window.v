module core

import gg

struct WindowApp {
mut:
	ctx       &gg.Context = unsafe { nil }
	scale     int
	image_idx int
	rgba      []u8
}

fn (mut app WindowApp) init() {
	app.image_idx = app.ctx.new_streaming_image(screenwidth, screenheight, 4, pixel_format: .rgba8)
	if app.rgba.len != screenwidth * screenheight * 4 {
		app.rgba = []u8{len: screenwidth * screenheight * 4}
	}
}

fn (mut app WindowApp) frame() {
	app.ctx.begin()
	rgb := i_last_rgb()
	if rgb.len == screenwidth * screenheight * 3 {
		// Convert RGB -> RGBA once per frame, then upload as a streaming texture.
		if app.rgba.len != screenwidth * screenheight * 4 {
			app.rgba = []u8{len: screenwidth * screenheight * 4}
		}
		for i := 0; i < screenwidth * screenheight; i++ {
			src := i * 3
			dst := i * 4
			app.rgba[dst] = rgb[src]
			app.rgba[dst + 1] = rgb[src + 1]
			app.rgba[dst + 2] = rgb[src + 2]
			app.rgba[dst + 3] = 255
		}
		app.ctx.update_pixel_data(app.image_idx, &app.rgba[0])
		s := f32(app.scale)
		app.ctx.draw_image_by_id(0, 0, f32(screenwidth) * s, f32(screenheight) * s, app.image_idx)
	}
	app.ctx.end()
}

pub fn show_window_if_enabled() {
	if !i_window_enabled() {
		return
	}
	rgb := i_last_rgb()
	println('window: last_rgb len=${rgb.len}')
	if rgb.len >= 6 {
		println('window: first_rgb=${rgb[0]},${rgb[1]},${rgb[2]}')
	}
	if rgb.len != screenwidth * screenheight * 3 {
		println('window: no RGB frame available to display')
		return
	}
	mut app := &WindowApp{
		scale: 2
		rgba:  []u8{len: screenwidth * screenheight * 4}
	}
	app.ctx = gg.new_context(
		width: screenwidth * app.scale
		height: screenheight * app.scale
		create_window: true
		window_title: 'vdoom (pure V)'
		init_fn: app.init
		frame_fn: app.frame
		user_data: app
	)
	app.ctx.run()
}
