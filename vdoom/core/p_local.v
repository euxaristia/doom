@[has_globals]
module core

// Constants
pub const float_speed = frac_unit * 4
pub const maxhealth = 100
pub const viewheight_fixed = 41 * frac_unit
pub const viewheight = 41
pub const centerview = 0
pub const no_center = 1
pub const tocenter = 8
pub const lookdir_min = -90
pub const lookdir_max = 90
pub const look_units = 3
pub const look_steps = 20
pub const maxbob = 0x100000
pub const mapblockunits = 128
pub const mapblocksize = mapblockunits * frac_unit
pub const mapblockshift = frac_bits + 7
pub const mapbmask = mapblocksize - 1
pub const mapbtofrac = mapblockshift - frac_bits
pub const playerradius = 16 * frac_unit
pub const maxradius = 32 * frac_unit
pub const gravity = frac_unit
pub const maxmove = 30 * frac_unit
pub const userange = 64 * frac_unit
pub const meeleerange = 64 * frac_unit
pub const missilerange = 32 * 64 * frac_unit
pub const basethreshold = 100
pub const onfloorz = int_min
pub const onceilingz = int_max
pub const itemquesize = 128
pub const maxintercepts_original = 128
pub const maxintercepts = maxintercepts_original + 61
pub const maxspecialcross = 20
pub const maxspecialcross_original = 8
pub const stop_speed = frac_unit
pub const coff = 1
pub const snum_sounds = 2

pub struct DivLine {
pub mut:
	x  Fixed
	y  Fixed
	dx Fixed
	dy Fixed
}

pub struct DdUnion {
pub mut:
	thing voidptr
	line  voidptr
	a     int
}

pub struct Intercept {
pub mut:
	frac   Fixed
	isaline bool
	d      DdUnion
}

pub type Traverser = fn (in &Intercept) bool

__global thinkercap = Thinker{}

__global itemrespawnque = []voidptr{len: itemquesize, init: unsafe { nil }}
__global itemrespawntime = []int{len: itemquesize}
__global iquehead = 0
__global iquetail = 0

__global intercepts = []Intercept{len: maxintercepts}
__global intercept_p = &Intercept(unsafe { nil })

__global opentop = Fixed(0)
__global openbottom = Fixed(0)
__global openrange = Fixed(0)
__global lowfloor = Fixed(0)

__global trace = DivLine{}

__global floatok = false
__global tmfloorz = Fixed(0)
__global tmceilingz = Fixed(0)

__global ceilingline = unsafe { nil }
__global spechit = []voidptr{len: maxspecialcross, init: unsafe { nil }}
__global numspechit = 0

__global linetarget = unsafe { nil }

__global rejectmatrix = []u8{}
__global blockmaplump = []i16{}
__global blockmap = []i16{}
__global bmapwidth = 0
__global bmapheight = 0
__global bmaporgx = Fixed(0)
__global bmaporgy = Fixed(0)
__global blocklinks = []voidptr{}

__global maxammo = []int{len: numammo}
__global clipammo = []int{len: numammo}

// P_TICK / thinker list management
pub fn p_init_thinkers() {
	thinkercap.removed = false
	thinkercap.next = &thinkercap
	thinkercap.prev = &thinkercap
}

pub fn p_add_thinker(mut thinker Thinker) {
	// Insert thinker at the end of the doubly-linked list.
	unsafe {
		thinker.removed = false
		thinkercap.prev.next = &thinker
		thinker.next = &thinkercap
		thinker.prev = thinkercap.prev
		thinkercap.prev = &thinker
	}
}

pub fn p_remove_thinker(mut thinker Thinker) {
	// Lazy removal; actual unlink happens during p_run_thinkers.
	thinker.removed = true
}

pub fn p_run_thinkers() {
	mut current := thinkercap.next
	for current != &thinkercap {
		mut next := current.next
		if current.removed {
			current.next.prev = current.prev
			current.prev.next = current.next
		} else if voidptr(current.function.acp1) != unsafe { nil } {
			current.function.acp1(current)
		}
		current = next
	}
}

// P_PSPR stubs - actual implementation in p_pspr.v

// P_USER stub - actual implementation in p_user.v

// P_MOBJ stubs - actual implementation in p_mobj.v

// P_ENEMY
pub fn p_noise_alert(target voidptr, emmiter voidptr) { _ = target; _ = emmiter }

// P_MAPUTL
pub fn p_aprox_distance(dx Fixed, dy Fixed) Fixed {
	return p_approx_distance(dx, dy)
}
pub fn p_point_on_line_side(x Fixed, y Fixed, line voidptr) int {
	if line == unsafe { nil } {
		return 0
	}
	ld := unsafe { &Line(line) }
	return p_point_on_line_side_impl(x, y, ld)
}
pub fn p_point_on_divline_side(x Fixed, y Fixed, line &DivLine) int {
	return p_point_on_divline_side_impl(x, y, line)
}
pub fn p_make_divline(li voidptr, dl &DivLine) {
	if li == unsafe { nil } {
		return
	}
	line := unsafe { &Line(li) }
	p_make_divline_impl(line, dl)
}
pub fn p_intercept_vector(v2 &DivLine, v1 &DivLine) Fixed {
	return p_intercept_vector_impl(v2, v1)
}
pub fn p_box_on_line_side(tmbox []Fixed, ld voidptr) int {
	if ld == unsafe { nil } {
		return 0
	}
	line := unsafe { &Line(ld) }
	return p_box_on_line_side_impl(tmbox, line)
}
pub fn p_line_opening(linedef voidptr) { _ = linedef }
pub fn p_block_lines_iterator(x int, y int, func fn (line voidptr) bool) bool { _ = x; _ = y; _ = func; return false }
pub fn p_block_things_iterator(x int, y int, func fn (mobj voidptr) bool) bool { _ = x; _ = y; _ = func; return false }
pub fn p_path_traverse(x1 Fixed, y1 Fixed, x2 Fixed, y2 Fixed, flags int, trav Traverser) bool {
	_ = x1; _ = y1; _ = x2; _ = y2; _ = flags; _ = trav
	return false
}
pub fn p_unset_thing_position(thing voidptr) { _ = thing }
pub fn p_set_thing_position(thing voidptr) { _ = thing }

// P_MAP
pub fn p_check_position(thing voidptr, x Fixed, y Fixed) bool { _ = thing; _ = x; _ = y; return false }
pub fn p_try_move(thing voidptr, x Fixed, y Fixed) bool { _ = thing; _ = x; _ = y; return false }
pub fn p_teleport_move(thing voidptr, x Fixed, y Fixed) bool { _ = thing; _ = x; _ = y; return false }
pub fn p_slide_move(mo voidptr) { _ = mo }
// p_check_sight is in p_sight.v

pub fn p_use_lines(player voidptr) { _ = player }
pub fn p_change_sector(sector voidptr, crunch bool) bool { _ = sector; _ = crunch; return false }
pub fn p_aim_line_attack(t1 voidptr, angle int, distance Fixed) Fixed { _ = t1; _ = angle; _ = distance; return Fixed(0) }
pub fn p_line_attack(t1 voidptr, angle int, distance Fixed, slope Fixed, damage int) { _ = t1; _ = angle; _ = distance; _ = slope; _ = damage }
pub fn p_radius_attack(spot voidptr, source voidptr, damage int) { _ = spot; _ = source; _ = damage }

// P_INTER stubs - actual implementation in p_inter.v
