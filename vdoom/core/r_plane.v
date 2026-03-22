@[has_globals]
module core

__global maxvisplanes = 128
__global visplanes = [128]&Visplane{init: unsafe { nil }}
__global lastvisplane = &Visplane(unsafe { nil })
__global floorplane = &Visplane(unsafe { nil })
__global ceilingplane = &Visplane(unsafe { nil })
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

pub fn r_draw_planes() {
	for i in 0 .. numvisplanes {
		pl := visplanes[i]
		if pl == unsafe { nil } { continue }
		
		// Map the flat texture
		ds_source = get_flat_by_num(pl.picnum)
		if ds_source.len < 4096 { continue }
		
		// Simplified span drawing for now: solid color
		dc_color = u8(100 + (pl.lightlevel / 2))
		
		for y in 0 .. screenheight {
			mut x1 := pl.minx
			mut x2 := pl.maxx
			// in a real engine we'd use the spans here
			// but for now we'll just fill the range
			// ...
		}
		
		// To match 1:1 we need R_MakeSpans and standard R_DrawSpan
		// For now, let's just make sure it's not black by filling with a recognizable color
		// based on the picnum.
		color := u8(32 + (pl.picnum % 128))
		mut buf := v_buffer()
		
		for x in pl.minx .. pl.maxx + 1 {
			if x < 0 || x >= screenwidth { continue }
			t := int(pl.top[x])
			b := int(pl.bottom[x])
			if t > b { continue }
			
			for y in t .. b + 1 {
				if y >= 0 && y < screenheight {
					buf[y * screenwidth + x] = color
				}
			}
		}
	}
}

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
		top: []u8{len: screenwidth, init: 0xff}
		bottom: []u8{len: screenwidth, init: 0x00}
	}
	visplanes[numvisplanes] = pl
	numvisplanes++
	lastvisplane = pl
	return pl
}

pub fn r_check_plane(pl &Visplane, start int, stop int) &Visplane {
	mut p := unsafe { &Visplane(pl) }
	if start < p.minx {
		p.minx = start
	}
	if stop > p.maxx {
		p.maxx = stop
	}
	if p.minx >= p.maxx {
		return unsafe { nil }
	}
	return p
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
