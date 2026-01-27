module core

pub struct StNumber {
pub mut:
	x      int
	y      int
	width  int
	oldnum int
	num    voidptr
	on     voidptr
	p      []&Patch
	data   int
}

pub struct StPercent {
pub mut:
	n StNumber
	p &Patch = unsafe { nil }
}

pub struct StMultIcon {
pub mut:
	x       int
	y       int
	oldinum int
	inum    voidptr
	on      voidptr
	p       []&Patch
	data    int
}

pub struct StBinIcon {
pub mut:
	x      int
	y      int
	oldval bool
	val    voidptr
	on     voidptr
	p      &Patch = unsafe { nil }
	data   int
}

pub fn stlib_init() {}

pub fn stlib_init_num(mut n StNumber, x int, y int, pl []&Patch, num voidptr, on voidptr, width int) {
	n.x = x
	n.y = y
	n.p = pl
	n.num = num
	n.on = on
	n.width = width
}

pub fn stlib_update_num(n &StNumber, refresh bool) {
	_ = n
	_ = refresh
}

pub fn stlib_init_percent(mut p StPercent, x int, y int, pl []&Patch, num voidptr, on voidptr, percent &Patch) {
	stlib_init_num(mut p.n, x, y, pl, num, on, 3)
	unsafe { p.p = percent }
}

pub fn stlib_update_percent(per &StPercent, refresh int) {
	_ = per
	_ = refresh
}

pub fn stlib_init_mult_icon(mut mi StMultIcon, x int, y int, il []&Patch, inum voidptr, on voidptr) {
	mi.x = x
	mi.y = y
	mi.p = il
	mi.inum = inum
	mi.on = on
}

pub fn stlib_update_mult_icon(mi &StMultIcon, refresh bool) {
	_ = mi
	_ = refresh
}

pub fn stlib_init_bin_icon(mut b StBinIcon, x int, y int, i &Patch, val voidptr, on voidptr) {
	b.x = x
	b.y = y
	unsafe { b.p = i }
	b.val = val
	b.on = on
}

pub fn stlib_update_bin_icon(b &StBinIcon, refresh bool) {
	_ = b
	_ = refresh
}
