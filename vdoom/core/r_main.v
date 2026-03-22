@[has_globals]
module core

import math

// POV-related globals.
__global viewcos = Fixed(0)
__global viewsin = Fixed(0)
__global viewwindowx = 0
__global viewwindowy = 0
__global v_centerx = 0
__global v_centery = 0
__global centerxfrac = Fixed(0)
__global centeryfrac = Fixed(0)
__global projection = Fixed(0)
__global projectiony = Fixed(0)
__global validcount = 0
__global linecount = 0
__global loopcount = 0

// Lighting constants.
pub const lightlevels = 16
pub const lightsegshift = 4
pub const maxlightscale = 48
pub const lightscaleshift = 12
pub const maxlightz = 128
pub const lightzshift = 20
pub const numcolormaps = 32
pub const nf_subsector = 32768

// Lighting LUT placeholders.
__global scalelight = [][][]voidptr{len: lightlevels, init: [][]voidptr{len: maxlightscale, init: unsafe { nil }}}
__global scalelightfixed = []voidptr{len: maxlightscale, init: unsafe { nil }}
__global zlight = [][][]voidptr{len: lightlevels, init: [][]voidptr{len: maxlightz, init: unsafe { nil }}}

__global extralight = 0
__global fixedcolormap = unsafe { nil }
__global detailshift = 0

// Function pointer hooks.
pub type ColFunc = fn ()
__global colfunc = ColFunc(unsafe { nil })
__global transcolfunc = ColFunc(unsafe { nil })
__global basecolfunc = ColFunc(unsafe { nil })
__global fuzzcolfunc = ColFunc(unsafe { nil })
__global spanfunc = ColFunc(unsafe { nil })

// Utility functions.
pub fn r_point_on_side(x Fixed, y Fixed, node &Node) int {
	dx := i64(x) - node.x
	dy := i64(y) - node.y
	left := i64(node.dy >> frac_bits) * dx
	right := dy * i64(node.dx >> frac_bits)
	return if right < left { 0 } else { 1 }
}

pub fn r_point_on_seg_side(x Fixed, y Fixed, line &Seg) int {
	dx := i64(x) - line.v1.x
	dy := i64(y) - line.v1.y
	ldx := i64(line.v2.x) - line.v1.x
	ldy := i64(line.v2.y) - line.v1.y
	left := i64(ldy >> frac_bits) * dx
	right := dy * i64(ldx >> frac_bits)
	return if right < left { 0 } else { 1 }
}

pub fn r_point_to_angle(x Fixed, y Fixed) u32 {
	angle_rad := math.atan2(f64(y - viewy), f64(x - viewx))
	if math.is_nan(angle_rad) || math.is_inf(angle_rad, 0) {
		return 0
	}
	return u32(i64(angle_rad * 0x80000000 / math.pi))
}

pub fn r_point_to_angle2(x1 Fixed, y1 Fixed, x2 Fixed, y2 Fixed) u32 {
	angle_rad := math.atan2(f64(y2 - y1), f64(x2 - x1))
	if math.is_nan(angle_rad) || math.is_inf(angle_rad, 0) {
		return 0
	}
	return u32(i64(angle_rad * 0x80000000 / math.pi))
}

pub fn r_point_to_dist(x Fixed, y Fixed) Fixed {
	dx := f64(x - viewx)
	dy := f64(y - viewy)
	res := math.sqrt(dx * dx + dy * dy)
	if math.is_nan(res) || math.is_inf(res, 0) {
		return Fixed(0)
	}
	return Fixed(i32(res))
}

pub fn r_scale_from_global_angle(visangle u32) Fixed {
	angle := f64(i32(visangle - viewangle)) * math.pi / 0x80000000
	cos_ang := math.cos(angle)
	if math.abs(cos_ang) < 0.0001 || math.is_nan(cos_ang) {
		return int_max
	}
	
	// Ensure rw_distance is not 0 to avoid division by zero
	dist := if rw_distance == 0 { Fixed(1) } else { rw_distance }
	s := f64(projection) / (f64(dist) * cos_ang / f64(frac_unit))
	if math.is_nan(s) || math.is_inf(s, 0) {
		return int_max
	}
	return Fixed(i32(s))
}

pub fn r_point_in_subsector(x Fixed, y Fixed) &Subsector {
	if numnodes <= 0 || nodes.len == 0 {
		if subsectors.len > 0 {
			return unsafe { &subsectors[0] }
		}
		return unsafe { nil }
	}
	mut nodenum := numnodes - 1
	for (nodenum & nf_subsector) == 0 {
		if nodenum < 0 || nodenum >= nodes.len { break }
		node := &nodes[nodenum]
		side := r_point_on_side(x, y, node)
		nodenum = int(node.children[side])
	}
	ssidx := nodenum & ~nf_subsector
	if ssidx < 0 || ssidx >= numsubsectors || ssidx >= subsectors.len {
		if subsectors.len > 0 {
			return unsafe { &subsectors[0] }
		}
		return unsafe { nil }
	}
	return unsafe { &subsectors[ssidx] }
}

