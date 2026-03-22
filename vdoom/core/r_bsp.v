@[has_globals]
module core


struct Cliprange {
mut:
	first int
	last  int
}

__global (
	solidsegs = [128]Cliprange{}
	newend = 0
	curline = &Seg(unsafe { nil })
	frontsector = &Sector(unsafe { nil })
	backsector = &Sector(unsafe { nil })
	checkcoord = [12][4]int{} // V will init to 0s, we will populate in an init func
)

pub fn r_init_bsp() {
	if checkcoord.len < 12 { return }
	checkcoord[0] = [3, 0, 2, 1]!
	checkcoord[1] = [3, 0, 2, 0]!
	checkcoord[2] = [3, 1, 2, 0]!
	checkcoord[3] = [0, 0, 0, 0]!
	checkcoord[4] = [2, 0, 2, 1]!
	checkcoord[5] = [0, 0, 0, 0]!
	checkcoord[6] = [3, 1, 3, 0]!
	checkcoord[7] = [0, 0, 0, 0]!
	checkcoord[8] = [2, 0, 3, 1]!
	checkcoord[9] = [2, 1, 3, 1]!
	checkcoord[10] = [2, 1, 3, 0]!
	checkcoord[11] = [0, 0, 0, 0]!
}

pub fn r_clear_clip_segs() {
	if screenwidth <= 0 { return }
	if solidsegs.len < 2 { return }
	solidsegs[0].first = -2147483648
	solidsegs[0].last = -1
	solidsegs[1].first = screenwidth
	solidsegs[1].last = 2147483647
	newend = 2
}

pub fn r_clear_draw_segs() {
	ds_p = 0
}

pub fn r_clip_solid_wall_segment(first int, last int) {
	mut next := 0
	mut start := 0

	for next < solidsegs.len && solidsegs[next].last < first - 1 {
		next++
	}

	if next >= solidsegs.len { return }

	if first < solidsegs[next].first {
		if last < solidsegs[next].first - 1 {
			r_store_wall_range(first, last)
			if newend < solidsegs.len {
				solidsegs[newend].first = first
				solidsegs[newend].last = last
				newend++
				// Need to sort it into place.
				mut i := newend - 1
				for i > 0 && i < solidsegs.len && solidsegs[i].first < solidsegs[i - 1].first {
					solidsegs[i], solidsegs[i - 1] = solidsegs[i - 1], solidsegs[i]
					i--
				}
			}
			return
		}
		r_store_wall_range(first, solidsegs[next].first - 1)
		solidsegs[next].first = first
	}

	if last <= solidsegs[next].last {
		return
	}

	start = next

	mut crunched := false
	for next + 1 < solidsegs.len && last >= solidsegs[next + 1].first - 1 {
		r_store_wall_range(solidsegs[next].last + 1, solidsegs[next + 1].first - 1)
		next++
		if last <= solidsegs[next].last {
			solidsegs[start].last = solidsegs[next].last
			crunched = true
			break
		}
	}

	if !crunched {
		if next < solidsegs.len {
			r_store_wall_range(solidsegs[next].last + 1, last)
			solidsegs[start].last = last
		}
	}

	if next == start {
		return
	}

	for next < newend - 1 {
		next++
		start++
		if start < solidsegs.len && next < solidsegs.len {
			solidsegs[start] = solidsegs[next]
		}
	}
	newend = start + 1
}

pub fn r_clip_pass_wall_segment(first int, last int) {
	mut start := 0
	for start < solidsegs.len && solidsegs[start].last < first - 1 {
		start++
	}

	if start >= solidsegs.len { return }

	if first < solidsegs[start].first {
		if last < solidsegs[start].first - 1 {
			r_store_wall_range(first, last)
			return
		}
		r_store_wall_range(first, solidsegs[start].first - 1)
	}

	if last <= solidsegs[start].last {
		return
	}

	for start + 1 < solidsegs.len && last >= solidsegs[start + 1].first - 1 {
		r_store_wall_range(solidsegs[start].last + 1, solidsegs[start + 1].first - 1)
		start++
		if last <= solidsegs[start].last {
			return
		}
	}

	if start < solidsegs.len {
		r_store_wall_range(solidsegs[start].last + 1, last)
	}
}

