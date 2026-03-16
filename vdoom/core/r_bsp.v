@[has_globals]
module core

__global curline = &Seg(unsafe { nil })
__global sidedef = &Side(unsafe { nil })
__global linedef = &Line(unsafe { nil })
__global frontsector = &Sector(unsafe { nil })
__global backsector = &Sector(unsafe { nil })

__global rw_x = 0
__global rw_stopx = 0
__global segtextured = false
__global markfloor = false
__global markceiling = false
__global skymap = false

__global drawsegs &DrawSeg
__global ds_p &DrawSeg

__global hscalelight = []voidptr{}
__global vscalelight = []voidptr{}
__global dscalelight = []voidptr{}

// Debug counter for rendered segs
__global seg_render_count = 0

pub type DrawFunc = fn (start int, stop int)

pub fn r_clear_clip_segs() {}

pub fn r_clear_draw_segs() {
	validcount++
	ds_p = drawsegs
	seg_render_count = 0
}

pub fn r_init_bsp() {
	drawsegs = &DrawSeg(unsafe { nil })
	ds_p = &DrawSeg(unsafe { nil })
}

// NF_SUBSECTOR flag — bit 15 of a child index marks it as a subsector leaf.
const nf_subsector = u16(0x8000)

pub fn r_render_bsp_node(bspnum int) {
	if bspnum & int(nf_subsector) != 0 {
		ssec_idx := if bspnum == -1 { 0 } else { bspnum & int(~nf_subsector) }
		r_render_subsector(ssec_idx)
		return
	}

	if bspnum < 0 || bspnum >= numnodes {
		return
	}

	node := &nodes[bspnum]
	side := r_point_on_side(viewx, viewy, node)

	r_render_bsp_node(int(node.children[side]))

	if r_check_bbox(node.bbox[side ^ 1]) {
		r_render_bsp_node(int(node.children[side ^ 1]))
	}
}

fn r_check_bbox(bbox [4]Fixed) bool {
	_ = bbox
	return true
}

fn r_render_subsector(ssec_idx int) {
	if ssec_idx < 0 || ssec_idx >= numsubsectors {
		return
	}

	ssec := &subsectors[ssec_idx]
	first := int(ssec.firstline)
	count := int(ssec.numlines)

	if count == 0 {
		return
	}

	for i in 0 .. count {
		seg_idx := first + i
		if seg_idx >= numsegs {
			break
		}
		seg := &segs[seg_idx]
		r_render_seg(seg)
	}
}

// Debug counters
__global seg_total_calls = 0
__global seg_null_reject = 0
__global seg_behind_reject = 0
__global seg_offscreen_reject = 0

