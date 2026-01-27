@[has_globals]
module core

pub const centery = screenheight / 2

pub type VPatchClipFunc = fn (patch &Patch, x int, y int) bool

__global dirtybox = [0, 0, 0, 0]
__global tinttable = []u8{}
__global v_patch_clip_callback = VPatchClipFunc(unsafe { nil })
__global v_active_buffer = []u8{}

pub fn v_set_patch_clip_callback(func VPatchClipFunc) {
	v_patch_clip_callback = func
}

pub fn v_init() {
	unsafe {
		v_active_buffer = i_video_buffer
	}
}

pub fn v_copy_rect(srcx int, srcy int, source []u8, width int, height int, destx int, desty int) {
	if source.len == 0 || width <= 0 || height <= 0 {
		return
	}
	mut dest := v_buffer()
	for y in 0 .. height {
		sy := srcy + y
		dy := desty + y
		if sy < 0 || dy < 0 || dy >= screenheight {
			continue
		}
		for x in 0 .. width {
			sx := srcx + x
			dx := destx + x
			if sx < 0 || dx < 0 || dx >= screenwidth {
				continue
			}
			sidx := sy * width + sx
			didx := dy * screenwidth + dx
			if sidx >= 0 && sidx < source.len && didx < dest.len {
				dest[didx] = source[sidx]
			}
		}
	}
}

pub fn v_draw_patch(x int, y int, patch &Patch) {
	_ = patch
	img := v_try_load_patch('TITLEPIC') or { return }
	draw_patch_image(x, y, img)
}

pub fn v_draw_patch_flipped(x int, y int, patch &Patch) {
	_ = patch
	img := v_try_load_patch('TITLEPIC') or { return }
	draw_patch_image_flipped(x, y, img)
}

pub fn v_draw_tl_patch(x int, y int, patch &Patch) {
	_ = x
	_ = y
	_ = patch
}

pub fn v_draw_alt_tl_patch(x int, y int, patch &Patch) {
	_ = x
	_ = y
	_ = patch
}

pub fn v_draw_shadowed_patch(x int, y int, patch &Patch) {
	_ = x
	_ = y
	_ = patch
}

pub fn v_draw_xla_patch(x int, y int, patch &Patch) {
	_ = x
	_ = y
	_ = patch
}

pub fn v_draw_patch_direct(x int, y int, patch &Patch) {
	v_draw_patch(x, y, patch)
}

pub fn v_draw_block(x int, y int, width int, height int, src []u8) {
	if src.len == 0 || width <= 0 || height <= 0 {
		return
	}
	mut dest := v_buffer()
	for row in 0 .. height {
		dy := y + row
		if dy < 0 || dy >= screenheight {
			continue
		}
		for col in 0 .. width {
			dx := x + col
			if dx < 0 || dx >= screenwidth {
				continue
			}
			sidx := row * width + col
			didx := dy * screenwidth + dx
			if sidx < src.len && didx < dest.len {
				dest[didx] = src[sidx]
			}
		}
	}
	v_mark_rect(x, y, width, height)
}

pub fn v_mark_rect(x int, y int, width int, height int) {
	if width <= 0 || height <= 0 {
		return
	}
	dirtybox[0] = if dirtybox[0] == 0 { x } else { min(dirtybox[0], x) }
	dirtybox[1] = if dirtybox[1] == 0 { y } else { min(dirtybox[1], y) }
	dirtybox[2] = max(dirtybox[2], x + width)
	dirtybox[3] = max(dirtybox[3], y + height)
}

pub fn v_draw_filled_box(x int, y int, w int, h int, c int) {
	if w <= 0 || h <= 0 {
		return
	}
	mut dest := v_buffer()
	color := u8(c & 0xff)
	for row in 0 .. h {
		dy := y + row
		if dy < 0 || dy >= screenheight {
			continue
		}
		for col in 0 .. w {
			dx := x + col
			if dx < 0 || dx >= screenwidth {
				continue
			}
			dest[dy * screenwidth + dx] = color
		}
	}
	v_mark_rect(x, y, w, h)
}

pub fn v_draw_horiz_line(x int, y int, w int, c int) {
	v_draw_filled_box(x, y, w, 1, c)
}

pub fn v_draw_vert_line(x int, y int, h int, c int) {
	v_draw_filled_box(x, y, 1, h, c)
}

pub fn v_draw_box(x int, y int, w int, h int, c int) {
	if w <= 1 || h <= 1 {
		return
	}
	v_draw_horiz_line(x, y, w, c)
	v_draw_horiz_line(x, y + h - 1, w, c)
	v_draw_vert_line(x, y, h, c)
	v_draw_vert_line(x + w - 1, y, h, c)
}

pub fn v_draw_raw_screen(raw []u8) {
	if raw.len == 0 {
		return
	}
	mut max := screenwidth * screenheight
	if raw.len < max {
		max = raw.len
	}
	if i_video_buffer.len < max {
		return
	}
	for i in 0 .. max {
		i_video_buffer[i] = raw[i]
	}
	unsafe {
		v_active_buffer = i_video_buffer
	}
}

pub fn v_use_buffer(buffer []u8) {
	if buffer.len == screenwidth * screenheight {
		unsafe {
			v_active_buffer = buffer
		}
	}
}

pub fn v_restore_buffer() {
	unsafe {
		v_active_buffer = i_video_buffer
	}
}

pub fn v_screen_shot(format string) {
	_ = format
}

pub fn v_load_tint_table() {
}

pub fn v_load_xla_table() {
}

pub fn v_draw_mouse_speed_box(speed int) {
	_ = speed
}

pub fn v_clear_screen(c int) {
	v_draw_filled_box(0, 0, screenwidth, screenheight, c)
}

fn v_buffer() []u8 {
	if v_active_buffer.len == screenwidth * screenheight {
		return v_active_buffer
	}
	if i_video_buffer.len != screenwidth * screenheight {
		i_init_graphics()
	}
	unsafe {
		v_active_buffer = i_video_buffer
	}
	return v_active_buffer
}

fn v_try_load_patch(name string) ?PatchImage {
	if render_wad_path.len == 0 {
		return none
	}
	mut wad := load_wad_with_options(render_wad_path, true, true) or { return none }
	if wad.has_lump(name) {
		return load_patch_image(mut wad, name)
	}
	if name != 'INTERPIC' && wad.has_lump('INTERPIC') {
		return load_patch_image(mut wad, 'INTERPIC')
	}
	return none
}

fn min(a int, b int) int {
	return if a < b { a } else { b }
}

fn max(a int, b int) int {
	return if a > b { a } else { b }
}
