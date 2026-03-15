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

// NF_SUBSECTOR flag — bit 15 of a child index marks it as a subsector leaf.
const nf_subsector = u16(0x8000)

pub fn r_render_bsp_node(bspnum int) {
	// Check if this is a subsector (bit 15 set in the child value)
	if bspnum & int(nf_subsector) != 0 {
		ssec_idx := if bspnum == -1 { 0 } else { bspnum & int(~nf_subsector) }
		r_render_subsector(ssec_idx)
		return
	}

	if bspnum < 0 || bspnum >= numnodes {
		return
	}

	node := &nodes[bspnum]

	// Determine which side of the partition the viewer is on
	side := r_point_on_side(viewx, viewy, node)

	// Recursively render the front side (side the viewer is on)
	r_render_bsp_node(int(node.children[side]))

	// Only render the back side if its bounding box is potentially visible
	if r_check_bbox(node.bbox[side ^ 1]) {
		r_render_bsp_node(int(node.children[side ^ 1]))
	}
}

// r_check_bbox checks whether a bounding box is potentially visible.
// bbox layout: [0]=top, [1]=bottom, [2]=left, [3]=right (all Fixed, world coords).
fn r_check_bbox(bbox [4]Fixed) bool {
	// Simplified check: always return true to render everything.
	// A full implementation would clip against the view frustum and reject
	// bounding boxes that are entirely behind the viewer or fully occluded.
	// For correctness this is fine; for performance it means we traverse the
	// entire BSP tree every frame instead of culling invisible branches.
	_ = bbox
	return true
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
	// Rendering stub - returns without drawing to avoid crash
	// Full wall rendering needs proper implementation
	_ = seg
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
