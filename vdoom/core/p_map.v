module core

const box_top = 0
const box_bottom = 1
const box_left = 2
const box_right = 3

__global tmthing &Mobj
__global tmflags int
__global tmx Fixed
__global tmy Fixed
__global tmbbox [4]Fixed
__global tmdropoffz Fixed

fn p_check_thing(thing &Mobj) bool {
	if thing == tmthing {
		return true
	}
	if (thing.flags & (u32(mf_solid) | u32(mf_special) | u32(mf_shootable))) == 0 {
		return true
	}
	blockdist := thing.radius + tmthing.radius
	if abs(thing.x - tmx) >= blockdist || abs(thing.y - tmy) >= blockdist {
		return true
	}
	return false
}

fn p_check_line(ld &Line) bool {
	if tmbbox[box_right] <= ld.bbox[box_left] || tmbbox[box_left] >= ld.bbox[box_right]
		|| tmbbox[box_top] <= ld.bbox[box_bottom] || tmbbox[box_bottom] >= ld.bbox[box_top] {
		return true
	}
	side := p_point_on_line_side(tmx, tmy, voidptr(ld))
	if side != -1 {
		return true
	}
	if ld.backsector == voidptr(0) {
		return false
	}
	if (tmflags & u32(mf_missile)) == 0 {
		if ld.flags & ml_blocking != 0 {
			return false
		}
		if tmthing != unsafe { nil } && (tmflags & u32(mf_momx)) == 0 && ld.flags & ml_blockmonsters != 0 {
			return false
		}
	}
	return true
}

pub fn p_check_position(thing &Mobj, x Fixed, y Fixed) bool {
	unsafe {
		tmthing = thing
		tmflags = thing.flags
	}
	tmx = x
	tmy = y
	tmbbox[box_top] = y + thing.radius
	tmbbox[box_bottom] = y - thing.radius
	tmbbox[box_right] = x + thing.radius
	tmbbox[box_left] = x - thing.radius
	ss := r_point_in_subsector(x, y)
	if ss == unsafe { nil } {
		return false
	}
	unsafe {
		ceilingline = voidptr(0)
	}
	tmfloorz = ss.sector.floorheight
	tmceilingz = ss.sector.ceilingheight
	tmdropoffz = ss.sector.floorheight
	validcount++
	numspechit = 0
	if tmflags & u32(mf_noclip) != 0 {
		return true
	}
	xl := (tmbbox[box_left] - bmaporgx - maxradius) >> mapblockshift
	xh := (tmbbox[box_right] - bmaporgx + maxradius) >> mapblockshift
	yl := (tmbbox[box_bottom] - bmaporgy - maxradius) >> mapblockshift
	yh := (tmbbox[box_top] - bmaporgy + maxradius) >> mapblockshift
	for bx := xl; bx <= xh; bx++ {
		for by := yl; by <= yh; by++ {
			if !p_block_things_iterator(bx, by, p_check_thing) {
				return false
			}
		}
	}
	xl = (tmbbox[box_left] - bmaporgx) >> mapblockshift
	xh = (tmbbox[box_right] - bmaporgx) >> mapblockshift
	yl = (tmbbox[box_bottom] - bmaporgy) >> mapblockshift
	yh = (tmbbox[box_top] - bmaporgy) >> mapblockshift
	for bx := xl; bx <= xh; bx++ {
		for by := yl; by <= yh; by++ {
			if !p_block_lines_iterator(bx, by, p_check_line) {
				return false
			}
		}
	}
	return true
}

