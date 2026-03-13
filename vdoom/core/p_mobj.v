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
	unsafe {
		if mobj.flags & mf_nosector == 0 {
			mobj.subsector = voidptr(r_point_in_subsector(mobj.x, mobj.y))
			ss := &Subsector(mobj.subsector)
			if ss != voidptr(0) && ss.sector != voidptr(0) {
				if mobj.z < ss.sector.floorheight {
					mobj.z = ss.sector.floorheight
				}
				if mobj.z > ss.sector.ceilingheight - mobj.height {
					mobj.z = ss.sector.ceilingheight - mobj.height
				}
			}
		}
		if (mobj.flags & mf_noclip) == 0 && mobj.player == 0 {
			p_slide_move(voidptr(mobj))
		}
		if mobj.subsector != voidptr(0) {
			ss := &Subsector(mobj.subsector)
			if ss != voidptr(0) && ss.sector != voidptr(0) {
				mobj.floorz = ss.sector.floorheight
				mobj.ceilingz = ss.sector.ceilingheight
			}
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

pub const mobj_invalid_tid = -1
pub const mobj_no_height = 0
pub const mobj_no_radius = 0
pub const mobj_spawn_height = 0
pub const mobj_spawn_radius = 0

pub fn p_spawn_player(x Fixed, y Fixed, z Fixed, player &Player) &Mobj {
	mut mobj := &Mobj{}
	unsafe {
		mobj.x = x
		mobj.y = y
		mobj.z = z
		mobj.angle = 0
		mobj.player = player
		mobj.health = 100
		mobj.flags = mf_solid | mf_shootable | mf_countkill
		mobj.reactiontime = 18
	}
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

pub fn p_unlink_mobj(mobj &Mobj) {
	_ = mobj
}

pub fn p_link_mobj(mobj &Mobj) {
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
