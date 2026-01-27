module core

import gg

struct WindowApp {
mut:
	ctx       &gg.Context = unsafe { nil }
	scale     int
	image_idx int
	rgba      []u8
	logged    bool
}

fn (mut app WindowApp) init() {
	app.image_idx = app.ctx.new_streaming_image(
		screenwidth,
		screenheight,
		4,
		pixel_format: .rgba8
		min_filter: .nearest
		mag_filter: .nearest
	)
	if app.rgba.len != screenwidth * screenheight * 4 {
		app.rgba = []u8{len: screenwidth * screenheight * 4}
	}
}

fn (mut app WindowApp) frame() {
	app.ctx.begin()
	// Clear the whole drawable area each frame to avoid artifacts.
	real := gg.window_size_real_pixels()
	if !app.logged {
		println('window: ctx=${app.ctx.width}x${app.ctx.height} real=${real.width}x${real.height} scale=${app.scale}')
		app.logged = true
	}
	app.ctx.draw_rect_filled(0, 0, app.ctx.width, app.ctx.height, gg.black)
	app.ctx.draw_rect_filled(0, 0, real.width, real.height, gg.black)
	// Optionally advance the pure-V renderer each frame.
	if i_animate_enabled() {
		render_tick_frame()
	}
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
		// Draw with integer letterboxing based on real pixel size.
		mut scale_x := real.width / screenwidth
		mut scale_y := real.height / screenheight
		mut scale := if scale_x < scale_y { scale_x } else { scale_y }
		if scale < 1 {
			scale = 1
		}
		// Respect the configured maximum scale if set.
		if app.scale > 0 && scale > app.scale {
			scale = app.scale
		}
		draw_w := screenwidth * scale
		draw_h := screenheight * scale
		off_x := (real.width - draw_w) / 2
		off_y := (real.height - draw_h) / 2
		// Explicitly paint letterbox bars to avoid driver artifacts.
		app.ctx.draw_rect_filled(0, 0, real.width, off_y, gg.black)
		app.ctx.draw_rect_filled(0, off_y + draw_h, real.width, real.height - (off_y + draw_h), gg.black)
		app.ctx.draw_rect_filled(0, off_y, off_x, draw_h, gg.black)
		app.ctx.draw_rect_filled(off_x + draw_w, off_y, real.width - (off_x + draw_w), draw_h, gg.black)
		app.ctx.draw_image_by_id(f32(off_x), f32(off_y), f32(draw_w), f32(draw_h), app.image_idx)
	}
	app.ctx.end()
}

pub fn show_window_if_enabled() {
	if !i_window_enabled() {
		return
	}
	rgb := i_last_rgb()
	if rgb.len != screenwidth * screenheight * 3 {
		println('window: no RGB frame available to display')
		return
	}
	scale := i_window_scale()
	mut app := &WindowApp{
		scale: scale
		rgba:  []u8{len: screenwidth * screenheight * 4}
	}
	win_w := screenwidth * scale
	win_h := screenheight * scale
	app.ctx = gg.new_context(
		width: win_w
		height: win_h
		create_window: true
		window_title: 'vdoom (pure V)'
		bg_color: gg.black
		init_fn: app.init
		frame_fn: app.frame
		user_data: app
	)
	app.ctx.run()
}
