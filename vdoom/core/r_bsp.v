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

pub type DrawFunc = fn (start int, stop int)

pub fn r_clear_clip_segs() {}

pub fn r_clear_draw_segs() {
	validcount++
	ds_p = drawsegs
}

pub fn r_init_bsp() {
	drawsegs = &DrawSeg(unsafe { nil })
	ds_p = &DrawSeg(unsafe { nil })
}

pub fn r_render_bsp_node(bspnum int) {
	if (bspnum & 0x8000) != 0 {
		// Reached a subsector - render the segs
		r_render_subsector(bspnum)
		return
	}
	
	// Get the node
	node := &nodes[bspnum]
	
	// Determine which side of the node the viewer is on
	side := r_point_on_side(viewx, viewy, node)
	
	// Render the back side first, then front
	// Cast children to i16 to handle sign bit correctly
	r_render_bsp_node(int(i16(if side == 0 { node.children[1] } else { node.children[0] })))
	r_render_bsp_node(int(i16(if side == 0 { node.children[0] } else { node.children[1] })))
}

fn r_render_subsector(bspnum int) {
	if bspnum > 0 {
		return // Not a subsector
	}
	
	// Get the subsector index (negative bspnum in original Doom)
	ssec_idx := -(bspnum + 1)
	if ssec_idx < 0 || ssec_idx >= numsubsectors {
		return
	}
	
	ssec := &subsectors[ssec_idx]
	
	// Render each seg in the subsector
	first := int(ssec.firstline)
	numlines := int(ssec.numlines)
	
	for i in 0 .. numlines {
		seg_idx := first + i
		if seg_idx >= numsegs {
			break
		}
		
		seg := &segs[seg_idx]
		r_render_seg(seg)
	}
}

fn r_render_seg(seg &Seg) {
	// Check if seg is visible
	// Calculate angles for view
	mut angle1 := int(seg.angle) - viewangle
	mut angle2 := int(seg.angle) + seg_angle(seg) - viewangle
	
	// Normalize angles to 0-359 range
	for angle1 < 0 {
		angle1 += 360
	}
	for angle1 >= 360 {
		angle1 -= 360
	}
	for angle2 < 0 {
		angle2 += 360
	}
	for angle2 >= 360 {
		angle2 -= 360
	}
	
	// Convert angles to screen x coordinates
	mut x1 := angle_to_x(angle1)
	mut x2 := angle_to_x(angle2)
	
	// Clip and draw
	if x1 < 0 {
		x1 = 0
	}
	if x2 >= screenwidth {
		x2 = screenwidth - 1
	}
	if x1 >= x2 {
		return
	}
	
	// Get sectors
	frontsector = seg.frontsector
	backsector = seg.backsector
	
	// Determine what to draw
	mut draw_wall := false
	mut draw_floor := false
	mut draw_ceiling := false
	
	if backsector == unsafe { nil } {
		// Solid wall
		draw_wall = true
		draw_floor = true
		draw_ceiling = true
	} else {
		// Check for differences
		if frontsector.floorheight != backsector.floorheight {
			draw_floor = true
		}
		if frontsector.ceilingheight != backsector.ceilingheight {
			draw_ceiling = true
		}
		// Check if we need to draw the wall texture
		if seg.sidedef != unsafe { nil } && seg.sidedef.midtexture >= 0 {
			draw_wall = true
		}
	}
	
	// Render the seg
	render_wall_column(seg, x1, x2, draw_wall, draw_floor, draw_ceiling)
}

fn seg_angle(seg &Seg) int {
	// Calculate angle from v1 to v2
	v1 := seg.v1
	v2 := seg.v2
	dx := v2.x - v1.x
	dy := v2.y - v1.y
	
	// Convert to angle using atan2 approximation
	// Doom uses angle_t = atan2(dy, dx) * (fine_angles / 360)
	// We'll use a simpler approach
	return int((fixed_atan2(dy, dx) * 45) >> frac_bits)
}

