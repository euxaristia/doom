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
	_ = x
	_ = y
	_ = node
	return 0
}

pub fn r_point_on_seg_side(x Fixed, y Fixed, line &Seg) int {
	_ = x
	_ = y
	_ = line
	return 0
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
	_ = x
	_ = y
	return Fixed(0)
}

pub fn r_scale_from_global_angle(visangle int) Fixed {
	_ = visangle
	return Fixed(0)
}

pub fn r_point_in_subsector(x Fixed, y Fixed) &Subsector {
	_ = x
	_ = y
	return unsafe { nil }
}

pub fn r_add_point_to_box(x int, y int, mut box []Fixed) {
	_ = x
	_ = y
	_ = box
}

// Refresh/render entry points.
pub fn r_render_player_view(player voidptr) {
	_ = player
}

pub fn r_init() {}

pub fn r_set_view_size(blocks int, detail int) {
	_ = blocks
	_ = detail
}
