module core

import gg
import sokol.sapp

__global game_ctx = &gg.Context(unsafe { nil })

struct WindowApp {
mut:
	ctx       &gg.Context = unsafe { nil }
	scale     int
	image_idx int = -1
	rgba      []u8
	logged    bool
	last_up   bool
	last_down bool
	debug_event string
	debug_keys  string
	debug_flash int
	last_key_code int
	last_event_type int
	seen_event bool
}

fn (mut app WindowApp) init() {
	if screenwidth <= 0 || screenheight <= 0 {
		return
	}
	if screenwidth * screenheight <= 0 {
		return
	}
	app.image_idx = app.ctx.new_streaming_image(
		screenwidth,
		screenheight,
		4,
		pixel_format: .rgba8
		min_filter: .nearest
		mag_filter: .nearest
	)
	if app.image_idx < 0 {
		return
	}
	app.rgba = []u8{len: screenwidth * screenheight * 4}
}

fn (mut app WindowApp) frame() {
	app.ctx.begin()
	// Clear the whole drawable area each frame to avoid artifacts.
	real := gg.window_size_real_pixels()
	logical := app.ctx.window_size()
	if !app.logged {
		println('window: ctx=${app.ctx.width}x${app.ctx.height} logical=${logical.width}x${logical.height} real=${real.width}x${real.height} scale=${app.scale}')
		app.logged = true
	}
	app.ctx.draw_rect_filled(0, 0, app.ctx.width, app.ctx.height, gg.black)
	app.ctx.draw_rect_filled(0, 0, real.width, real.height, gg.black)

	// Process events and advance game state
	d_process_events()
	d_handle_game_action()
	try_run_tics()
	render_tick_frame()

	// Edge-detect arrow keys for menu navigation (only if events are not firing).
	up_now := app.ctx.is_key_down(.up)
	down_now := app.ctx.is_key_down(.down)
	if !app.seen_event {
		if up_now && !app.last_up {
			render_menu_move(-1)
		}
		if down_now && !app.last_down {
			render_menu_move(1)
		}
	}
	app.last_up = up_now
	app.last_down = down_now
	if i_debug_input() {
		app.debug_keys = 'poll up=${up_now} down=${down_now} events=${app.seen_event}'
	}

	rgb := i_last_rgb()
	if rgb.len == screenwidth * screenheight * 3 && app.image_idx >= 0 && app.rgba.len == screenwidth * screenheight * 4 {
		// Convert RGB -> RGBA once per frame, then upload as a streaming texture.
		for i := 0; i < screenwidth * screenheight; i++ {
			src := i * 3
			dst := i * 4
			app.rgba[dst] = rgb[src]
			app.rgba[dst + 1] = rgb[src + 1]
			app.rgba[dst + 2] = rgb[src + 2]
			app.rgba[dst + 3] = 255
		}
		app.ctx.update_pixel_data(app.image_idx, &app.rgba[0])

		// Choose target aspect based on configured presentation mode.
		target_aspect := if i_aspect_mode() == 'doom43' { f32(4.0 / 3.0) } else { f32(screenwidth) / f32(screenheight) }

		// Use logical sizes for viewport math and drawing coordinates.
		mut view_w := logical.width
		mut view_h := logical.height
		mut view_x := 0
		mut view_y := 0
		if f32(logical.width) / f32(logical.height) > target_aspect {
			view_h = logical.height
			view_w = int(f32(logical.height) * target_aspect)
			view_x = (logical.width - view_w) / 2
		} else {
			view_w = logical.width
			view_h = int(f32(logical.width) / target_aspect)
			view_y = (logical.height - view_h) / 2
		}

		// Explicitly paint bars to avoid driver artifacts.
		app.ctx.draw_rect_filled(0, 0, logical.width, view_y, gg.black)
		app.ctx.draw_rect_filled(0, view_y + view_h, logical.width, logical.height - (view_y + view_h), gg.black)
		app.ctx.draw_rect_filled(0, view_y, view_x, view_h, gg.black)
		app.ctx.draw_rect_filled(view_x + view_w, view_y, logical.width - (view_x + view_w), view_h, gg.black)

		// Non-uniform scaling inside the 4:3 viewport applies the classic vertical stretch.
		app.ctx.draw_image_by_id(f32(view_x), f32(view_y), f32(view_w), f32(view_h), app.image_idx)
	} else {
		// No valid RGB - just draw black
		app.ctx.draw_rect_filled(0, 0, logical.width, logical.height, gg.black)
	}

	// Debug overlay for input events (enable with VDOOM_DEBUG_INPUT=1).
	if i_debug_input() {
		if app.ctx.font_inited {
			if app.debug_event.len > 0 {
				app.ctx.draw_text(9, 9, app.debug_event, gg.TextCfg{
					color: gg.black
				})
				app.ctx.draw_text(8, 8, app.debug_event, gg.TextCfg{
					color: gg.white
				})
			}
			if app.debug_keys.len > 0 {
				app.ctx.draw_text(9, 21, app.debug_keys, gg.TextCfg{
					color: gg.black
				})
				app.ctx.draw_text(8, 20, app.debug_keys, gg.TextCfg{
					color: gg.white
				})
			}
		}
		// Fallback debug indicator if text rendering is unavailable.
		if app.debug_flash > 0 {
			app.debug_flash--
		}
		up_color := if up_now { gg.green } else { gg.red }
		down_color := if down_now { gg.green } else { gg.red }
		event_color := if app.debug_flash > 0 { gg.yellow } else { gg.gray }
		app.ctx.draw_rect_filled(4, 32, 12, 12, up_color)
		app.ctx.draw_rect_filled(20, 32, 12, 12, down_color)
		app.ctx.draw_rect_filled(36, 32, 12, 12, event_color)
	}
	app.ctx.end()
}

