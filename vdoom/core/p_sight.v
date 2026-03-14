module core

__global sightzstart = Fixed(0)
__global topslope = Fixed(0)
__global bottomslope = Fixed(0)
__global sightt2x = Fixed(0)
__global sightt2y = Fixed(0)
__global sightcounts = [0, 0]

pub fn p_check_sight_stub(t1 &Mobj, t2 &Mobj) bool {
	return p_check_sight(t1, t2)
}

pub fn p_check_sight(t1 &Mobj, t2 &Mobj) bool {
	if t1 == unsafe { nil } || t2 == unsafe { nil } {
		return false
	}
	if t1.subsector == unsafe { nil } || t2.subsector == unsafe { nil } {
		return false
	}
	t1_ss := unsafe { &Subsector(t1.subsector) }
	t2_ss := unsafe { &Subsector(t2.subsector) }
	if t1_ss.sector == unsafe { nil } || t2_ss.sector == unsafe { nil } {
		return false
	}
	
	sightcounts[1]++
	validcount++
	
	sightzstart = t1.z + t1.height - (t1.height >> 2)
	topslope = (t2.z + t2.height) - sightzstart
	bottomslope = t2.z - sightzstart
	
	sightt2x = t2.x
	sightt2y = t2.y
	
	trace.x = t1.x
	trace.y = t1.y
	trace.dx = t2.x - t1.x
	trace.dy = t2.y - t1.y
	
	return p_cross_bsp_node(numnodes - 1)
}

fn p_ptr_sight_traverse(intercept &Intercept) bool {
    li := unsafe { &Line(intercept.d.line) }
	
	p_line_opening(voidptr(li))
	
	if openbottom >= opentop {
		return false
	}
	
	if li.frontsector != unsafe { nil } && li.backsector != unsafe { nil } {
		if li.frontsector.floorheight != li.backsector.floorheight {
            slope := fixed_div(openbottom - sightzstart, intercept.frac)
			if slope > bottomslope {
				bottomslope = slope
			}
		}
		if li.frontsector.ceilingheight != li.backsector.ceilingheight {
            slope := fixed_div(opentop - sightzstart, intercept.frac)
			if slope < topslope {
				topslope = slope
			}
		}
	}
	
	if topslope <= bottomslope {
		return false
	}
	
	return true
}

fn p_sight_traverse_lines(x1 Fixed, y1 Fixed, x2 Fixed, y2 Fixed) bool {
	xl := (tmbbox[box_left] - bmaporgx) >> mapblockshift
	xh := (tmbbox[box_right] - bmaporgx) >> mapblockshift
	yl := (tmbbox[box_bottom] - bmaporgy) >> mapblockshift
	yh := (tmbbox[box_top] - bmaporgy) >> mapblockshift
	
	for bx := xl; bx <= xh; bx++ {
		for by := yl; by <= yh; by++ {
			if !p_block_lines_iterator(bx, by, p_sight_check_line) {
				return false
			}
		}
	}
	return true
}

