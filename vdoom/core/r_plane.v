@[has_globals]
module core

__global lastopening = []i16{}

pub type PlaneFunction = fn (top int, bottom int)

__global floorfunc = PlaneFunction(unsafe { nil })
__global ceilingfunc = PlaneFunction(unsafe { nil })

__global floorclip = []i16{len: screenwidth}
__global ceilingclip = []i16{len: screenwidth}
__global yslope = []Fixed{len: screenheight}
__global distscale = []Fixed{len: screenwidth}

pub fn r_init_planes() {}
pub fn r_clear_planes() {}

pub fn r_map_plane(y int, x1 int, x2 int) {
	_ = y
	_ = x1
	_ = x2
}

pub fn r_make_spans(x int, t1 int, b1 int, t2 int, b2 int) {
	_ = x
	_ = t1
	_ = b1
	_ = t2
	_ = b2
}

pub fn r_draw_planes() {}

pub fn r_find_plane(height Fixed, picnum int, lightlevel int) &Visplane {
	_ = height
	_ = picnum
	_ = lightlevel
	return unsafe { nil }
}

pub fn r_check_plane(pl &Visplane, start int, stop int) &Visplane {
	_ = pl
	_ = start
	_ = stop
	return unsafe { nil }
}