pub fn r_add_point_to_box(x int, y int, mut box []Fixed) {
	_ = x
	_ = y
	_ = box
}

// Refresh/render entry points.
pub fn r_render_player_view(player voidptr) {
	if voidptr(player) == unsafe { nil } {
		return
	}
	p := unsafe { &Player(player) }

	if p.mo == unsafe { nil } {
		return
	}

	// Setup the view frame
	r_setup_frame(p)

	// Clear the screen to a dark color before rendering
	v_clear_screen(0)

	// Clear buffers
	r_clear_clip_segs()
	r_clear_draw_segs()
	r_clear_planes()
	r_clear_sprites()

	// Render the world
	if numnodes <= 0 || nodes.len == 0 {
		i_finish_update()
		return
	}

	// Render the BSP tree (walls, floors, ceilings)
	r_render_bsp_node(numnodes - 1)

	// Draw floors and ceilings (handled inline during BSP traversal)
	r_draw_planes()

	// Draw masked elements (sprites, etc)
	r_draw_masked()

	i_finish_update()
}

fn r_setup_frame(player &Player) {
	unsafe {
		viewx = player.mo.x
		viewy = player.mo.y
		viewz = player.viewz
		viewangle = player.mo.angle

		viewcos = Fixed(i32(f64(frac_unit) * math.cos(f64(viewangle) * math.pi / 0x80000000)))
		viewsin = Fixed(i32(f64(frac_unit) * math.sin(f64(viewangle) * math.pi / 0x80000000)))
	}

	// Initialize projection constants
	v_centerx = screenwidth / 2
	v_centery = screenheight / 2
	centerxfrac = Fixed(v_centerx << frac_bits)
	centeryfrac = Fixed(v_centery << frac_bits)
	projection = centerxfrac
	projectiony = centeryfrac

	// Initialize tables if needed
	r_init_tables()
}

__global (
	tables_inited = false
)

fn r_init_tables() {
	if tables_inited && xtoviewangle.len == screenwidth + 1 && viewangletox.len == fine_angles_half {
		return
	}

	// Initialize sine/cosine tables first (needed by tangent and other lookups).
	if finesine.len != 10240 {
		finesine = []Fixed{len: 10240}
		for i in 0 .. 10240 {
			finesine[i] = Fixed(i32(f64(frac_unit) * math.sin(f64(i) * math.pi * 2.0 / 8192.0)))
		}
		finecosine = finesine[2048..].clone()
	}

	if finetangent.len != fine_angles_half {
		finetangent = []Fixed{len: fine_angles_half}
		for i in 0 .. fine_angles_half {
			angle_rad := (f64(i) - 2048.0) * math.pi * 2.0 / 8192.0
			tan_val := math.tan(angle_rad)
			if math.is_nan(tan_val) || math.is_inf(tan_val, 0) {
				finetangent[i] = Fixed(0)
			} else {
				finetangent[i] = Fixed(i32(f64(frac_unit) * tan_val))
			}
		}
	}

	// xtoviewangle: screen column to relative view angle (BAM).
	if xtoviewangle.len != screenwidth + 1 {
		xtoviewangle = []int{len: screenwidth + 1}
	}
	for i in 0 .. screenwidth + 1 {
		angle_rad := math.atan2(f64(v_centerx - i), f64(v_centerx))
		if math.is_nan(angle_rad) || math.is_inf(angle_rad, 0) {
			xtoviewangle[i] = 0
		} else {
			xtoviewangle[i] = int(u32(i64(angle_rad * 2147483648.0 / math.pi)))
		}
	}

	// viewangletox: fine-angle index → screen column.
	// Uses the tangent-based approach from R_InitTextureMapping in Doom.
	// focallength = centerxfrac (since tan(FOV/2) = tan(45°) = 1.0).
	focallength := i64(centerxfrac)
	if viewangletox.len != fine_angles_half {
		viewangletox = []int{len: fine_angles_half}
	}
	for i in 0 .. fine_angles_half {
		tan_v := i64(finetangent[i])
		if tan_v > i64(frac_unit) * 2 {
			viewangletox[i] = -1
		} else if tan_v < -i64(frac_unit) * 2 {
			viewangletox[i] = screenwidth + 1
		} else {
			t := (tan_v * focallength) >> frac_bits
			mut x := int((i64(centerxfrac) - t + i64(frac_unit) - 1) >> frac_bits)
			if x < -1 {
				x = -1
			} else if x > screenwidth + 1 {
				x = screenwidth + 1
			}
			viewangletox[i] = x
		}
	}

	// clipangle is the view angle at the leftmost screen column (half-FOV).
	clipangle = xtoviewangle[0]

	tables_inited = true
}

pub fn r_init() {
	v_centerx = screenwidth / 2
	v_centery = screenheight / 2
	centerxfrac = Fixed(v_centerx << frac_bits)
	centeryfrac = Fixed(v_centery << frac_bits)
	projection = centerxfrac
	projectiony = centeryfrac

	r_init_bsp()
	r_init_segs()
	r_init_tables()
}

pub fn r_set_view_size(blocks int, detail int) {
	_ = blocks
	_ = detail
}
