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

pub fn p_apply_time_limit() {
	if timelimit > 0 {
		p_start_level_timer(timelimit)
	} else {
		p_stop_level_timer()
	}
}

// Line flags.
const ml_twosided = i16(4)

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
	if sector < 0 || sector >= numsectors {
		return 0
	}
	if line < 0 || line >= sectors[sector].linecount {
		return 0
	}
	return int(sectors[sector].lines[line].flags & ml_twosided)
}

pub fn get_sector(current_sector int, line int, side int) &Sector {
	if current_sector < 0 || current_sector >= numsectors {
		return unsafe { nil }
	}
	if line < 0 || line >= sectors[current_sector].linecount {
		return unsafe { nil }
	}
	if side < 0 || side > 1 {
		return unsafe { nil }
	}
	sidenum := int(sectors[current_sector].lines[line].sidenum[side])
	if sidenum < 0 || sidenum >= numsides {
		return unsafe { nil }
	}
	return sides[sidenum].sector
}

pub fn get_side(current_sector int, line int, side int) &Side {
	if current_sector < 0 || current_sector >= numsectors {
		return unsafe { nil }
	}
	if line < 0 || line >= sectors[current_sector].linecount {
		return unsafe { nil }
	}
	if side < 0 || side > 1 {
		return unsafe { nil }
	}
	sidenum := int(sectors[current_sector].lines[line].sidenum[side])
	if sidenum < 0 || sidenum >= numsides {
		return unsafe { nil }
	}
	return &sides[sidenum]
}

pub fn p_find_lowest_floor_surrounding(sec &Sector) Fixed {
	mut floor := sec.floorheight
	for i := 0; i < sec.linecount; i++ {
		check := sec.lines[i]
		other := get_next_sector(check, sec)
		if other == unsafe { nil } {
			continue
		}
		if other.floorheight < floor {
			floor = other.floorheight
		}
	}
	return floor
}

pub fn p_find_highest_floor_surrounding(sec &Sector) Fixed {
	mut floor := Fixed(-500 * frac_unit)
	for i := 0; i < sec.linecount; i++ {
		check := sec.lines[i]
		other := get_next_sector(check, sec)
		if other == unsafe { nil } {
			continue
		}
		if other.floorheight > floor {
			floor = other.floorheight
		}
	}
	return floor
}

pub fn p_find_next_highest_floor(sec &Sector, currentheight int) Fixed {
	mut height := Fixed(currentheight)
	mut h := 0
	mut heightlist := []Fixed{len: 22}
	for i := 0; i < sec.linecount; i++ {
		check := sec.lines[i]
		other := get_next_sector(check, sec)
		if other == unsafe { nil } {
			continue
		}
		if other.floorheight > height {
			// Emulate vanilla overflow quirks (20 adjoining sectors max).
			if h == 21 {
				height = other.floorheight
			} else if h == 22 {
				i_error('Sector with more than 22 adjoining sectors. Vanilla will crash here')
			}
			if h < heightlist.len {
				heightlist[h] = other.floorheight
			}
			h++
		}
	}
	if h == 0 {
		return Fixed(currentheight)
	}
	mut min := heightlist[0]
	for i := 1; i < h && i < heightlist.len; i++ {
		if heightlist[i] < min {
			min = heightlist[i]
		}
	}
	return min
}

pub fn p_find_lowest_ceiling_surrounding(sec &Sector) Fixed {
	mut height := Fixed(int_max)
	for i := 0; i < sec.linecount; i++ {
		check := sec.lines[i]
		other := get_next_sector(check, sec)
		if other == unsafe { nil } {
			continue
		}
		if other.ceilingheight < height {
			height = other.ceilingheight
		}
	}
	return height
}

pub fn p_find_highest_ceiling_surrounding(sec &Sector) Fixed {
	mut height := Fixed(0)
	for i := 0; i < sec.linecount; i++ {
		check := sec.lines[i]
		other := get_next_sector(check, sec)
		if other == unsafe { nil } {
			continue
		}
		if other.ceilingheight > height {
			height = other.ceilingheight
		}
	}
	return height
}

pub fn p_find_sector_from_line_tag(line &Line, start int) int {
	for i := start + 1; i < numsectors; i++ {
		if sectors[i].tag == line.tag {
			return i
		}
	}
	return -1
}

pub fn p_find_min_surrounding_light(sector &Sector, max int) int {
	mut min := max
	for i := 0; i < sector.linecount; i++ {
		line := sector.lines[i]
		check := get_next_sector(line, sector)
		if check == unsafe { nil } {
			continue
		}
		if int(check.lightlevel) < min {
			min = int(check.lightlevel)
		}
	}
	return min
}

