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

pub fn r_draw_column() {}
pub fn r_draw_column_low() {}
pub fn r_draw_fuzz_column() {}
pub fn r_draw_fuzz_column_low() {}
pub fn r_draw_translated_column() {}
pub fn r_draw_translated_column_low() {}

pub fn r_video_erase(ofs u32, count int) {
	_ = ofs
	_ = count
}

pub fn r_draw_span() {}
pub fn r_draw_span_low() {}

pub fn r_init_buffer(width int, height int) {
	_ = width
	_ = height
}

pub fn r_init_translation_tables() {}
pub fn r_fill_back_screen() {}
pub fn r_draw_view_border() {}