pub fn p_try_move(thing &Mobj, x Fixed, y Fixed) bool {
	oldx := thing.x
	oldy := thing.y
	floatok = false
	if !p_check_position(thing, x, y) {
		return false
	}
	if (thing.flags & u32(mf_noclip)) == 0 {
		if tmceilingz - tmfloorz < thing.height {
			return false
		}
		floatok = true
		if (thing.flags & u32(mf_teleport)) == 0 && tmceilingz - thing.z < thing.height {
			return false
		}
		if (thing.flags & u32(mf_teleport)) == 0 && tmfloorz - thing.z > 24 * frac_unit {
			return false
		}
		if (thing.flags & (u32(mf_dropoff) | u32(mf_float))) == 0
			&& tmfloorz - tmdropoffz > 24 * frac_unit {
			return false
		}
	}
	p_unset_thing_position_impl(thing)
	unsafe {
		thing.floorz = tmfloorz
		thing.ceilingz = tmceilingz
		thing.x = x
		thing.y = y
	}
	p_set_thing_position_impl(thing)
	if (thing.flags & (u32(mf_teleport) | u32(mf_noclip))) != 0 {
		return true
	}
	for numspechit > 0 {
		numspechit--
		ld := unsafe { &Line(spechit[numspechit]) }
		side := p_point_on_line_side(thing.x, thing.y, voidptr(ld))
		oldside := p_point_on_line_side(oldx, oldy, voidptr(ld))
		if side != oldside && ld.special != 0 {
			p_cross_special_line(ld, oldside, thing)
		}
	}
	return true
}

pub fn p_teleport_move(thing &Mobj, x Fixed, y Fixed) bool {
	oldx := thing.x
	oldy := thing.y
	tmx = x
	tmy = y
	tmbbox[box_top] = y + thing.radius
	tmbbox[box_bottom] = y - thing.radius
	tmbbox[box_right] = x + thing.radius
	tmbbox[box_left] = x - thing.radius
	ss := r_point_in_subsector(x, y)
	if ss == unsafe { nil } {
		return false
	}
	unsafe {
		ceilingline = voidptr(0)
	}
	tmfloorz = ss.sector.floorheight
	tmceilingz = ss.sector.ceilingheight
	tmdropoffz = ss.sector.floorheight
	validcount++
	numspechit = 0
	xl := (tmbbox[box_left] - bmaporgx - maxradius) >> mapblockshift
	xh := (tmbbox[box_right] - bmaporgx + maxradius) >> mapblockshift
	yl := (tmbbox[box_bottom] - bmaporgy - maxradius) >> mapblockshift
	yh := (tmbbox[box_top] - bmaporgy + maxradius) >> mapblockshift
	for bx := xl; bx <= xh; bx++ {
		for by := yl; by <= yh; by++ {
			if !p_block_things_iterator(bx, by, p_check_thing) {
				return false
			}
		}
	}
	p_unset_thing_position_impl(thing)
	unsafe {
		thing.floorz = tmfloorz
		thing.ceilingz = tmceilingz
		thing.x = x
		thing.y = y
		thing.interp = false
	}
	p_set_thing_position(voidptr(thing))
	return true
}

__global bestslidefrac Fixed
__global secondslidefrac Fixed
__global bestslideline &Line
__global secondslideline &Line
__global slidemo &Mobj
__global tmxmove Fixed
__global tmymove Fixed

fn p_hit_slide_line(ld &Line) {
	side := p_point_on_line_side(slidemo.x, slidemo.y, voidptr(ld))
	lineangle := if side == 0 { ld.angle } else { ld.angle + ang180 }
	moveangle := atan2(slidemo.momy, slidemo.momx)
	deltaangle := lineangle - moveangle
	if deltaangle > ang180 {
		deltaangle += ang360
	}
	if deltaangle < -ang180 {
		deltaangle += ang360
	}
	deltaangle = abs(deltaangle)
	if deltaangle > ang90 {
		deltaangle = ang180 - deltaangle
	}
	tmxmove = fixed_mul(p_aprox_distance(slidemo.momx, slidemo.momy), finecosine[deltaangle >> angletoscreen_shift])
	tmymove = fixed_mul(p_aprox_distance(slidemo.momx, slidemo.momy), finesine[deltaangle >> angletoscreen_shift])
	if moveangle + ang90 < ang180 {
		slidemo.momx = -tmymove
		slidemo.momy = tmxmove
	} else {
		slidemo.momx = tmymove
		slidemo.momy = -tmxmove
	}
}

