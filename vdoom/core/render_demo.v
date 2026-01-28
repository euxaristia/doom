@[has_globals]
module core

__global render_tick = 0
__global render_wad_path = ''
__global render_checksum = u64(0)
__global render_was_patch = false
__global render_show_menu = false
__global render_menu_base = []u8{}
__global render_menu_item = 0

const menu_lineheight = 16
const menu_skull_xoff = -32
const menu_item_count = 6

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
	render_show_menu = false
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
	render_show_menu = false
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

fn render_main_menu(mut wad Wad) {
	i_init_graphics()
	v_init()
	load_playpal(mut wad)
	render_wad_path = wad.path
	render_checksum = w_checksum(wad)
	render_tick = 0
	i_reset_frame_dumps()
	render_was_patch = false
	render_show_menu = true
	render_menu_item = 0
	// Base layer: TITLEPIC if available, else clear.
	if wad.has_lump('TITLEPIC') {
		if screen := try_decode_patch_fullscreen(mut wad, 'TITLEPIC') {
			v_draw_raw_screen(screen)
		} else {
			v_clear_screen(0)
		}
	} else {
		v_clear_screen(0)
	}
	// Draw main menu title/logo.
	draw_menu_patch(mut wad, 'M_DOOM', 94, 2)
	// Draw menu items from the classic main menu layout.
	mut x := 97
	mut y := 64
	items := ['M_NGAME', 'M_OPTION', 'M_LOADG', 'M_SAVEG', 'M_RDTHIS', 'M_QUITG']
	for name in items {
		if draw_menu_patch(mut wad, name, x, y) {
			y += menu_lineheight
		} else {
			y += menu_lineheight
		}
	}
	// Snapshot the base menu without the skull for animation frames.
	store_menu_base()
	// Draw initial skull cursor.
	draw_menu_skull(mut wad, x, 64, render_menu_item, 0)
	i_finish_update()
}

fn draw_menu_patch(mut wad Wad, name string, x int, y int) bool {
	if !wad.has_lump(name) {
		return false
	}
	img := load_patch_image_cached(mut wad, name) or { return false }
	draw_patch_image(x, y, img)
	return true
}

fn draw_menu_skull(mut wad Wad, x int, y int, item int, frame int) {
	skull := if frame == 0 { 'M_SKULL1' } else { 'M_SKULL2' }
	if wad.has_lump(skull) {
		if img := load_patch_image_cached(mut wad, skull) {
			draw_patch_image(x + menu_skull_xoff, y - 5 + item * menu_lineheight, img)
			return
		}
	}
	// Fallback: simple box cursor.
	v_draw_box(x + menu_skull_xoff, y - 5 + item * menu_lineheight, 12, 12, 255)
}

fn store_menu_base() {
	if i_video_buffer.len != screenwidth * screenheight {
		return
	}
	if render_menu_base.len != screenwidth * screenheight {
		render_menu_base = []u8{len: screenwidth * screenheight}
	}
	for i := 0; i < render_menu_base.len; i++ {
		render_menu_base[i] = i_video_buffer[i]
	}
}

pub fn render_menu_frame(mut wad Wad) {
	render_main_menu(mut wad)
}

pub fn render_menu_move(delta int) {
	if !render_show_menu {
		return
	}
	mut next := render_menu_item + delta
	if next < 0 {
		next = menu_item_count - 1
	} else if next >= menu_item_count {
		next = 0
	}
	render_menu_item = next
	render_menu_redraw()
}

fn render_menu_redraw() {
	if render_menu_base.len != screenwidth * screenheight {
		return
	}
	v_draw_raw_screen(render_menu_base)
	mut wad := load_wad_with_options(render_wad_path, true, true) or { return }
	which_skull := (render_tick / 8) & 1
	draw_menu_skull(mut wad, 97, 64, render_menu_item, which_skull)
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
	if render_show_menu {
		if render_menu_base.len != screenwidth * screenheight {
			i_finish_update()
			return
		}
		v_draw_raw_screen(render_menu_base)
		mut wad := load_wad_with_options(render_wad_path, true, true) or {
			i_finish_update()
			return
		}
		which_skull := (render_tick / 8) & 1
		draw_menu_skull(mut wad, 97, 64, render_menu_item, which_skull)
		i_finish_update()
		render_tick++
		return
	}
	render_tick++
	// Simple animated marker so repeated frames differ.
	bar_y := 120 + (render_tick % 40)
	v_draw_filled_box(0, bar_y, screenwidth, 4, (render_tick * 3 + int(render_checksum & 0xff)) % 256)
	v_draw_box(0, bar_y, screenwidth, 4, 255)
	i_finish_update()
}