fn angle_to_x(angle int) int {
	// Convert angle to screen x coordinate
	// Simple linear mapping for now
	// Angles 0-90 map to left half, 90-180 to right half
	// We need a more sophisticated mapping based on FOV
	mut x := 0
	if angle <= 90 {
		x = (screenwidth / 2) - (angle * (screenwidth / 4) / 90)
	} else if angle <= 180 {
		x = (screenwidth / 2) + ((angle - 90) * (screenwidth / 4) / 90)
	} else if angle <= 270 {
		x = (screenwidth / 2) + ((angle - 180) * (screenwidth / 4) / 90)
	} else {
		x = (screenwidth / 2) - ((angle - 270) * (screenwidth / 4) / 90)
	}
	return x
}

fn render_wall_column(seg &Seg, x1 int, x2 int, draw_wall bool, draw_floor bool, draw_ceiling bool) {
	// Get wall heights from sector
	top_height := frontsector.ceilingheight
	bottom_height := frontsector.floorheight
	
	// Calculate screen y positions
	mut top_y := height_to_screen_y(top_height)
	mut bottom_y := height_to_screen_y(bottom_height)
	
	// Clip
	if top_y < 0 {
		top_y = 0
	}
	if bottom_y >= screenheight {
		bottom_y = screenheight - 1
	}
	
	// Determine colors based on wall/lighting
	wall_color := u8(108 + (frontsector.lightlevel >> 4))
	
	// Render for each x column
	for x in x1 .. x2 {
		if draw_ceiling {
			// Draw ceiling (black/sky)
			for y in 0 .. top_y {
				offset := y * screenwidth + x
				if offset >= 0 && offset < i_video_buffer.len {
					i_video_buffer[offset] = 0
				}
			}
		}
		
		if draw_wall {
			// Draw wall
			for y in top_y .. bottom_y {
				offset := y * screenwidth + x
				if offset >= 0 && offset < i_video_buffer.len {
					i_video_buffer[offset] = wall_color
				}
			}
		}
		
		if draw_floor {
			// Draw floor (darker)
			floor_color := u8(frontsector.lightlevel >> 3)
			for y in bottom_y .. screenheight {
				offset := y * screenwidth + x
				if offset >= 0 && offset < i_video_buffer.len {
					i_video_buffer[offset] = floor_color
				}
			}
		}
	}
}

fn height_to_screen_y(height Fixed) int {
	// Convert world height to screen y coordinate
	// viewz is viewer's eye height
	dist := viewz - height
	if dist <= 0 {
		return screenheight
	}
	
	// Simple perspective projection
	// y = center_y - (height_diff * scale) / dist
	scale := Fixed(50 * frac_unit) // Arbitrary scale factor
	projected := fixed_mul(scale, height)
	mut y := (screenheight / 2) - int(projected / dist)
	
	if y < 0 {
		y = 0
	}
	if y > screenheight {
		y = screenheight
	}
	return y
}

fn fixed_atan2(y Fixed, x Fixed) Fixed {
	// Simple fixed-point atan2
	// Returns angle in degrees (as Fixed)
	if x == 0 {
		if y >= 0 {
			return Fixed(90 * frac_unit)
		} else {
			return Fixed(270 * frac_unit)
		}
	}
	
	// Calculate ratio and approximate
	yf := int(y)
	xf := int(x)
	
	mut angle := 0
	if x > 0 {
		if y >= 0 {
			// Quadrant 1: 0-90 degrees
			angle = int((fixed_div(y, x) * 45) >> frac_bits)
		} else {
			// Quadrant 4: 270-360 degrees
			angle = 360 - int((fixed_div(-y, x) * 45) >> frac_bits)
		}
	} else {
		if y >= 0 {
			// Quadrant 2: 90-180 degrees
			angle = 180 - int((fixed_div(y, -x) * 45) >> frac_bits)
		} else {
			// Quadrant 3: 180-270 degrees
			angle = 180 + int((fixed_div(-y, -x) * 45) >> frac_bits)
		}
	}
	
	return Fixed(angle * frac_unit)
}
