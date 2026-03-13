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
	ceilingz   Fixed
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

pub fn p_set_mobj_state(mobj &Mobj, state int) bool {
	if state == 0 {
		return false
	}
	return true
}

pub fn p_spawn_mobj(x Fixed, y Fixed, z Fixed, typ int) &Mobj {
	mut mobj := &Mobj{}
	unsafe {
		mobj.x = x
		mobj.y = y
		mobj.z = z
		mobj.mobj_type = typ
		mobj.flags = 0
		mobj.health = 100
	}
	return mobj
}

pub fn p_remove_mobj(mobj &Mobj) {
	_ = mobj
}

pub fn p_spawn_puff(x Fixed, y Fixed, z Fixed) {
	_ = x
	_ = y
	_ = z
}

pub fn p_spawn_blood(x Fixed, y Fixed, z Fixed, damage int) {
	_ = x
	_ = y
	_ = z
	_ = damage
}

pub fn p_mobj_thinker(mobj &Mobj) {
	_ = mobj
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

pub const mobj_invalid_tid = -1
pub const mobj_no_height = 0
pub const mobj_no_radius = 0
pub const mobj_spawn_height = 0
pub const mobj_spawn_radius = 0
