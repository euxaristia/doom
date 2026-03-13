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
	if bspnum < 0 {
		// Reached a subsector - render the segs
		r_render_subsector(bspnum)
		return
	}
	
	// Get the node
	node := &nodes[bspnum]
	
	// Determine which side of the node the viewer is on
	side := r_point_on_side(viewx, viewy, node)
	
	// Render the back side first, then front
	r_render_bsp_node(if side == 0 { node.children[1] } else { node.children[0] })
	r_render_bsp_node(if side == 0 { node.children[0] } else { node.children[1] })
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
		r_render_line(seg)
	}
}

fn r_render_line(seg &Seg) {
	// Calculate seg visibility
	// This is a simplified version - full renderer would do proper clipping
	
	// Get the linedef
	line := seg.linedef
	if line == unsafe { nil } {
		return
	}
	
	// Get the sector
	frontsector = line.frontsector
	
	// Draw a simple vertical line for now
	x := int(fixed_div(seg.v1.x - viewx, viewcos))
	if x < 0 || x >= screenwidth {
		return
	}
	
	// Simple wall rendering - draw a vertical line
	color := u8(108) // Gray wall color
	
	// Draw column
	for y := 0; y < screenheight; y++ {
		offset := y * screenwidth + x
		if offset >= 0 && offset < i_video_buffer.len {
			i_video_buffer[offset] = color
		}
	}
}
