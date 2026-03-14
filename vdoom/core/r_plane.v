@[has_globals]
module core

__global maxvisplanes = 128
__global visplanes = []&Visplane{len: maxvisplanes}
__global lastvisplane &Visplane
__global floorplane &Visplane
__global ceilingplane &Visplane
__global numvisplanes = 0

__global lastopening = []i16{}

pub type PlaneFunction = fn (top int, bottom int)

__global floorfunc = PlaneFunction(unsafe { nil })
__global ceilingfunc = PlaneFunction(unsafe { nil })

__global floorclip = []i16{len: screenwidth}
__global ceilingclip = []i16{len: screenwidth}
__global yslope = []Fixed{len: screenheight}
__global distscale = []Fixed{len: screenwidth}

__global spanstart = []int{len: screenheight}
__global spanstop = []int{len: screenheight}

__global planezlight = []voidptr{}
__global planeheight = Fixed(0)

__global basexscale = Fixed(0)
__global baseyscale = Fixed(0)

__global cachedheight = []Fixed{len: screenheight}
__global cacheddistance = []Fixed{len: screenheight}
__global cachedxstep = []Fixed{len: screenheight}
__global cachedystep = []Fixed{len: screenheight}

pub fn r_init_planes() {
	for i in 0 .. screenwidth {
		floorclip[i] = screenheight
		ceilingclip[i] = -1
	}
}

pub fn r_clear_planes() {
	numvisplanes = 0
	lastvisplane = unsafe { nil }
	for i in 0 .. screenwidth {
		floorclip[i] = screenheight
		ceilingclip[i] = -1
	}
}

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
	for i in 0 .. numvisplanes {
		pl := visplanes[i]
		if pl.height == height && pl.picnum == picnum && pl.lightlevel == lightlevel {
			return pl
		}
	}
	if numvisplanes >= maxvisplanes {
		return unsafe { nil }
	}
	pl := &Visplane{
		height: height
		picnum: picnum
		lightlevel: lightlevel
		minx: screenwidth - 1
		maxx: 0
	}
	visplanes[numvisplanes] = pl
	numvisplanes++
	lastvisplane = pl
	return pl
}

pub fn r_check_plane(pl &Visplane, start int, stop int) &Visplane {
	if start < pl.minx {
		pl.minx = start
	}
	if stop > pl.maxx {
		pl.maxx = stop
	}
	if pl.minx >= pl.maxx {
		return unsafe { nil }
	}
	return pl
}

pub fn r_add_plane(sec &Sector, isfloor bool) {
	_ = sec
	_ = isfloor
}

pub fn r_check_z_plane(plane &Visplane, height Fixed) &Visplane {
	_ = plane
	_ = height
	return unsafe { nil }
}

pub fn r_draw_visible_plane(pl &Visplane) {
	_ = pl
}