// r_render_seg projects a wall segment to screen space and draws it.
fn r_render_seg(seg &Seg) {
	seg_total_calls++

	if seg.v1 == unsafe { nil } || seg.v2 == unsafe { nil } {
		seg_null_reject++
		return
	}
	if seg.frontsector == unsafe { nil } {
		seg_null_reject++
		return
	}

	front := seg.frontsector

	// Transform vertices to view-relative coordinates
	wx1 := seg.v1.x - viewx
	wy1 := seg.v1.y - viewy
	wx2 := seg.v2.x - viewx
	wy2 := seg.v2.y - viewy

	sin := viewsin
	cos := viewcos

	// Rotate world-relative coords to view space.
	// Doom angle 0 faces east (+x). View-space: depth is forward, horiz is right.
	// depth  = wx * cos + wy * sin   (projection onto forward vector)
	// horiz  = wx * sin - wy * cos   (projection onto right vector)
	d1 := fixed_mul(wx1, cos) + fixed_mul(wy1, sin)
	h1 := fixed_mul(wx1, sin) - fixed_mul(wy1, cos)
	d2 := fixed_mul(wx2, cos) + fixed_mul(wy2, sin)
	h2 := fixed_mul(wx2, sin) - fixed_mul(wy2, cos)

	// Reject if both endpoints are behind the viewer
	near := Fixed(frac_unit / 4)
	if d1 < near && d2 < near {
		seg_behind_reject++
		return
	}

	// Clip to near plane
	mut cd1 := d1
	mut ch1 := h1
	mut cd2 := d2
	mut ch2 := h2

	if cd1 < near {
		dd := cd2 - cd1
		if dd == 0 {
			return
		}
		frac := fixed_div(near - cd1, dd)
		ch1 = ch1 + fixed_mul(frac, ch2 - ch1)
		cd1 = near
	}
	if cd2 < near {
		dd := cd1 - cd2
		if dd == 0 {
			return
		}
		frac := fixed_div(near - cd2, dd)
		ch2 = ch2 + fixed_mul(frac, ch1 - ch2)
		cd2 = near
	}

	// Project to screen x coordinates
	// screen_x = center + h * center / depth (using i64 to avoid overflow)
	half_w := screenwidth / 2
	sx1 := half_w + int(i64(ch1) * i64(half_w) / i64(cd1))
	sx2 := half_w + int(i64(ch2) * i64(half_w) / i64(cd2))

	// Ensure left-to-right ordering
	mut lx := sx1
	mut rx := sx2
	mut ld := cd1
	mut rd := cd2
	if lx > rx {
		lx, rx = rx, lx
		ld, rd = rd, ld
	}

	// Clip to screen
	if rx <= 0 || lx >= screenwidth {
		return
	}
	if lx < 0 {
		lx = 0
	}
	if rx >= screenwidth {
		rx = screenwidth - 1
	}
	if lx >= rx {
		return
	}

	seg_render_count++

	// Sector heights
	floor_h := front.floorheight
	ceil_h := front.ceilingheight

	has_back := seg.backsector != unsafe { nil }
	mut back := unsafe { &Sector(nil) }
	if has_back {
		back = seg.backsector
	}

	// Colors
	light := int(front.lightlevel)
	mut wall_color := u8(96)
	if light < 64 {
		wall_color = 0
	} else if light < 128 {
		wall_color = 96
	} else if light < 192 {
		wall_color = 100
	} else {
		wall_color = 104
	}
	floor_color := u8(int(front.floorpic) & 0x3f + 64)
	ceil_color := u8(int(front.ceilingpic) & 0x3f + 128)

	// Draw columns
	span := rx - lx
	if span <= 0 {
		return
	}

	half_h := screenheight / 2
	for x in lx .. rx {
		// Interpolate depth
		frac := if span > 1 { Fixed((x - lx) * frac_unit / span) } else { Fixed(0) }
		depth := ld + fixed_mul(frac, rd - ld)
		if depth <= 0 {
			continue
		}

		// Project heights to screen y
		// screen_y = center - (height - viewz) * center_x / depth
		ceil_sy := half_h - int(i64(ceil_h - viewz) * i64(half_w) / i64(depth))
		floor_sy := half_h - int(i64(floor_h - viewz) * i64(half_w) / i64(depth))

		// Clamp to clipping arrays
		clip_top := int(ceilingclip[x]) + 1
		clip_bot := int(floorclip[x]) - 1

		mut top := ceil_sy
		mut bot := floor_sy
		if top < clip_top {
			top = clip_top
		}
		if bot > clip_bot {
			bot = clip_bot
		}
		if top > bot {
			continue
		}

		if !has_back {
			// Solid wall — draw ceiling, wall, floor, then occlude
			if top > clip_top {
				dc_x = x
				dc_color = ceil_color
				dc_yl = clip_top
				dc_yh = top - 1
				r_draw_column()
			}

			dc_x = x
			dc_color = wall_color
			dc_yl = top
			dc_yh = bot
			r_draw_column()

			if bot < clip_bot {
				dc_x = x
				dc_color = floor_color
				dc_yl = bot + 1
				dc_yh = clip_bot
				r_draw_column()
			}

			// Fully occlude this column
			ceilingclip[x] = i16(clip_bot)
			floorclip[x] = i16(clip_top)
		} else {
			// Two-sided line (portal)
			back_floor := back.floorheight
			back_ceil := back.ceilingheight
			back_ceil_sy := half_h - int(i64(back_ceil - viewz) * i64(half_w) / i64(depth))
			back_floor_sy := half_h - int(i64(back_floor - viewz) * i64(half_w) / i64(depth))

			mut bt := back_ceil_sy
			mut bb := back_floor_sy
			if bt < clip_top {
				bt = clip_top
			}
			if bb > clip_bot {
				bb = clip_bot
			}

			// Upper wall (ceiling step)
			if bt > top {
				dc_x = x
				dc_color = ceil_color
				dc_yl = clip_top
				dc_yh = top - 1
				r_draw_column()

				dc_x = x
				dc_color = wall_color
				dc_yl = top
				dc_yh = bt - 1
				r_draw_column()

				ceilingclip[x] = i16(bt - 1)
			} else if top > clip_top {
				dc_x = x
				dc_color = ceil_color
				dc_yl = clip_top
				dc_yh = top - 1
				r_draw_column()
				ceilingclip[x] = i16(top - 1)
			}

			// Lower wall (floor step)
			if bb < bot {
				dc_x = x
				dc_color = wall_color
				dc_yl = bb + 1
				dc_yh = bot
				r_draw_column()

				dc_x = x
				dc_color = floor_color
				dc_yl = bot + 1
				dc_yh = clip_bot
				r_draw_column()

				floorclip[x] = i16(bb + 1)
			} else if bot < clip_bot {
				dc_x = x
				dc_color = floor_color
				dc_yl = bot + 1
				dc_yh = clip_bot
				r_draw_column()
				floorclip[x] = i16(bot + 1)
			}
		}
	}
}
