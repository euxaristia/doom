@[has_globals]
module core

// POV-related globals.
__global viewcos = Fixed(0)
__global viewsin = Fixed(0)
__global viewwindowx = 0
__global viewwindowy = 0
__global centerx = 0
__global centery = 0
__global centerxfrac = Fixed(0)
__global centeryfrac = Fixed(0)
__global projection = Fixed(0)
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
	dx := x - node.x
	dy := y - node.y
	left := fixed_mul(node.dy >> frac_bits, dx)
	right := fixed_mul(dy, node.dx >> frac_bits)
	return if right < left { 0 } else { 1 }
}

pub fn r_point_on_seg_side(x Fixed, y Fixed, line &Seg) int {
	dx := x - line.v1.x
	dy := y - line.v1.y
	ldx := line.v2.x - line.v1.x
	ldy := line.v2.y - line.v1.y
	left := fixed_mul(ldy >> frac_bits, dx)
	right := fixed_mul(dy, ldx >> frac_bits)
	return if right < left { 0 } else { 1 }
}

pub fn r_point_to_angle(x Fixed, y Fixed) int {
	_ = x
	_ = y
	return 0
}

pub fn r_point_to_angle2(x1 Fixed, y1 Fixed, x2 Fixed, y2 Fixed) int {
	_ = x1
	_ = y1
	_ = x2
	_ = y2
	return 0
}

pub fn r_point_to_dist(x Fixed, y Fixed) Fixed {
	return p_approx_distance(x, y)
}

pub fn r_scale_from_global_angle(visangle int) Fixed {
	_ = visangle
	return Fixed(0)
}

pub fn r_point_in_subsector(x Fixed, y Fixed) &Subsector {
	if numnodes == 0 {
		return unsafe { &subsectors[0] }
	}
	mut nodenum := numnodes - 1
	for nodenum & int(nf_subsector) == 0 {
		node := &nodes[nodenum]
		side := r_point_on_side(x, y, node)
		nodenum = int(node.children[side])
	}
	ssidx := nodenum & int(~nf_subsector)
	if ssidx < 0 || ssidx >= numsubsectors {
		return unsafe { &subsectors[0] }
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
	if numnodes == 0 {
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
		viewangle = int(player.mo.angle)

		viewcos = fixed_cos(u32(viewangle))
		viewsin = fixed_sin(u32(viewangle))
	}

	// Initialize projection constants
	centerx = screenwidth / 2
	centerxfrac = Fixed(centerx << frac_bits)
	centeryfrac = Fixed((screenheight / 2) << frac_bits)
	projection = centerxfrac
}

pub fn r_init() {}

pub fn r_set_view_size(blocks int, detail int) {
	_ = blocks
	_ = detail
}