fn gg_key_to_doom(kc gg.KeyCode) int {
	return match kc {
		.space { int(` `) }
		.apostrophe { int(`'`) }
		.comma { int(`,`) }
		.minus { key_minus }
		.period { int(`.`) }
		.slash { int(`/`) }
		._0 { int(`0`) }
		._1 { int(`1`) }
		._2 { int(`2`) }
		._3 { int(`3`) }
		._4 { int(`4`) }
		._5 { int(`5`) }
		._6 { int(`6`) }
		._7 { int(`7`) }
		._8 { int(`8`) }
		._9 { int(`9`) }
		.semicolon { int(`;`) }
		.equal { key_equals }
		.a { int(`a`) }
		.b { int(`b`) }
		.c { int(`c`) }
		.d { int(`d`) }
		.e { int(`e`) }
		.f { int(`f`) }
		.g { int(`g`) }
		.h { int(`h`) }
		.i { int(`i`) }
		.j { int(`j`) }
		.k { int(`k`) }
		.l { int(`l`) }
		.m { int(`m`) }
		.n { int(`n`) }
		.o { int(`o`) }
		.p { int(`p`) }
		.q { int(`q`) }
		.r { int(`r`) }
		.s { int(`s`) }
		.t { int(`t`) }
		.u { int(`u`) }
		.v { int(`v`) }
		.w { int(`w`) }
		.x { int(`x`) }
		.y { int(`y`) }
		.z { int(`z`) }
		.left_bracket { int(`[`) }
		.backslash { int(`\\`) }
		.right_bracket { int(`]`) }
		.grave_accent { 96 }
		.escape { key_escape }
		.enter { key_enter }
		.tab { key_tab }
		.backspace { key_backspace }
		.insert { key_ins }
		.delete { key_del }
		.right { key_rightarrow }
		.left { key_leftarrow }
		.down { key_downarrow }
		.up { key_uparrow }
		.page_up { key_pgup }
		.page_down { key_pgdn }
		.home { key_home }
		.end { key_end }
		.caps_lock { key_capslock }
		.scroll_lock { key_scrlck }
		.num_lock { key_numlock }
		.print_screen { key_prtscr }
		.pause { key_pause }
		.f1 { key_f1 }
		.f2 { key_f2 }
		.f3 { key_f3 }
		.f4 { key_f4 }
		.f5 { key_f5 }
		.f6 { key_f6 }
		.f7 { key_f7 }
		.f8 { key_f8 }
		.f9 { key_f9 }
		.f10 { key_f10 }
		.f11 { key_f11 }
		.f12 { key_f12 }
		.kp_0 { key_ins }
		.kp_1 { key_end }
		.kp_2 { key_downarrow }
		.kp_3 { key_pgdn }
		.kp_4 { key_leftarrow }
		.kp_5 { keyp_5 }
		.kp_6 { key_rightarrow }
		.kp_7 { key_home }
		.kp_8 { key_uparrow }
		.kp_9 { key_pgup }
		.kp_divide { keyp_divide }
		.kp_multiply { keyp_multiply }
		.kp_subtract { keyp_minus }
		.kp_add { keyp_plus }
		.kp_enter { key_enter }
		.kp_equal { key_equals }
		.left_shift { key_rshift }
		.right_shift { key_rshift }
		.left_control { key_rctrl }
		.right_control { key_rctrl }
		.left_alt { key_ralt }
		.right_alt { key_ralt }
		else { 0 }
	}
}