fn p_slide_traverse(intercept &Intercept) bool {
    li := unsafe { &Line(intercept.d.line) }
	if li.backsector == voidptr(0) {
		return true
	}
	if p_box_on_line_side(tmbbox[0], tmbbox[1], tmbbox[2], tmbbox[3], voidptr(li)) != -1 {
		return true
	}
    if bestslideline == unsafe { nil } || intercept.frac < bestslidefrac {
        bestslidefrac = intercept.frac
		bestslideline = li
	}
	return true
}

pub fn p_slide_move(mo &Mobj) {
	leadx := if mo.momx > 0 { mo.x + mo.radius } else { mo.x - mo.radius }
	trailx := if mo.momx > 0 { mo.x - mo.radius } else { mo.x + mo.radius }
	leady := if mo.momy > 0 { mo.y + mo.radius } else { mo.y - mo.radius }
	traily := if mo.momy > 0 { mo.y - mo.radius } else { mo.y + mo.radius }
	slidemo = mo
	hitcount := 0
	for {
		hitcount++
		if hitcount == 3 {
			if !p_try_move(mo, mo.x, mo.y + mo.momy) {
				p_try_move(mo, mo.x + mo.momx, mo.y)
			}
			return
		}
		bestslidefrac = frac_unit + frac_unit
		bestslideline = unsafe { nil }
		p_path_traverse(leadx, leady, leadx + mo.momx, leady + mo.momy, 1,
			p_slide_traverse)
		p_path_traverse(trailx, leady, trailx + mo.momx, leady + mo.momy, 1,
			p_slide_traverse)
		p_path_traverse(leadx, traily, leadx + mo.momx, traily + mo.momy, 1,
			p_slide_traverse)
		if bestslidefrac > frac_unit {
			if !p_try_move(mo, mo.x, mo.y + mo.momy) {
				p_try_move(mo, mo.x + mo.momx, mo.y)
			}
			return
		}
		bestslidefrac -= 0x800
		if bestslidefrac > Fixed(0) {
			newx := fixed_mul(mo.momx, bestslidefrac)
			newy := fixed_mul(mo.momy, bestslidefrac)
			if !p_try_move(mo, mo.x + newx, mo.y + newy) {
				if !p_try_move(mo, mo.x, mo.y + mo.momy) {
					p_try_move(mo, mo.x + mo.momx, mo.y)
				}
				return
			}
		}
		bestslidefrac = frac_unit - (bestslidefrac + 0x800)
		if bestslidefrac > frac_unit {
			bestslidefrac = frac_unit
		}
		if bestslidefrac <= Fixed(0) {
			return
		}
		tmxmove = fixed_mul(mo.momx, bestslidefrac)
		tmymove = fixed_mul(mo.momy, bestslidefrac)
		p_hit_slide_line(bestslideline)
		mo.momx = tmxmove
		mo.momy = tmymove
		if !p_try_move(mo, mo.x + tmxmove, mo.y + tmymove) {
			continue
		}
		return
	}
}

pub fn p_thing_height_clip(thing &Mobj) bool {
	onfloor := thing.z == thing.floorz
	p_check_position(thing, thing.x, thing.y)
	thing.floorz = tmfloorz
	thing.ceilingz = tmceilingz
	if onfloor {
		thing.z = thing.floorz
	} else {
		if thing.z + thing.height > thing.ceilingz {
			thing.z = thing.ceilingz - thing.height
		}
	}
	if thing.ceilingz - thing.floorz < thing.height {
		return false
	}
	return true
}

pub fn p_cross_special_line(ld &Line, side int, thing &Mobj) {
	_ = ld
	_ = side
	_ = thing
}

pub fn p_check_position_impl(thing &Mobj, x Fixed, y Fixed) bool {
	return p_check_position(thing, x, y)
}

pub fn p_try_move_impl(thing &Mobj, x Fixed, y Fixed) bool {
	return p_try_move(thing, x, y)
}

pub fn p_teleport_move_impl(thing &Mobj, x Fixed, y Fixed) bool {
	return p_teleport_move(thing, x, y)
}

pub fn p_slide_move_impl(mo &Mobj) {
	p_slide_move(mo)
}

pub fn p_thing_height_clip_impl(thing &Mobj) bool {
	return p_thing_height_clip(thing)
}
