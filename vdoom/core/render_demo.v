@[has_globals]
module core

__global render_tick = 0
__global render_wad_path = ''
__global render_checksum = u64(0)
__global render_was_patch = false
__global render_show_menu = false
__global render_menu_base = []u8{}
__global render_menu_item = 0
__global render_menu_items = []MenuItem{}
__global render_menu_x = 97
__global render_menu_y = 64
__global render_menu_screen = MenuScreen.main
__global menu_cursor_color = -1
__global menu_skull_logged = false

const menu_lineheight = 16
const menu_skull_xoff = -32

enum MenuScreen {
	main
	options
}

struct MenuItem {
	name       string
	selectable bool
}

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

fn render_menu_set(mut wad Wad, screen MenuScreen) {
	i_init_graphics()
	v_init()
	load_playpal(mut wad)
	render_wad_path = wad.path
	render_checksum = w_checksum(wad)
	render_tick = 0
	i_reset_frame_dumps()
	render_was_patch = false
	render_show_menu = true
	render_menu_screen = screen
	render_menu_item = 0
	// Base layer: TITLEPIC if available, else clear.
    if wad.has_lump('TITLEPIC') {
        if title_screen := try_decode_patch_fullscreen(mut wad, 'TITLEPIC') {
            v_draw_raw_screen(title_screen)
        } else {
            v_clear_screen(0)
        }
    } else {
        v_clear_screen(0)
    }
	// Build menu definition.
	match screen {
		.main {
			render_menu_x = 97
			render_menu_y = 64
			render_menu_items = [
				MenuItem{name: 'M_NGAME', selectable: true},
				MenuItem{name: 'M_OPTION', selectable: true},
				MenuItem{name: 'M_LOADG', selectable: true},
				MenuItem{name: 'M_SAVEG', selectable: true},
				MenuItem{name: 'M_RDTHIS', selectable: true},
				MenuItem{name: 'M_QUITG', selectable: true},
			]
			draw_menu_patch(mut wad, 'M_DOOM', 94, 2)
			if i_debug_input() {
				println('menu skull lumps: M_SKULL1=${wad.has_lump("M_SKULL1")} M_SKULL2=${wad.has_lump("M_SKULL2")}')
			}
		}
		.options {
			render_menu_x = 60
			render_menu_y = 37
			render_menu_items = [
				MenuItem{name: 'M_ENDGAM', selectable: true},
				MenuItem{name: 'M_MESSG', selectable: true},
				MenuItem{name: 'M_DETAIL', selectable: true},
				MenuItem{name: 'M_SCRNSZ', selectable: true},
				MenuItem{name: '', selectable: false},
				MenuItem{name: 'M_MSENS', selectable: true},
				MenuItem{name: '', selectable: false},
				MenuItem{name: 'M_SVOL', selectable: true},
			]
			draw_menu_patch(mut wad, 'M_OPTTTL', 108, 15)
			if i_debug_input() {
				println('menu skull lumps: M_SKULL1=${wad.has_lump("M_SKULL1")} M_SKULL2=${wad.has_lump("M_SKULL2")}')
			}
		}
	}
	// Draw menu items.
	mut y := render_menu_y
	for item in render_menu_items {
		if item.name.len > 0 {
			_ = draw_menu_patch(mut wad, item.name, render_menu_x, y)
		}
		y += menu_lineheight
	}
	// Snapshot the base menu without the skull for animation frames.
	store_menu_base()
	ensure_menu_item_valid()
	// Draw initial skull cursor.
	draw_menu_skull(mut wad, render_menu_x, render_menu_y, render_menu_item, 0)
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
	skull_names := if frame == 0 {
		['M_SKULL1', 'SKULL1']
	} else {
		['M_SKULL2', 'SKULL2']
	}
	mut drew := false
	for name in skull_names {
		if wad.has_lump(name) {
			if img := load_patch_image_cached(mut wad, name) {
				if i_debug_input() && !menu_skull_logged {
					println('skull ${name} w=${img.width} h=${img.height} left=${img.leftoffset} top=${img.topoffset}')
					println('skull draw at x=${x + menu_skull_xoff} y=${y - 5 + item * menu_lineheight}')
					menu_skull_logged = true
				}
				draw_patch_image(x + menu_skull_xoff, y - 5 + item * menu_lineheight, img)
				if i_debug_input() {
					// Debug-only tick to visualize selection.
					color := menu_cursor_color_index()
					v_draw_filled_box(x - 6, y + item * menu_lineheight + 2, 3, 10, color)
				}
				drew = true
				break
			}
		}
	}
	if !drew {
		// Fallback: simple high-contrast cursor.
		fb_x := x + menu_skull_xoff
		fb_y := y - 5 + item * menu_lineheight
		color := menu_cursor_color_index()
		v_draw_filled_box(fb_x, fb_y, 12, 12, color)
		v_draw_box(fb_x, fb_y, 12, 12, 255)
		if i_debug_input() {
			v_draw_filled_box(x - 6, y + item * menu_lineheight + 2, 3, 10, color)
		}
	}
}