pub fn p_sight_check_line(ln voidptr) bool {
	if ln == unsafe { nil } {
		return true
	}
	
	mut line := unsafe { &Line(ln) }
	
	if line.validcount == validcount {
		return true
	}
	line.validcount = validcount
	
	v1x := line.v1.x
	v1y := line.v1.y
	v2x := line.v2.x
	v2y := line.v2.y
	
	mut s1 := p_point_on_divline_side(v1x, v1y, &trace)
	mut s2 := p_point_on_divline_side(v2x, v2y, &trace)
	
	if s1 == s2 {
		return true
	}
	
	mut divl := DivLine{}
	divl.x = v1x
	divl.y = v1y
	divl.dx = v2x - v1x
	divl.dy = v2y - v1y
	
	s1 = p_point_on_divline_side(trace.x, trace.y, &divl)
	s2 = p_point_on_divline_side(sightt2x, sightt2y, &divl)
	
	if s1 == s2 {
		return true
	}
	
	if line.backsector == unsafe { nil } {
		return false
	}
	
	if line.flags & ml_twosided == 0 {
		return false
	}
	
	front := line.frontsector
	back := line.backsector
	
	if front == unsafe { nil } || back == unsafe { nil } {
		return true
	}
	
	if front.floorheight == back.floorheight && front.ceilingheight == back.ceilingheight {
		return true
	}
	
	if front.ceilingheight < back.ceilingheight {
		opentop = front.ceilingheight
	} else {
		opentop = back.ceilingheight
	}
	
	if front.floorheight > back.floorheight {
		openbottom = front.floorheight
	} else {
		openbottom = back.floorheight
	}
	
	if openbottom >= opentop {
		return false
	}
	
	frac := p_intercept_vector_impl(&trace, &divl)
	
	if front.floorheight != back.floorheight {
		slope := fixed_div(openbottom - sightzstart, frac)
		if slope > bottomslope {
			bottomslope = slope
		}
	}
	
	if front.ceilingheight != back.ceilingheight {
		slope := fixed_div(opentop - sightzstart, frac)
		if slope < topslope {
			topslope = slope
		}
	}
	
	if topslope <= bottomslope {
		return false
	}
	
	return true
}

pub fn p_cross_bsp_node(bspnum int) bool {
	if bspnum < 0 {
		return p_sight_traverse_lines(trace.x, trace.y, sightt2x, sightt2y)
	}
	
	node := &nodes[bspnum]
	
	side := p_point_on_divline_side(trace.x, trace.y, &DivLine{
		x: node.x
		y: node.y
		dx: node.dx
		dy: node.dy
	})
	
	mut front := true
	mut back := true
	
	if side == 1 {
		front = false
	} else if side == 0 {
		back = false
	}
	
	if front {
		if !p_check_box(node.bbox[0][0], node.bbox[0][1], node.bbox[0][2], node.bbox[0][3], p_cross_bsp_node) {
			return false
		}
	}
	
	if back {
		if !p_check_box(node.bbox[1][0], node.bbox[1][1], node.bbox[1][2], node.bbox[1][3], p_cross_bsp_node) {
			return false
		}
	}
	
	return true
}

fn p_check_box(box0 Fixed, box1 Fixed, box2 Fixed, box3 Fixed, check fn (int) bool) bool {
	tmbbox[box_top] = box0
	tmbbox[box_bottom] = box1
	tmbbox[box_left] = box2
	tmbbox[box_right] = box3
	
	mut xl := (tmbbox[box_left] - bmaporgx) >> mapblockshift
	mut xh := (tmbbox[box_right] - bmaporgx) >> mapblockshift
	mut yl := (tmbbox[box_bottom] - bmaporgy) >> mapblockshift
	mut yh := (tmbbox[box_top] - bmaporgy) >> mapblockshift
	
	if xl < 0 { xl = 0 }
	if yl < 0 { yl = 0 }
	if xh >= bmapwidth { xh = bmapwidth - 1 }
	if yh >= bmapheight { yh = bmapheight - 1 }
	
	for bx := xl; bx <= xh; bx++ {
		for by := yl; by <= yh; by++ {
			if !p_block_things_iterator(bx, by, p_sight_check_thing) {
				return false
			}
		}
	}
	
	return true
}

fn p_sight_check_thing(thing voidptr) bool {
	if thing == unsafe { nil } {
		return true
	}
	
	m := unsafe { &Mobj(thing) }
	
	if m == tmthing {
		return true
	}
	
	if (m.flags & (mf_solid | mf_shootable)) == 0 {
		return true
	}
	
	delta_x := abs(m.x - trace.x)
	delta_y := abs(m.y - trace.y)
	
	blockdist := m.radius
	
	if delta_x >= blockdist || delta_y >= blockdist {
		return true
	}
	
	return false
}

pub fn p_line_to_intercept(line &Line, p_x Fixed, p_y Fixed, p_z Fixed, p_dz Fixed) Fixed {
	_ = line
	_ = p_x
	_ = p_y
	_ = p_z
	_ = p_dz
	return Fixed(0)
}

pub fn p_sight_glob_z(z Fixed) bool {
	_ = z
	return true
}
