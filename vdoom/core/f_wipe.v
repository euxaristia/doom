module core

pub enum WipeType {
	color_xform
	melt
	numwipes
}

pub fn wipe_start_screen(x int, y int, width int, height int) int {
	_ = x
	_ = y
	_ = width
	_ = height
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
	return 0
}
