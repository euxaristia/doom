module core

pub struct Mobj {
pub mut:
	thinker     Thinker
	x           Fixed
	y           Fixed
	z           Fixed
	snext       &Mobj = unsafe { nil }
	sprev       &Mobj = unsafe { nil }
	angle       u32
	sprite      int
	frame       int
	bnext       &Mobj = unsafe { nil }
	bprev       &Mobj = unsafe { nil }
	subsector   voidptr
	floorz      Fixed
	ceilingz    Fixed
	radius      Fixed
	height      Fixed
	momx        Fixed
	momy        Fixed
	momz        Fixed
	validcount  int
	mobj_type   int
	info        voidptr
	tics        int
	state_ptr   voidptr
	flags       int
	health      int
	movedir     int
	movecount   int
	target      &Mobj = unsafe { nil }
	reactiontime int
	threshold   int
	player      voidptr
	lastlook    int
	spawnpoint  voidptr
	tracer      &Mobj = unsafe { nil }
	interp      int
	oldx        Fixed
	oldy        Fixed
	oldz        Fixed
	oldangle    u32
}

const mf_special = 1
const mf_solid = 2
const mf_shootable = 4
const mf_nosector = 8
const mf_noblockmap = 16
const mf_ambush = 32
const mf_justattacked = 128
const mf_spawnceiling = 256
const mf_nogravity = 512
const mf_dropoff = 0x400
const mf_pickup = 0x800
const mf_noclip = 0x1000
const mf_slide = 0x2000
const mf_float = 0x4000
const mf_teleport = 0x8000
const mf_missile = 0x10000
const mf_dropped = 0x20000
const mf_shadow = 0x40000
const mf_noblood = 0x80000
const mf_corpse = 0x100000
const mf_infloat = 0x200000
const mf_countkill = 0x400000
const mf_countitem = 0x800000
const mf_skullfly = 0x1000000
const mf_notdmatch = 0x2000000
const mf_translation = 0xc000000
const mf_flip = 0x1
const mf_flippable = 0x1

pub const mobj_invalid_tid = -1
pub const mobj_no_height = 0
pub const mobj_no_radius = 0
pub const mobj_spawn_height = 0
pub const mobj_spawn_radius = 0

pub fn p_set_mobj_state(mut mobj &Mobj, state StateNum) bool {
	if int(state) == 0 {
		return false
	}
	st := &states[int(state)]
	mobj.state_ptr = voidptr(st)
	mobj.tics = st.tics
	mobj.sprite = int(st.sprite)
	mobj.frame = st.frame
	if st.action.acp1 != voidptr(0) {
		st.action.acp1(voidptr(mobj))
	}
	mut next := st.nextstate
	for next != StateNum.s_null && next != unsafe { StateNum(0) } {
		next_st := &states[int(next)]
		mobj.state_ptr = voidptr(next_st)
		mobj.tics = next_st.tics
		mobj.sprite = int(next_st.sprite)
		mobj.frame = next_st.frame
		if next_st.action.acp1 != voidptr(0) {
			next_st.action.acp1(voidptr(mobj))
		}
		if mobj.tics > 0 {
			break
		}
		next = next_st.nextstate
	}
	return true
}

pub fn p_spawn_mobj(x Fixed, y Fixed, z Fixed, typ int) &Mobj {
	mut mobj := &Mobj{}
	if typ >= num_mobj_types || typ < 0 {
		return mobj
	}
	info := &mobjinfo[typ]
	mobj.mobj_type = typ
	mobj.info = voidptr(info)
	mobj.x = x
	mobj.y = y
	mobj.radius = info.radius
	mobj.height = info.height
	mobj.flags = info.flags
	mobj.health = info.spawnhealth
	mobj.lastlook = p_random() % maxplayers
	st := &states[int(info.spawnstate)]
	mobj.state_ptr = voidptr(st)
	mobj.tics = st.tics
	mobj.sprite = int(st.sprite)
	mobj.frame = st.frame
	p_set_thing_position_impl(mobj)
	ss := unsafe { &Subsector(mobj.subsector) }
	if ss != unsafe { nil } && ss.sector != unsafe { nil } {
		mobj.floorz = ss.sector.floorheight
		mobj.ceilingz = ss.sector.ceilingheight
	}
	if z == onfloorz {
		mobj.z = mobj.floorz
	} else if z == onceilingz {
		mobj.z = mobj.ceilingz - mobj.height
	} else {
		mobj.z = z
	}
	mobj.oldx = mobj.x
	mobj.oldy = mobj.y
	mobj.oldz = mobj.z
	mobj.oldangle = mobj.angle
	mobj.thinker.function.acp1 = p_mobj_thinker_fn
	p_add_thinker(mut mobj.thinker)
	return mobj
}

