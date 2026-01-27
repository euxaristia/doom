@[has_globals]
module core

// Constants
pub const float_speed = frac_unit * 4
pub const maxhealth = 100
pub const viewheight = 41 * frac_unit
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

pub struct Thinker {
pub mut:
	next &Thinker = unsafe { nil }
	prev &Thinker = unsafe { nil }
}

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

// P_TICK
pub fn p_init_thinkers() {}
pub fn p_add_thinker(thinker &Thinker) { _ = thinker }
pub fn p_remove_thinker(thinker &Thinker) { _ = thinker }

// P_PSPR
pub fn p_setup_psprites(curplayer voidptr) { _ = curplayer }
pub fn p_move_psprites(curplayer voidptr) { _ = curplayer }
pub fn p_drop_weapon(player voidptr) { _ = player }

// P_USER
pub fn p_player_think(player voidptr) { _ = player }

// P_MOBJ
pub fn p_respawn_specials() {}
pub fn p_spawn_mobj(x Fixed, y Fixed, z Fixed, typ int) voidptr { _ = x; _ = y; _ = z; _ = typ; return unsafe { nil } }
pub fn p_remove_mobj(th voidptr) { _ = th }
pub fn p_subst_null_mobj(th voidptr) voidptr { _ = th; return unsafe { nil } }
pub fn p_set_mobj_state(mobj voidptr, state int) bool { _ = mobj; _ = state; return false }
pub fn p_mobj_thinker(mobj voidptr) { _ = mobj }
pub fn p_spawn_puff(x Fixed, y Fixed, z Fixed) { _ = x; _ = y; _ = z }
pub fn p_spawn_blood(x Fixed, y Fixed, z Fixed, damage int) { _ = x; _ = y; _ = z; _ = damage }
pub fn p_spawn_missile(source voidptr, dest voidptr, typ int) voidptr { _ = source; _ = dest; _ = typ; return unsafe { nil } }
pub fn p_spawn_player_missile(source voidptr, typ int) { _ = source; _ = typ }

// P_ENEMY
pub fn p_noise_alert(target voidptr, emmiter voidptr) { _ = target; _ = emmiter }

// P_MAPUTL
pub fn p_aprox_distance(dx Fixed, dy Fixed) Fixed { _ = dx; _ = dy; return Fixed(0) }
pub fn p_point_on_line_side(x Fixed, y Fixed, line voidptr) int { _ = x; _ = y; _ = line; return 0 }
pub fn p_point_on_divline_side(x Fixed, y Fixed, line &DivLine) int { _ = x; _ = y; _ = line; return 0 }
pub fn p_make_divline(li voidptr, dl &DivLine) { _ = li; _ = dl }
pub fn p_intercept_vector(v2 &DivLine, v1 &DivLine) Fixed { _ = v2; _ = v1; return Fixed(0) }
pub fn p_box_on_line_side(tmbox []Fixed, ld voidptr) int { _ = tmbox; _ = ld; return 0 }
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
pub fn p_check_sight(t1 voidptr, t2 voidptr) bool { _ = t1; _ = t2; return false }
pub fn p_use_lines(player voidptr) { _ = player }
pub fn p_change_sector(sector voidptr, crunch bool) bool { _ = sector; _ = crunch; return false }
pub fn p_aim_line_attack(t1 voidptr, angle int, distance Fixed) Fixed { _ = t1; _ = angle; _ = distance; return Fixed(0) }
pub fn p_line_attack(t1 voidptr, angle int, distance Fixed, slope Fixed, damage int) { _ = t1; _ = angle; _ = distance; _ = slope; _ = damage }
pub fn p_radius_attack(spot voidptr, source voidptr, damage int) { _ = spot; _ = source; _ = damage }

// P_INTER
pub fn p_touch_special_thing(special voidptr, toucher voidptr) { _ = special; _ = toucher }
pub fn p_damage_mobj(target voidptr, inflictor voidptr, source voidptr, damage int) { _ = target; _ = inflictor; _ = source; _ = damage }
