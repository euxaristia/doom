@[has_globals]
module core

__global render_tick = 0

fn load_playpal(mut wad Wad) {
	pal := wad.read_lump('PLAYPAL') or { return }
	if pal.len >= 256 * 3 {
		i_set_palette(pal[..256 * 3])
	}
}

pub fn render_demo_frame(mut wad Wad) {
	i_init_graphics()
	v_init()
	load_playpal(mut wad)
	render_tick = 0
	// Palette gradient background.
	mut screen := []u8{len: screenwidth * screenheight}
	for y in 0 .. screenheight {
		for x in 0 .. screenwidth {
			idx := (x * 256) / screenwidth
			screen[y * screenwidth + x] = u8(idx)
		}
	}
	v_draw_raw_screen(screen)
	// Add a couple of simple overlays so the output is recognizable.
	v_draw_filled_box(8, 8, screenwidth - 16, 24, 0)
	v_draw_box(8, 8, screenwidth - 16, 24, 255)
	for i in 0 .. 10 {
		c := (i * 23) % 256
		v_draw_filled_box(16 + i * 28, 48, 20, 60, c)
		v_draw_box(16 + i * 28, 48, 20, 60, 255)
	}
	i_finish_update()
}

pub fn render_tick_frame() {
	if i_video_buffer.len != screenwidth * screenheight {
		return
	}
	render_tick++
	// Simple animated marker so repeated frames differ.
	bar_y := 120 + (render_tick % 40)
	v_draw_filled_box(0, bar_y, screenwidth, 4, (render_tick * 3) % 256)
	v_draw_box(0, bar_y, screenwidth, 4, 255)
	i_finish_update()
}
