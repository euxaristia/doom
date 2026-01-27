@[has_globals]
module core

// End-level timer (-TIMER option)
__global level_timer = false
__global level_time_count = 0

pub fn p_start_level_timer(minutes int) {
	if minutes <= 0 {
		level_timer = false
		level_time_count = 0
		return
	}
	level_timer = true
	level_time_count = minutes * 60 * ticrate
}

pub fn p_stop_level_timer() {
	level_timer = false
	level_time_count = 0
}

// Define values for map objects
pub const mo_teleportman = 14

// At game start / map load / every tic
pub fn p_init_pic_anims() {}
pub fn p_spawn_specials() {}
pub fn p_update_specials() {}

// Line/sector interactions
pub fn p_use_special_line(thing &Mobj, line &Line, side int) bool {
	_ = thing
	_ = line
	_ = side
	return false
}

pub fn p_shoot_special_line(thing &Mobj, line &Line) {
	_ = thing
	_ = line
}

pub fn p_cross_special_line(linenum int, side int, thing &Mobj) {
	_ = linenum
	_ = side
	_ = thing
}

pub fn p_player_in_special_sector(player voidptr) {
	_ = player
}

pub fn two_sided(sector int, line int) int {
	_ = sector
	_ = line
	return 0
}

pub fn get_sector(current_sector int, line int, side int) &Sector {
	_ = current_sector
	_ = line
	_ = side
	return unsafe { nil }
}

pub fn get_side(current_sector int, line int, side int) &Side {
	_ = current_sector
	_ = line
	_ = side
	return unsafe { nil }
}

pub fn p_find_lowest_floor_surrounding(sec &Sector) Fixed {
	_ = sec
	return Fixed(0)
}

pub fn p_find_highest_floor_surrounding(sec &Sector) Fixed {
	_ = sec
	return Fixed(0)
}

pub fn p_find_next_highest_floor(sec &Sector, currentheight int) Fixed {
	_ = sec
	_ = currentheight
	return Fixed(0)
}

pub fn p_find_lowest_ceiling_surrounding(sec &Sector) Fixed {
	_ = sec
	return Fixed(0)
}

pub fn p_find_highest_ceiling_surrounding(sec &Sector) Fixed {
	_ = sec
	return Fixed(0)
}

pub fn p_find_sector_from_line_tag(line &Line, start int) int {
	_ = line
	_ = start
	return -1
}

pub fn p_find_min_surrounding_light(sector &Sector, max int) int {
	_ = sector
	_ = max
	return 0
}

pub fn get_next_sector(line &Line, sec &Sector) &Sector {
	_ = line
	_ = sec
	return unsafe { nil }
}

// SPECIAL
pub fn ev_do_donut(line &Line) int {
	_ = line
	return 0
}

// P_LIGHTS
pub struct FireFlicker {
pub mut:
	thinker  Thinker
	sector   &Sector = unsafe { nil }
	count    int
	maxlight int
	minlight int
}

pub struct LightFlash {
pub mut:
	thinker  Thinker
	sector   &Sector = unsafe { nil }
	count    int
	maxlight int
	minlight int
	maxtime  int
	mintime  int
}

pub struct Strobe {
pub mut:
	thinker     Thinker
	sector      &Sector = unsafe { nil }
	count       int
	minlight    int
	maxlight    int
	darktime    int
	brighttime  int
}

pub struct Glow {
pub mut:
	thinker   Thinker
	sector    &Sector = unsafe { nil }
	minlight  int
	maxlight  int
	direction int
}

pub const glowspeed = 8
pub const strobebright = 5
pub const fastdark = 15
pub const slowdark = 35

pub fn p_spawn_fire_flicker(sector &Sector) { _ = sector }
pub fn t_light_flash(flash &LightFlash) { _ = flash }
pub fn p_spawn_light_flash(sector &Sector) { _ = sector }
pub fn t_strobe_flash(flash &Strobe) { _ = flash }
pub fn p_spawn_strobe_flash(sector &Sector, fast_or_slow int, in_sync int) {
	_ = sector
	_ = fast_or_slow
	_ = in_sync
}
pub fn ev_start_light_strobing(line &Line) { _ = line }
pub fn ev_turn_tag_lights_off(line &Line) { _ = line }
pub fn ev_light_turn_on(line &Line, bright int) { _ = line; _ = bright }
pub fn t_glow(g &Glow) { _ = g }
pub fn p_spawn_glowing_light(sector &Sector) { _ = sector }