fn menu_cursor_color_index() int {
	if menu_cursor_color >= 0 {
		return menu_cursor_color
	}
	if palette_rgb.len < 256 * 3 {
		menu_cursor_color = 255
		return menu_cursor_color
	}
	mut best_idx := 0
	mut best_score := -1
	for i := 0; i < 256; i++ {
		base := i * 3
		r := int(palette_rgb[base])
		g := int(palette_rgb[base + 1])
		b := int(palette_rgb[base + 2])
		score := r + g + b
		if score > best_score {
			best_score = score
			best_idx = i
		}
	}
	menu_cursor_color = best_idx
	return menu_cursor_color
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
	render_menu_set(mut wad, .main)
}

pub fn render_menu_move(delta int) {
	if !render_show_menu {
		return
	}
	if render_menu_items.len == 0 {
		return
	}
	mut idx := render_menu_item
	for _ in 0 .. render_menu_items.len {
		idx = (idx + delta + render_menu_items.len) % render_menu_items.len
		if render_menu_items[idx].selectable {
			render_menu_item = idx
			break
		}
	}
	render_menu_redraw()
}

pub fn render_menu_activate() {
	if !render_show_menu || render_menu_items.len == 0 {
		return
	}
	item := render_menu_items[render_menu_item]
	match render_menu_screen {
		.main {
			if item.name == 'M_OPTION' {
				mut wad := load_wad_with_options(render_wad_path, true, true) or { return }
				render_menu_set(mut wad, .options)
				return
			}
		}
		.options {}
	}
	println('menu action: ${item.name}')
}

pub fn render_menu_back() {
	if !render_show_menu {
		return
	}
	if render_menu_screen == .options {
		mut wad := load_wad_with_options(render_wad_path, true, true) or { return }
		render_menu_set(mut wad, .main)
	}
}

fn render_menu_redraw() {
	if render_menu_base.len != screenwidth * screenheight {
		return
	}
	v_draw_raw_screen(render_menu_base)
	mut wad := load_wad_with_options(render_wad_path, true, true) or { return }
	which_skull := (render_tick / 8) & 1
	draw_menu_skull(mut wad, render_menu_x, render_menu_y, render_menu_item, which_skull)
	i_finish_update()
}

fn ensure_menu_item_valid() {
	if render_menu_items.len == 0 {
		render_menu_item = 0
		return
	}
	if render_menu_item < 0 || render_menu_item >= render_menu_items.len || !render_menu_items[render_menu_item].selectable {
		for i, item in render_menu_items {
			if item.selectable {
				render_menu_item = i
				return
			}
		}
		render_menu_item = 0
	}
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
		draw_menu_skull(mut wad, render_menu_x, render_menu_y, render_menu_item, which_skull)
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
