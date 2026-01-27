@[has_globals]
module core

__global render_tick = 0
__global render_wad_path = ''
__global render_checksum = u64(0)
__global render_was_patch = false

fn load_playpal(mut wad Wad) {
	pal := wad.read_lump('PLAYPAL') or { return }
	if pal.len >= 256 * 3 {
		i_set_palette(pal[..256 * 3])
	}
	if wad.has_lump('COLORMAP') {
		if cmap := wad.read_lump('COLORMAP') {
			i_set_colormap(cmap)
		}
	}
}

pub fn render_patch_frame(mut wad Wad, patch_name string) {
	i_init_graphics()
	v_init()
	load_playpal(mut wad)
	render_wad_path = wad.path
	render_checksum = w_checksum(wad)
	render_tick = 0
	i_reset_frame_dumps()
	name := patch_name.to_upper()
	if wad.has_lump(name) {
		if screen := try_decode_patch_fullscreen(mut wad, name) {
			v_draw_raw_screen(screen)
			render_was_patch = true
			println('render: patch ${name} decoded to screen')
			i_finish_update()
			return
		}
	}
	render_was_patch = false
	println('render: patch ${name} not found, falling back to demo frame')
	render_demo_frame(mut wad)
}

pub fn render_demo_frame(mut wad Wad) {
	i_init_graphics()
	v_init()
	load_playpal(mut wad)
	render_wad_path = wad.path
	render_checksum = w_checksum(wad)
	render_tick = 0
	i_reset_frame_dumps()
	render_was_patch = false
	// Try to draw a real Doom patch if available.
	mut drew_titlepic := false
	if wad.has_lump('TITLEPIC') {
		if screen := try_decode_patch_fullscreen(mut wad, 'TITLEPIC') {
			v_draw_raw_screen(screen)
			drew_titlepic = true
			println('render: TITLEPIC decoded to screen')
		}
	}
	// Fallback: palette gradient background.
	if !drew_titlepic {
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
		// Visualize the directory checksum as a simple barcode.
		mut sum := render_checksum
		for i in 0 .. 32 {
			bit := int(sum & 1)
			sum >>= 1
			if bit == 1 {
				v_draw_filled_box(4 + i * 9, screenheight - 12, 6, 8, 255)
			}
		}
	}
	i_finish_update()
}

pub fn render_more_frames(count int) {
	if count <= 0 {
		return
	}
	for _ in 0 .. count {
		render_tick_frame()
	}
}

pub fn render_tick_frame() {
	if i_video_buffer.len != screenwidth * screenheight {
		return
	}
	// Do not draw the animated bar over patch renders like TITLEPIC.
	if render_was_patch {
		i_finish_update()
		return
	}
	render_tick++
	// Simple animated marker so repeated frames differ.
	bar_y := 120 + (render_tick % 40)
	v_draw_filled_box(0, bar_y, screenwidth, 4, (render_tick * 3 + int(render_checksum & 0xff)) % 256)
	v_draw_box(0, bar_y, screenwidth, 4, 255)
	i_finish_update()
}
