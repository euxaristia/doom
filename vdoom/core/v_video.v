@[has_globals]
module core

pub const centery = screenheight / 2

pub type VPatchClipFunc = fn (patch &Patch, x int, y int) bool

__global dirtybox = [0, 0, 0, 0]
__global tinttable = []u8{}
__global v_patch_clip_callback = VPatchClipFunc(unsafe { nil })

pub fn v_set_patch_clip_callback(func VPatchClipFunc) {
	v_patch_clip_callback = func
}

pub fn v_init() {
}

pub fn v_copy_rect(srcx int, srcy int, source []u8, width int, height int, destx int, desty int) {
	_ = srcx
	_ = srcy
	_ = source
	_ = width
	_ = height
	_ = destx
	_ = desty
}

pub fn v_draw_patch(x int, y int, patch &Patch) {
	_ = x
	_ = y
	_ = patch
}

pub fn v_draw_patch_flipped(x int, y int, patch &Patch) {
	_ = x
	_ = y
	_ = patch
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
	_ = x
	_ = y
	_ = patch
}

pub fn v_draw_block(x int, y int, width int, height int, src []u8) {
	_ = x
	_ = y
	_ = width
	_ = height
	_ = src
}

pub fn v_mark_rect(x int, y int, width int, height int) {
	_ = x
	_ = y
	_ = width
	_ = height
}

pub fn v_draw_filled_box(x int, y int, w int, h int, c int) {
	_ = x
	_ = y
	_ = w
	_ = h
	_ = c
}

pub fn v_draw_horiz_line(x int, y int, w int, c int) {
	_ = x
	_ = y
	_ = w
	_ = c
}

pub fn v_draw_vert_line(x int, y int, h int, c int) {
	_ = x
	_ = y
	_ = h
	_ = c
}

pub fn v_draw_box(x int, y int, w int, h int, c int) {
	_ = x
	_ = y
	_ = w
	_ = h
	_ = c
}

pub fn v_draw_raw_screen(raw []u8) {
	_ = raw
}

pub fn v_use_buffer(buffer []u8) {
	_ = buffer
}

pub fn v_restore_buffer() {
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
