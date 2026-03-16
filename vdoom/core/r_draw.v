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

// r_draw_column draws a solid-color vertical column to i_video_buffer.
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
	for y in y1 .. y2 + 1 {
		buf[y * screenwidth + dc_x] = dc_color
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

// r_draw_span draws a horizontal span (floor/ceiling) to i_video_buffer.
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
	color := dc_color
	off := ds_y * screenwidth
	for x in x1 .. x2 + 1 {
		buf[off + x] = color
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
