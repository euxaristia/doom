@[translated]
module main

// Video primitives: core software drawing helpers.

fn C.memcpy(voidptr, voidptr, usize) voidptr

const sw_screen_w = 320
const sw_screen_h = 200

@[weak]
__global (
	v_buffer        &Pixel_t
	v_using_alt_buf bool
)

fn v_active_buffer() &Pixel_t {
	if v_using_alt_buf && v_buffer != unsafe { nil } {
		return v_buffer
	}
	return I_VideoBuffer
}

fn v_put_pixel(buf &Pixel_t, x int, y int, c int) {
	if buf == unsafe { nil } {
		return
	}
	if x < 0 || y < 0 || x >= sw_screen_w || y >= sw_screen_h {
		return
	}
	unsafe {
		buf[y * sw_screen_w + x] = Pixel_t(c)
	}
}

@[export: 'V_MarkRect']
pub fn v_mark_rect(_x int, _y int, _width int, _height int) {
	_ = _x
	_ = _y
	_ = _width
	_ = _height
}

@[export: 'V_CopyRect']
pub fn v_copy_rect(srcx int, srcy int, source &Pixel_t, width int, height int, destx int, desty int) {
	dest := v_active_buffer()
	if source == unsafe { nil } || dest == unsafe { nil } {
		return
	}
	for y := 0; y < height; y++ {
		sy := srcy + y
		dy := desty + y
		if sy < 0 || dy < 0 || sy >= sw_screen_h || dy >= sw_screen_h {
			continue
		}
		if srcx < 0 || destx < 0 || srcx + width > sw_screen_w || destx + width > sw_screen_w {
			for x := 0; x < width; x++ {
				sx := srcx + x
				dx := destx + x
				if sx < 0 || dx < 0 || sx >= sw_screen_w || dx >= sw_screen_w {
					continue
				}
				unsafe {
					dest[dy * sw_screen_w + dx] = source[sy * sw_screen_w + sx]
				}
			}
		} else {
			unsafe {
				C.memcpy(dest + dy * sw_screen_w + destx, source + sy * sw_screen_w + srcx,
					usize(width))
			}
		}
	}
}

@[export: 'V_DrawBlock']
pub fn v_draw_block(x int, y int, width int, height int, src &Pixel_t) {
	dest := v_active_buffer()
	if src == unsafe { nil } || dest == unsafe { nil } {
		return
	}
	for row := 0; row < height; row++ {
		dy := y + row
		if dy < 0 || dy >= sw_screen_h {
			continue
		}
		for col := 0; col < width; col++ {
			dx := x + col
			if dx < 0 || dx >= sw_screen_w {
				continue
			}
			unsafe {
				dest[dy * sw_screen_w + dx] = src[row * width + col]
			}
		}
	}
}

@[export: 'V_DrawScaledBlock']
pub fn v_draw_scaled_block(x int, y int, width int, height int, src &u8) {
	v_draw_block(x, y, width, height, &Pixel_t(src))
}

@[export: 'V_DrawFilledBox']
pub fn v_draw_filled_box(x int, y int, w int, h int, c int) {
	for yy := 0; yy < h; yy++ {
		for xx := 0; xx < w; xx++ {
			v_put_pixel(v_active_buffer(), x + xx, y + yy, c)
		}
	}
}

@[export: 'V_DrawHorizLine']
pub fn v_draw_horiz_line(x int, y int, w int, c int) {
	for xx := 0; xx < w; xx++ {
		v_put_pixel(v_active_buffer(), x + xx, y, c)
	}
}

@[export: 'V_DrawVertLine']
pub fn v_draw_vert_line(x int, y int, h int, c int) {
	for yy := 0; yy < h; yy++ {
		v_put_pixel(v_active_buffer(), x, y + yy, c)
	}
}

@[export: 'V_DrawBox']
pub fn v_draw_box(x int, y int, w int, h int, c int) {
	if w <= 0 || h <= 0 {
		return
	}
	v_draw_horiz_line(x, y, w, c)
	v_draw_horiz_line(x, y + h - 1, w, c)
	v_draw_vert_line(x, y, h, c)
	v_draw_vert_line(x + w - 1, y, h, c)
}

@[export: 'V_UseBuffer']
pub fn v_use_buffer(buffer &Pixel_t) {
	v_buffer = buffer
	v_using_alt_buf = buffer != unsafe { nil }
}

@[export: 'V_RestoreBuffer']
pub fn v_restore_buffer() {
	v_buffer = unsafe { nil }
	v_using_alt_buf = false
}