fn p_mobj_thinker_fn(mobj voidptr) {
	_ = mobj
}

pub fn p_set_thing_position_impl(m &Mobj) {
	ss := r_point_in_subsector(m.x, m.y)
	unsafe {
		m.subsector = voidptr(ss)
	}
}

pub fn p_unset_thing_position_impl(m &Mobj) {
	_ = m
}

pub fn p_link_mobj(mobj &Mobj) {
	_ = mobj
}

pub fn p_mobj_thinker(mut mobj &Mobj) {
	if mobj.subsector == unsafe { nil } {
		return
	}
	ss := unsafe { &Subsector(mobj.subsector) }
	if ss == unsafe { nil } || ss.sector == unsafe { nil } {
		return
	}
	if (mobj.flags & mf_nosector) == 0 {
		if mobj.z < ss.sector.floorheight {
			mobj.z = ss.sector.floorheight
		}
		if mobj.z > ss.sector.ceilingheight - mobj.height {
			mobj.z = ss.sector.ceilingheight - mobj.height
		}
	}
	if (mobj.flags & mf_noclip) == 0 && mobj.player == unsafe { nil } {
		if mobj.flags & mf_missile == 0 {
			p_slide_move(voidptr(mobj))
		}
	}
	mobj.x += mobj.momx
	mobj.y += mobj.momy
	mobj.z += mobj.momz
	if mobj.z > mobj.floorz && mobj.momz != 0 {
		mobj.momz -= gravity >> 4
		if mobj.momz < -maxvelocity {
			mobj.momz = -maxvelocity
		}
	} else {
		mobj.momz = 0
		if mobj.z < mobj.floorz {
			mobj.z = mobj.floorz
		}
	}
	if mobj.subsector != unsafe { nil } {
		new_ss := unsafe { &Subsector(mobj.subsector) }
		if new_ss != unsafe { nil } && new_ss.sector != unsafe { nil } {
			mobj.floorz = new_ss.sector.floorheight
			mobj.ceilingz = new_ss.sector.ceilingheight
		}
	}
}

pub fn p_respawn_specials() {}

pub fn p_check_missile_spawn(missile &Mobj) bool {
	_ = missile
	return false
}

pub fn p_subst_null_mobj(mobj &Mobj) &Mobj {
	return mobj
}

pub fn p_explode_missile(mobj &Mobj) {
	_ = mobj
}

pub fn p_spawn_player(x Fixed, y Fixed, z Fixed, player &Player) &Mobj {
	mut mobj := &Mobj{}
	mobj.x = x
	mobj.y = y
	mobj.z = z
	mobj.angle = 0
	mobj.player = player
	mobj.health = 100
	mobj.flags = mf_solid | mf_shootable | mf_countkill
	mobj.reactiontime = 18
	mobj.radius = playerradius
	mobj.height = Fixed(16 * frac_unit)
	return mobj
}

pub fn p_remove_player_mobj(mobj &Mobj) {
	_ = mobj
}

pub fn p_spawn_missile(source &Mobj, dest &Mobj, missiletype int) &Mobj {
	_ = source
	_ = dest
	_ = missiletype
	return unsafe { nil }
}

pub fn p_spawn_player_missile(source &Mobj, missiletype int) {
	_ = source
	_ = missiletype
}

pub fn p_x_movement(mobj &Mobj) {
	_ = mobj
}

pub fn p_z_movement(mobj &Mobj) {
	_ = mobj
}

pub fn p_mobj_position(mobj &Mobj) {
	_ = mobj
}

pub fn p_mobj_on_segs(mobj &Mobj) {
	_ = mobj
}

pub fn p_spawn_teleport_fog(x Fixed, y Fixed, z Fixed) {
	_ = x
	_ = y
	_ = z
}

pub fn p_mobj_check_spawnpos(x Fixed, y Fixed, z Fixed, mobj &Mobj) {
	_ = x
	_ = y
	_ = z
	_ = mobj
}

pub fn p_is_mobj_dead(mobj &Mobj) bool {
	_ = mobj
	return false
}

pub fn p_mobj_damaged(mobj &Mobj, damage int) {
	_ = mobj
	_ = damage
}

pub fn p_check_mobj_explode(mobj &Mobj) {
	_ = mobj
}