pub fn get_next_sector(line &Line, sec &Sector) &Sector {
	if (line.flags & ml_twosided) == 0 {
		return unsafe { nil }
	}
	if line.frontsector == sec {
		return line.backsector
	}
	return line.frontsector
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

pub fn t_fire_flicker(thinker voidptr) {
	if thinker == unsafe { nil } {
		return
	}
	mut flick := unsafe { &FireFlicker(thinker) }
	flick.count--
	if flick.count > 0 {
		return
	}
	amount := (p_random() & 3) * 16
	if int(flick.sector.lightlevel) - amount < flick.minlight {
		flick.sector.lightlevel = i16(flick.minlight)
	} else {
		flick.sector.lightlevel = i16(flick.maxlight - amount)
	}
	flick.count = 4
}

pub fn p_spawn_fire_flicker(mut sector &Sector) {
	sector.special = 0
	mut flick := &FireFlicker{}
	p_add_thinker(mut flick.thinker)
	flick.thinker.function.acp1 = ActionfP1(t_fire_flicker)
	flick.sector = sector
	flick.maxlight = int(sector.lightlevel)
	flick.minlight = p_find_min_surrounding_light(sector, int(sector.lightlevel)) + 16
	flick.count = 4
}

pub fn t_light_flash(thinker voidptr) {
	if thinker == unsafe { nil } {
		return
	}
	mut flash := unsafe { &LightFlash(thinker) }
	flash.count--
	if flash.count > 0 {
		return
	}
	if int(flash.sector.lightlevel) == flash.maxlight {
		flash.sector.lightlevel = i16(flash.minlight)
		flash.count = (p_random() & flash.mintime) + 1
	} else {
		flash.sector.lightlevel = i16(flash.maxlight)
		flash.count = (p_random() & flash.maxtime) + 1
	}
}

pub fn p_spawn_light_flash(mut sector &Sector) {
	sector.special = 0
	mut flash := &LightFlash{}
	p_add_thinker(mut flash.thinker)
	flash.thinker.function.acp1 = ActionfP1(t_light_flash)
	flash.sector = sector
	flash.maxlight = int(sector.lightlevel)
	flash.minlight = p_find_min_surrounding_light(sector, int(sector.lightlevel))
	flash.maxtime = 64
	flash.mintime = 7
	flash.count = (p_random() & flash.maxtime) + 1
}

pub fn t_strobe_flash(thinker voidptr) {
	if thinker == unsafe { nil } {
		return
	}
	mut flash := unsafe { &Strobe(thinker) }
	flash.count--
	if flash.count > 0 {
		return
	}
	if int(flash.sector.lightlevel) == flash.minlight {
		flash.sector.lightlevel = i16(flash.maxlight)
		flash.count = flash.brighttime
	} else {
		flash.sector.lightlevel = i16(flash.minlight)
		flash.count = flash.darktime
	}
}

pub fn p_spawn_strobe_flash(mut sector &Sector, fast_or_slow int, in_sync int) {
	mut flash := &Strobe{}
	p_add_thinker(mut flash.thinker)
	flash.sector = sector
	flash.darktime = fast_or_slow
	flash.brighttime = strobebright
	flash.thinker.function.acp1 = ActionfP1(t_strobe_flash)
	flash.maxlight = int(sector.lightlevel)
	flash.minlight = p_find_min_surrounding_light(sector, int(sector.lightlevel))
	if flash.minlight == flash.maxlight {
		flash.minlight = 0
	}
	sector.special = 0
	if in_sync == 0 {
		flash.count = (p_random() & 7) + 1
	} else {
		flash.count = 1
	}
}

pub fn ev_start_light_strobing(line &Line) {
	mut secnum := 0
	secnum = p_find_sector_from_line_tag(line, secnum)
	for secnum >= 0 {
		secnum = p_find_sector_from_line_tag(line, secnum)
		mut sec := &sectors[secnum]
		if sec.specialdata != unsafe { nil } {
			continue
		}
		p_spawn_strobe_flash(mut sec, slowdark, 0)
	}
}

pub fn ev_turn_tag_lights_off(line &Line) {
	for i := 0; i < numsectors; i++ {
		mut sector := &sectors[i]
		if sector.tag != line.tag {
			continue
		}
		mut min := int(sector.lightlevel)
		for j := 0; j < sector.linecount; j++ {
			templine := sector.lines[j]
			tsec := get_next_sector(templine, sector)
			if tsec == unsafe { nil } {
				continue
			}
			if int(tsec.lightlevel) < min {
				min = int(tsec.lightlevel)
			}
		}
		sector.lightlevel = i16(min)
	}
}

pub fn ev_light_turn_on(line &Line, bright int) {
	for i := 0; i < numsectors; i++ {
		mut sector := &sectors[i]
		if sector.tag != line.tag {
			continue
		}
		mut target := bright
		if target == 0 {
			for j := 0; j < sector.linecount; j++ {
				templine := sector.lines[j]
				temp := get_next_sector(templine, sector)
				if temp == unsafe { nil } {
					continue
				}
				if int(temp.lightlevel) > target {
					target = int(temp.lightlevel)
				}
			}
		}
		sector.lightlevel = i16(target)
	}
}

pub fn t_glow(thinker voidptr) {
	if thinker == unsafe { nil } {
		return
	}
	mut g := unsafe { &Glow(thinker) }
	match g.direction {
		-1 {
			g.sector.lightlevel -= i16(glowspeed)
			if int(g.sector.lightlevel) <= g.minlight {
				g.sector.lightlevel += i16(glowspeed)
				g.direction = 1
			}
		}
		1 {
			g.sector.lightlevel += i16(glowspeed)
			if int(g.sector.lightlevel) >= g.maxlight {
				g.sector.lightlevel -= i16(glowspeed)
				g.direction = -1
			}
		}
		else {}
	}
}

pub fn p_spawn_glowing_light(mut sector &Sector) {
	mut g := &Glow{}
	p_add_thinker(mut g.thinker)
	g.sector = sector
	g.minlight = p_find_min_surrounding_light(sector, int(sector.lightlevel))
	g.maxlight = int(sector.lightlevel)
	g.thinker.function.acp1 = ActionfP1(t_glow)
	g.direction = -1
	sector.special = 0
}

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
