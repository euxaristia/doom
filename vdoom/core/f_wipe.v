@[has_globals]
module core

pub enum WipeType {
	color_xform
	melt
	numwipes
}

// Global wipe state mirrors the C module-level statics.
__global (
	wipe_go_        bool
	wipe_scr_start  []u8
	wipe_scr_end    []u8
	wipe_scr_work   []u8
	wipe_y_offsets  []int
)

pub fn wipe_start_screen(x int, y int, width int, height int) int {
	_ = x
	_ = y
	_ = width
	_ = height
	wipe_go_ = false
	return 0
}

pub fn wipe_end_screen(x int, y int, width int, height int) int {
	_ = x
	_ = y
	_ = width
	_ = height
	return 0
}

pub fn wipe_screen_wipe(wipeno int, x int, y int, width int, height int, ticks int) int {
	_ = wipeno
	_ = x
	_ = y
	_ = width
	_ = height
	_ = ticks
	wipe_go_ = false
	return 0
}
