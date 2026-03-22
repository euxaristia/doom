@[has_globals]
module core

// Column drawing state.
__global dc_colormap = unsafe { nil }
__global dc_x = 0
__global dc_yl = 0
__global dc_yh = 0
__global dc_iscale = Fixed(0)
__global dc_texturemid = Fixed(0)
__global dc_source = []u8{}
__global dc_color = u8(0)
__global dc_texheight = 0

// Span drawing state.
__global ds_y = 0
__global ds_x1 = 0
__global ds_x2 = 0
__global ds_colormap = unsafe { nil }
__global ds_xfrac = Fixed(0)
__global ds_yfrac = Fixed(0)
__global ds_xstep = Fixed(0)
__global ds_ystep = Fixed(0)
__global ds_source = []u8{}

__global translationtables = []u8{}
__global dc_translation = []u8{}

// r_draw_column draws a vertical column.
// If dc_source is set and non-empty, samples from it (texture mapped).
// Otherwise, draws a solid dc_color column.
pub fn r_draw_column() {
	if dc_x < 0 || dc_x >= screenwidth {
		return
	}
	mut y1 := dc_yl
	mut y2 := dc_yh
	if y1 < 0 {
		y1 = 0
	}
	if y2 >= screenheight {
		y2 = screenheight - 1
	}
	if y1 > y2 {
		return
	}

	mut buf := v_buffer()
	mut dc_cm := &u8(unsafe { nil })
	if dc_colormap != unsafe { nil } {
		dc_cm = &u8(dc_colormap)
	}

	if dc_source.len > 0 && dc_texheight > 0 {
		// Texture-mapped column drawing
		mut frac := i64(dc_texturemid) + i64(y1 - v_centery) * i64(dc_iscale)
		for y in y1 .. y2 + 1 {
			mut ty := int(frac >> frac_bits)
			ty = ((ty % dc_texheight) + dc_texheight) % dc_texheight
			if ty >= 0 && ty < dc_source.len {
				color := dc_source[ty]
				if dc_cm != unsafe { nil } {
					buf[y * screenwidth + dc_x] = unsafe { dc_cm[color] }
				} else {
					buf[y * screenwidth + dc_x] = color
				}
			}
			frac += i64(dc_iscale)
		}
	} else {
		// Solid color column - use a recognizable color if dc_color is 0
		color := if dc_color == 0 { u8(150) } else { dc_color }
		if dc_cm != unsafe { nil } {
			final_color := unsafe { dc_cm[color] }
			for y in y1 .. y2 + 1 {
				buf[y * screenwidth + dc_x] = final_color
			}
		} else {
			for y in y1 .. y2 + 1 {
				buf[y * screenwidth + dc_x] = color
			}
		}
	}
}

pub fn r_draw_column_low() {
	r_draw_column()
}

pub fn r_draw_fuzz_column() {
	r_draw_column()
}

pub fn r_draw_fuzz_column_low() {
	r_draw_column()
}

pub fn r_draw_translated_column() {
	r_draw_column()
}

pub fn r_draw_translated_column_low() {
	r_draw_column()
}

pub fn r_video_erase(ofs u32, count int) {
	_ = ofs
	_ = count
}

// r_draw_span draws a horizontal span (floor/ceiling) with texture mapping.
pub fn r_draw_span() {
	if ds_y < 0 || ds_y >= screenheight {
		return
	}
	mut x1 := ds_x1
	mut x2 := ds_x2
	if x1 < 0 {
		x1 = 0
	}
	if x2 >= screenwidth {
		x2 = screenwidth - 1
	}
	if x1 > x2 {
		return
	}
	mut buf := v_buffer()
	off := ds_y * screenwidth
	if ds_source.len >= flat_bytes {
		// Texture-mapped span drawing (flat = 64x64)
		mut xfrac := ds_xfrac
		mut yfrac := ds_yfrac
		for x in x1 .. x2 + 1 {
			// Extract integer coordinates and wrap to 64x64
			tx := (int(xfrac >> frac_bits)) & 63
			ty := (int(yfrac >> frac_bits)) & 63
			idx := ty * 64 + tx
			if idx >= 0 && idx < ds_source.len {
				buf[off + x] = ds_source[idx]
			}
			xfrac += ds_xstep
			yfrac += ds_ystep
		}
	} else {
		color := dc_color
		for x in x1 .. x2 + 1 {
			buf[off + x] = color
		}
	}
}

pub fn r_draw_span_low() {
	r_draw_span()
}

pub fn r_init_buffer(width int, height int) {
	_ = width
	_ = height
}

pub fn r_init_translation_tables() {}
pub fn r_fill_back_screen() {}
pub fn r_draw_view_border() {}