// P_SWITCH
pub struct SwitchList {
pub mut:
	name1  string
	name2  string
	episode i16
}

pub enum BWhere {
	top
	middle
	bottom
}

pub struct Button {
pub mut:
	line     &Line = unsafe { nil }
	where    BWhere
	btexture int
	btimer   int
	soundorg &DegenMobj = unsafe { nil }
}

pub const maxswitches = 50
pub const maxbuttons = 16
pub const buttontime = 35

__global buttonlist = []Button{len: maxbuttons}

pub fn p_change_switch_texture(line &Line, use_again int) {
	_ = line
	_ = use_again
}

pub fn p_init_switch_list() {}

// P_PLATS
pub enum PlatE {
	up
	down
	waiting
	in_stasis
}

pub enum PlatTypeE {
	perpetual_raise
	down_wait_up_stay
	raise_and_change
	raise_to_nearest_and_change
	blaze_dwus
}

pub struct Plat {
pub mut:
	thinker   Thinker
	sector    &Sector = unsafe { nil }
	speed     Fixed
	low       Fixed
	high      Fixed
	wait      int
	count     int
	status    PlatE
	oldstatus PlatE
	crush     bool
	tag       int
	typ       PlatTypeE
}

pub const platwait = 3
pub const platspeed = frac_unit
pub const maxplats = 30

__global activeplats = []&Plat{len: maxplats, init: unsafe { nil }}

pub fn t_plat_raise(plat &Plat) { _ = plat }

pub fn ev_do_plat(line &Line, typ PlatTypeE, amount int) int {
	_ = line
	_ = typ
	_ = amount
	return 0
}

pub fn p_add_active_plat(plat &Plat) { _ = plat }
pub fn p_remove_active_plat(plat &Plat) { _ = plat }
pub fn ev_stop_plat(line &Line) { _ = line }
pub fn p_activate_in_stasis(tag int) { _ = tag }

// P_DOORS
pub enum VlDoorE {
	normal
	close30_then_open
	close
	open
	raise_in_5_mins
	blaze_raise
	blaze_open
	blaze_close
}

pub struct VlDoor {
pub mut:
	thinker      Thinker
	typ          VlDoorE
	sector       &Sector = unsafe { nil }
	topheight    Fixed
	speed        Fixed
	direction    int
	topwait      int
	topcountdown int
}

pub const vdoorspeed = frac_unit * 2
pub const vdoorwait = 150

pub fn ev_vertical_door(line &Line, thing &Mobj) {
	_ = line
	_ = thing
}

pub fn ev_do_door(line &Line, typ VlDoorE) int {
	_ = line
	_ = typ
	return 0
}

pub fn ev_do_locked_door(line &Line, typ VlDoorE, thing &Mobj) int {
	_ = line
	_ = typ
	_ = thing
	return 0
}

pub fn t_vertical_door(door &VlDoor) { _ = door }
pub fn p_spawn_door_close_in_30(sec &Sector) { _ = sec }
pub fn p_spawn_door_raise_in_5_mins(sec &Sector, secnum int) {
	_ = sec
	_ = secnum
}

// P_CEILNG
pub enum CeilingE {
	lower_to_floor
	raise_to_highest
	lower_and_crush
	crush_and_raise
	fast_crush_and_raise
	silent_crush_and_raise
}

pub struct Ceiling {
pub mut:
	thinker      Thinker
	typ          CeilingE
	sector       &Sector = unsafe { nil }
	bottomheight Fixed
	topheight    Fixed
	speed        Fixed
	crush        bool
	direction    int
	tag          int
	olddirection int
}

pub const ceilspeed = frac_unit
pub const ceilwait = 150
pub const maxceilings = 30

__global activeceilings = []&Ceiling{len: maxceilings, init: unsafe { nil }}

pub fn ev_do_ceiling(line &Line, typ CeilingE) int {
	_ = line
	_ = typ
	return 0
}