fn on_event(e &gg.Event, _data voidptr) {
	if _data == unsafe { nil } {
		return
	}
	mut app := unsafe { &WindowApp(_data) }
	if i_debug_input() {
		app.debug_event = 'event ${e.typ} key=${e.key_code} repeat=${e.key_repeat}'
		app.last_key_code = int(e.key_code)
		app.last_event_type = int(e.typ)
	}
	app.seen_event = true

	// Handle window close button
	if e.typ == sapp.EventType.quit_requested {
		d_post_quit_event()
		return
	}

	if e.typ == sapp.EventType.key_down {
		if i_debug_input() {
			app.debug_flash = 10
			println('event key_down key=${e.key_code} repeat=${e.key_repeat}')
		}
		if !e.key_repeat {
			d_key := gg_key_to_doom(e.key_code)
			if d_key != 0 {
				ev := Event{
					typ: .keydown
					data1: d_key
				}
				d_post_event(&ev)
			}

			// Handle menu navigation
			match e.key_code {
				.up { render_menu_move(-1) }
				.down { render_menu_move(1) }
				.enter, .space { render_menu_activate() }
				.escape, .backspace { render_menu_back() }
				else {}
			}
		}
	} else if e.typ == sapp.EventType.key_up {
		d_key := gg_key_to_doom(e.key_code)
		if d_key != 0 {
			ev := Event{
				typ: .keyup
				data1: d_key
			}
			d_post_event(&ev)
		}
	}
}

fn on_char(c u32, data voidptr) {
	if data == unsafe { nil } {
		return
	}
	mut app := unsafe { &WindowApp(data) }
	if i_debug_input() {
		app.debug_event = 'char ${c}'
	}
}

pub fn show_window_if_enabled() {
	println('show_window_if_enabled: called, enabled=${i_window_enabled()}')
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

	// Window size follows the selected aspect mode.
	win_w := screenwidth * scale
	win_h := if i_aspect_mode() == 'doom43' { screenheight_4_3 * scale } else { screenheight * scale }

	app.ctx = gg.new_context(
		width: win_w
		height: win_h
		create_window: true
		window_title: i_window_title()
		bg_color: gg.black
		init_fn: app.init
		frame_fn: app.frame
		event_fn: on_event
		char_fn: on_char
		user_data: app
	)

	game_ctx = app.ctx
	app.ctx.run()
}
