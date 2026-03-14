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
	// Check if this is a subsector (stored as negative i16 in original Doom)
	// When child is read as i16 from WAD, negative values indicate subsectors
	if bspnum < 0 {
		// This is a subsector - convert negative i16 to subsector index
		// In Doom: ssec_idx = -(child_i16 + 1)
		ssec_idx := -(bspnum + 1)
		r_render_subsector(ssec_idx)
		return
	}
	
	// Not a subsector - it's a node
	if bspnum < 0 || bspnum >= numnodes {
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

fn r_render_subsector(ssec_idx int) {
	if ssec_idx < 0 || ssec_idx >= numsubsectors {
		return
	}
	
	ssec := &subsectors[ssec_idx]
	
	// Render each seg in the subsector
	first := int(ssec.firstline)
	numlines := int(ssec.numlines)
	
	if numlines == 0 {
		return
	}
	
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
	// Get sectors
	frontsector = seg.frontsector
	
	if frontsector == unsafe { nil } {
		return
	}
	
	// Simple test: use seg angle to draw
	// seg.angle is the angle of the seg in the view
	angle := seg.angle
	
	// Normalize to 0-360
	mut norm_angle := angle
	for norm_angle < 0 {
		norm_angle += 360
	}
	for norm_angle >= 360 {
		norm_angle -= 360
	}
	
	// Map angle to screen x coordinate (simple projection)
	screenx := int(f32(norm_angle) / 360.0 * f32(screenwidth))
	
	// Color based on sector lighting
	color := u8(frontsector.lightlevel)
	
	// Draw a vertical line at this x position
	if screenx >= 0 && screenx < screenwidth {
		for y := 0; y < screenheight; y++ {
			offset := y * screenwidth + screenx
			if offset >= 0 && offset < i_video_buffer.len {
				i_video_buffer[offset] = color
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
