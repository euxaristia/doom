@[has_globals]
module core

const mf_momx = 0x20000
const mf_momy = 0x40000

const ml_blocking = 0x1
const ml_blockmonsters = 0x8

__global tmthing &Mobj
__global tmflags int
__global tmx Fixed
__global tmy Fixed
__global tmbbox [4]Fixed
__global tmdropoffz Fixed

pub fn p_thing_height_clip(thing &Mobj) bool {
	_ = thing
	return true
}

pub fn p_check_thing2(thing &Mobj) bool {
	_ = thing
	return false
}

pub fn p_unblock_mobj(thing &Mobj) {
	_ = thing
}

pub fn p_block_linesearch(flags int, fn_n &int) {
	_ = flags
	_ = fn_n
}

pub fn p_block_thingssearch(flags int, fn_n &int) {
	_ = flags
	_ = fn_n
}

pub fn p_check_line_side(ld &Line, x Fixed, y Fixed) int {
	return p_point_on_line_side_impl(x, y, ld)
}

// p_check_line_blocking checks if a line blocks movement for the current tmthing.
fn p_check_line_blocking(ld &Line) bool {
	// Check bounding box first
	if tmbbox[box_right] <= ld.bbox[box_left]
		|| tmbbox[box_left] >= ld.bbox[box_right]
		|| tmbbox[box_top] <= ld.bbox[box_bottom]
		|| tmbbox[box_bottom] >= ld.bbox[box_top] {
		return true // doesn't intersect
	}
	bbox_slice := [tmbbox[0], tmbbox[1], tmbbox[2], tmbbox[3]]
	if p_box_on_line_side_impl(bbox_slice, ld) != -1 {
		return true // box is entirely on one side
	}

	// One-sided line (wall) always blocks
	if ld.backsector == unsafe { nil } {
		return false
	}
	// Check flags
	if (int(ld.flags) & ml_blocking) != 0 {
		return false
	}
	// Two-sided line: check gap
	front := ld.frontsector
	back := ld.backsector
	if front == unsafe { nil } || back == unsafe { nil } {
		return false
	}
	mut local_opentop := Fixed(0)
	mut local_openbottom := Fixed(0)
	mut local_lowfloor := Fixed(0)
	if front.ceilingheight < back.ceilingheight {
		local_opentop = front.ceilingheight
	} else {
		local_opentop = back.ceilingheight
	}
	if front.floorheight > back.floorheight {
		local_openbottom = front.floorheight
		local_lowfloor = back.floorheight
	} else {
		local_openbottom = back.floorheight
		local_lowfloor = front.floorheight
	}
	local_openrange := local_opentop - local_openbottom
	if local_openrange <= 0 {
		return false
	}
	// Check if thing fits through the gap
	if tmthing != unsafe { nil } {
		if local_opentop - tmthing.z < tmthing.height {
			return false // doesn't fit
		}
		if local_openbottom - tmthing.z > 24 * frac_unit {
			return false // too high a step
		}
		// Update floor/ceiling for the thing
		if local_opentop < tmceilingz {
			tmceilingz = local_opentop
		}
		if local_openbottom > tmfloorz {
			tmfloorz = local_openbottom
		}
		if local_lowfloor < tmdropoffz {
			tmdropoffz = local_lowfloor
		}
	}
	return true
}

pub fn p_check_position_impl(thing &Mobj, x Fixed, y Fixed) bool {
	tmthing = unsafe { &Mobj(thing) }
	tmx = x
	tmy = y
	radius := thing.radius
	if radius <= 0 {
		return true
	}
	tmbbox[box_top] = y + radius
	tmbbox[box_bottom] = y - radius
	tmbbox[box_right] = x + radius
	tmbbox[box_left] = x - radius

	// Set initial floor/ceiling from the destination subsector
	ss := r_point_in_subsector(x, y)
	if ss != unsafe { nil } && ss.sector != unsafe { nil } {
		tmfloorz = ss.sector.floorheight
		tmdropoffz = ss.sector.floorheight
		tmceilingz = ss.sector.ceilingheight
	}

	// Check lines in all blockmap cells the bounding box touches
	if bmapwidth <= 0 || bmapheight <= 0 || blockmap.len == 0 {
		return true
	}
	xl := int((tmbbox[box_left] - bmaporgx - maxradius) >> mapblockshift)
	xh := int((tmbbox[box_right] - bmaporgx + maxradius) >> mapblockshift)
	yl := int((tmbbox[box_bottom] - bmaporgy - maxradius) >> mapblockshift)
	yh := int((tmbbox[box_top] - bmaporgy + maxradius) >> mapblockshift)

	for bx := xl; bx <= xh; bx++ {
		for by := yl; by <= yh; by++ {
			if !p_block_lines_check(bx, by) {
				return false
			}
		}
	}
	return true
}

// p_block_lines_check iterates lines in a blockmap cell and checks for blocking.
fn p_block_lines_check(x int, y int) bool {
	if x < 0 || y < 0 || x >= bmapwidth || y >= bmapheight {
		return true
	}
	offset_idx := y * bmapwidth + x
	if offset_idx >= blockmap.len {
		return true
	}
	mut offset := int(blockmap[offset_idx])
	// offset indexes into blockmaplump; blockmap = blockmaplump[4..]
	// so blockmaplump[4+offset] is the start of the list
	// Convert: blockmap[offset_idx] gives the offset into blockmaplump from index 4
	// The list in blockmaplump starts with 0 (header) and ends with -1
	mut bml_idx := 4 + offset
	for {
		if bml_idx < 0 || bml_idx >= blockmaplump.len {
			break
		}
		idx := int(blockmaplump[bml_idx])
		if idx == -1 {
			break
		}
		bml_idx++
		if idx == 0 {
			continue
		}
		if idx < 0 || idx >= numlines {
			continue
		}
		if !p_check_line_blocking(&lines[idx]) {
			return false
		}
	}
	return true
}

pub fn p_try_move_impl(thing &Mobj, x Fixed, y Fixed) bool {
	floatok = false
	if !p_check_position_impl(thing, x, y) {
		return false
	}
	// Check ceiling height
	if tmceilingz - tmfloorz < thing.height {
		return false
	}
	// Step up check
	if tmfloorz - thing.z > 24 * frac_unit {
		return false
	}
	// Valid move — update thing position
	floatok = true
	unsafe {
		thing.floorz = tmfloorz
		thing.ceilingz = tmceilingz
		thing.x = x
		thing.y = y
	}
	p_set_thing_position_impl(thing)
	return true
}

pub fn p_teleport_move_impl(thing &Mobj, x Fixed, y Fixed) bool {
	_ = thing
	_ = x
	_ = y
	return false
}

pub fn p_slide_move_impl(mo &Mobj) {
	_ = mo
}

pub fn p_thing_height_clip_impl(thing &Mobj) bool {
	_ = thing
	return true
}