pub fn r_add_line(line &Seg) {
	if voidptr(line) == unsafe { nil } { return }
	if voidptr(line.v1) == unsafe { nil } || voidptr(line.v2) == unsafe { nil } { return }

	unsafe {
		curline = line
	}

	// Use Fixed math for angle calculation to match C precisely
	mut angle1 := r_point_to_angle(line.v1.x, line.v1.y)
	mut angle2 := r_point_to_angle(line.v2.x, line.v2.y)

	// Check backface culling
	span := angle1 - angle2
	if span >= ang180 {
		return
	}

	rw_angle1 = int(angle1)
	angle1 -= viewangle
	angle2 -= viewangle

	clip := u32(clipangle)
	double_clip := clip * 2

	mut tspan := angle1 + clip
	if tspan > double_clip {
		tspan -= double_clip
		if tspan >= span {
			return
		}
		angle1 = clip
	}

	tspan = clip - angle2
	if tspan > double_clip {
		tspan -= double_clip
		if tspan >= span {
			return
		}
		angle2 = u32(0) - clip
	}

	mut idx1 := int((angle1 + ang90) >> u32(angle_to_fineshift))
	mut idx2 := int((angle2 + ang90) >> u32(angle_to_fineshift))

	if idx1 < 0 || idx1 >= viewangletox.len || idx2 < 0 || idx2 >= viewangletox.len {
		return
	}

	x1 := viewangletox[idx1]
	x2 := viewangletox[idx2]

	if x1 == x2 {
		return
	}

	unsafe {
		backsector = line.backsector
	}
	if backsector == unsafe { nil } {
		r_clip_solid_wall_segment(x1, x2 - 1)
		return
	}

	if frontsector == unsafe { nil } { return }

	if backsector.ceilingheight <= frontsector.floorheight || backsector.floorheight >= frontsector.ceilingheight {
		r_clip_solid_wall_segment(x1, x2 - 1)
		return
	}

	if backsector.ceilingheight != frontsector.ceilingheight || backsector.floorheight != frontsector.floorheight {
		r_clip_pass_wall_segment(x1, x2 - 1)
		return
	}

	if voidptr(line.sidedef) == unsafe { nil } { return }

	if backsector.ceilingpic == frontsector.ceilingpic && backsector.floorpic == frontsector.floorpic && backsector.lightlevel == frontsector.lightlevel && line.sidedef.midtexture == 0 {
		return
	}

	r_clip_pass_wall_segment(x1, x2 - 1)
}

pub fn r_check_bbox(bspcoord [4]Fixed) bool {
	mut boxx := 0
	mut boxy := 0

	if viewx <= bspcoord[0] { // BOXLEFT
		boxx = 0
	} else if viewx < bspcoord[1] { // BOXRIGHT
		boxx = 1
	} else {
		boxx = 2
	}

	if viewy >= bspcoord[2] { // BOXTOP
		boxy = 0
	} else if viewy > bspcoord[3] { // BOXBOTTOM
		boxy = 1
	} else {
		boxy = 2
	}

	boxpos := (boxy << 2) + boxx
	if boxpos == 5 {
		return true
	}

	if boxpos < 0 || boxpos >= checkcoord.len { return true }

	x1 := bspcoord[checkcoord[boxpos][0]]
	y1 := bspcoord[checkcoord[boxpos][1]]
	x2 := bspcoord[checkcoord[boxpos][2]]
	y2 := bspcoord[checkcoord[boxpos][3]]

	mut angle1 := r_point_to_angle(x1, y1) - viewangle
	mut angle2 := r_point_to_angle(x2, y2) - viewangle

	span := angle1 - angle2
	if span >= ang180 {
		return true
	}

	clip := u32(clipangle)
	double_clip := clip * 2

	mut tspan := angle1 + clip
	if tspan > double_clip {
		tspan -= double_clip
		if tspan >= span {
			return false
		}
		angle1 = clip
	}

	tspan = clip - angle2
	if tspan > double_clip {
		tspan -= double_clip
		if tspan >= span {
			return false
		}
		angle2 = u32(0) - clip
	}

	idx1 := int((angle1 + ang90) >> u32(angle_to_fineshift))
	idx2 := int((angle2 + ang90) >> u32(angle_to_fineshift))
	
	if idx1 < 0 || idx1 >= viewangletox.len || idx2 < 0 || idx2 >= viewangletox.len {
		return true
	}

	sx1 := viewangletox[idx1]
	mut sx2 := viewangletox[idx2]

	if sx1 == sx2 {
		return false
	}
	sx2--

	mut start := 0
	for start < solidsegs.len && solidsegs[start].last < sx2 {
		start++
	}

	if start >= solidsegs.len { return true }

	if sx1 >= solidsegs[start].first && sx2 <= solidsegs[start].last {
		return false
	}

	return true
}

pub fn r_subsector(num int) {
	if num < 0 || num >= numsubsectors || num >= subsectors.len {
		return
	}
	sub := &subsectors[num]
	if voidptr(sub) == unsafe { nil } { return }
	unsafe {
		frontsector = sub.sector
	}
	
	if frontsector == unsafe { nil } { return }

	if frontsector.floorheight < viewz {
		floorplane = r_find_plane(frontsector.floorheight, int(frontsector.floorpic), int(frontsector.lightlevel))
	} else {
		floorplane = unsafe { nil }
	}

	if frontsector.ceilingheight > viewz || frontsector.ceilingpic == 0 {
		ceilingplane = r_find_plane(frontsector.ceilingheight, int(frontsector.ceilingpic), int(frontsector.lightlevel))
	} else {
		ceilingplane = unsafe { nil }
	}

	r_add_sprites(frontsector)

	for i in 0 .. sub.numlines {
		idx := sub.firstline + i
		if idx < 0 || idx >= segs.len { continue }
		line := &segs[idx]
		r_add_line(line)
	}
}

pub fn r_render_bsp_node(bspnum int) {
	if (bspnum & nf_subsector) != 0 {
		if bspnum == -1 {
			r_subsector(0)
		} else {
			r_subsector(bspnum & ~nf_subsector)
		}
		return
	}

	if bspnum < 0 || bspnum >= nodes.len { return }

bsp := &nodes[bspnum]
	if voidptr(bsp) == unsafe { nil } { return }
	side := r_point_on_side(viewx, viewy, bsp)

	r_render_bsp_node(int(bsp.children[side]))

	if r_check_bbox(bsp.bbox[side ^ 1]) {
		r_render_bsp_node(int(bsp.children[side ^ 1]))
	}
}
