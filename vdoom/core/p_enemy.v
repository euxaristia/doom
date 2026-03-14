module core

const di_nodir = 0
const di_east = 1
const di_northeast = 2
const di_north = 3
const di_northwest = 4
const di_west = 5
const di_southwest = 6
const di_south = 7
const di_southeast = 8

const xspeed = [Fixed(frac_unit), Fixed(47000), Fixed(0), Fixed(-47000), Fixed(-frac_unit), Fixed(-47000), Fixed(0), Fixed(47000)]
const yspeed = [Fixed(0), Fixed(47000), Fixed(frac_unit), Fixed(47000), Fixed(0), Fixed(-47000), Fixed(-frac_unit), Fixed(-47000)]
const diags = [di_northeast, di_northwest, di_southwest, di_southeast]

pub fn p_enemy_think(mobj &Mobj) {
	if mobj.target != unsafe { nil } {
		if mobj.flags & mf_ambush != 0 {
			if !p_check_sight(mobj, mobj.target) {
				return
			}
		}
		if mobj.flags & mf_countkill != 0 && (mobj.flags & mf_spawnceiling) == 0 {
			p_noise_alert(mobj, mobj)
		}
		if mobj.info != unsafe { nil } {
			info := unsafe { &MobjInfo(mobj.info) }
			if info.seestate != StateNum.s_null {
				p_set_mobj_state(mobj, info.seestate)
			}
		}
	}
}

pub fn p_spawn_brain_targets() {}
pub fn p_clear_brain_targets() {}

pub fn p_check_melee_range(actor &Mobj) bool {
	if actor.target == unsafe { nil } {
		return false
	}
	pl := actor.target
	dist := p_aprox_distance(pl.x - actor.x, pl.y - actor.y)
	range := meeleerange - 20 * frac_unit + pl.radius
	if dist >= range {
		return false
	}
	if !p_check_sight(actor, actor.target) {
		return false
	}
	return true
}

pub fn p_check_missile_range(actor &Mobj) bool {
	if !p_check_sight(actor, actor.target) {
		return false
	}
	if actor.flags & mf_justattacked != 0 {
		actor.flags &= ~mf_justattacked
		return true
	}
	if actor.reactiontime > 0 {
		return false
	}
	if actor.info != unsafe { nil } {
		info := unsafe { &MobjInfo(actor.info) }
		dist := p_aprox_distance(actor.x - actor.target.x, actor.y - actor.target.y) - 64 * frac_unit
		if info.meleestate == StateNum.s_null {
			dist -= 128 * frac_unit
		}
		dist >>= frac_bits
		if dist > info.maxattackrange {
			return false
		}
	}
	return true
}

pub fn p_move(actor &Mobj) bool {
	if actor.movedir == di_nodir {
		return false
	}
	if u32(actor.movedir) >= 8 {
		return false
	}
	info := unsafe { &MobjInfo(actor.info) }
	tryx := actor.x + info.speed * xspeed[actor.movedir]
	tryy := actor.y + info.speed * yspeed[actor.movedir]
	try_ok := p_try_move(voidptr(actor), tryx, tryy)
	if !try_ok {
		if actor.flags & mf_float != 0 && floatok {
			if actor.z < tmfloorz {
				actor.z += float_speed
			} else {
				actor.z -= float_speed
			}
			actor.flags |= mf_infloat
			return true
		}
		if numspechit == 0 {
			return false
		}
		actor.movedir = di_nodir
		good := false
		for numspechit > 0 {
			numspechit--
			_ = good
		}
		return good
	} else {
		actor.flags &= ~mf_infloat
	}
	return true
}

pub fn p_try_walk(actor &Mobj) bool {
	if !p_move(actor) {
		return false
	}
	actor.movecount = p_random() & 15
	return true
}

pub fn p_new_chase_dir(actor &Mobj) {
	if actor.target == unsafe { nil } {
		return
	}
	olddir := actor.movedir
	turnaround := (olddir + 4) % 8
	deltax := actor.target.x - actor.x
	deltay := actor.target.y - actor.y
	mut d1 := di_nodir
	mut d2 := di_nodir
	if deltax > 10 * frac_unit {
		d1 = di_east
	} else if deltax < -10 * frac_unit {
		d1 = di_west
	}
	if deltay > 10 * frac_unit {
		d2 = di_north
	} else if deltay < -10 * frac_unit {
		d2 = di_south
	}
	if d1 != di_nodir && d2 != di_nodir {
		actor.movedir = if deltay < 0 { if deltax > 0 { di_northeast } else { di_northwest } } else { if deltax > 0 { di_southeast } else { di_southwest } }
		if actor.movedir != turnaround && p_try_walk(actor) {
			return
		}
	}
	if p_random() > 200 || abs(deltay) > abs(deltax) {
		tdir := d1
		d1 = d2
		d2 = tdir
	}
	if d1 == turnaround {
		d1 = di_nodir
	}
	if d2 == turnaround {
		d2 = di_nodir
	}
	if d1 != di_nodir {
		actor.movedir = d1
		if p_try_walk(actor) {
			return
		}
	}
	if d2 != di_nodir {
		actor.movedir = d2
		if p_try_walk(actor) {
			return
		}
	}
	actor.movedir = di_nodir
	if olddir != di_nodir && p_try_walk(actor) {
		return
	}
	actor.movecount = p_random() & 15
}

pub fn p_look(actor &Mobj) bool {
	allaround := (actor.flags & mf_ambush) != 0
	stop := (actor.lastlook - 1) & 3
	mut c := 0
	for {
		actor.lastlook = (actor.lastlook + 1) & 3
		if !playeringame[actor.lastlook] {
			continue
		}
		c++
		if c == 2 || actor.lastlook == stop {
			return false
		}
		player := &players[actor.lastlook]
		if player.cheats & int(Cheat.notarget) != 0 {
			continue
		}
		if player.playerstate == .dead {
			continue
		}
		if !p_check_sight(actor, player.mo) {
			continue
		}
		if !allaround {
			an := r_point_to_angle_2(actor.x, actor.y, player.mo.x, player.mo.y) - actor.angle
			if an > ang90 && an < ang270 {
				dist := p_aprox_distance(player.mo.x - actor.x, player.mo.y - actor.y)
				if dist > meeleerange {
					continue
				}
			}
		}
		actor.target = player.mo
		return true
	}
}

pub fn p_chase(actor &Mobj) {
	if actor.target == unsafe { nil } || (actor.flags & mf_spawnceiling) != 0 {
		p_new_chase_dir(actor)
		return
	}
	if p_check_melee_range(actor) {
		info := unsafe { &MobjInfo(actor.info) }
		if info.meleestate != StateNum.s_null {
			p_set_mobj_state(actor, info.meleestate)
		}
		return
	}
	if actor.info != unsafe { nil } {
		info := unsafe { &MobjInfo(actor.info) }
		if info.missilestate != StateNum.s_null && p_check_missile_range(actor) {
			p_set_mobj_state(actor, info.missile_state)
			return
		}
	}
	if actor.threshold > 0 {
		return
	}
	if actor.movecount > 0 {
		actor.movecount--
		if actor.movecount == 0 {
			actor.movecount = p_random() & 15
		}
	} else {
		p_new_chase_dir(actor)
	}
	p_move(actor)
}

pub fn p_face_target(actor &Mobj) {
	if actor.target == unsafe { nil } {
		return
	}
	delta_x := actor.target.x - actor.x
	delta_y := actor.target.y - actor.y
	angle := atan2(delta_y, delta_x)
	actor.angle = u32(angle)
}

pub fn p_pos_attack(actor &Mobj) {
	_ = actor
}

pub fn p_spos_attack(actor &Mobj) {
	_ = actor
}

pub fn p_cpos_attack(actor &Mobj) {
	_ = actor
}

pub fn p_attack(actor &Mobj) {
	_ = actor
}

pub fn p_bspi_attack(actor &Mobj) {
	_ = actor
}

pub fn p_troop_attack(actor &Mobj) {
	_ = actor
}

pub fn p_spid_refire(actor &Mobj) {
	_ = actor
}

pub fn p_cpos_refire(actor &Mobj) {
	_ = actor
}

pub fn p_brain_awake(actor &Mobj) {
	_ = actor
}

pub fn p_brain_die(actor &Mobj) {
	_ = actor
}

pub fn p_brain_expand() {}

pub fn p_brain_more_points(x Fixed, y Fixed, special bool) {
	_ = x
	_ = y
	_ = special
}

pub fn p_brain_next_in_queue(actor &Mobj) &Mobj {
	_ = actor
	return unsafe { nil }
}

pub fn p_brain_not_target(actor &Mobj) {
	_ = actor
}

pub fn a_fall(actor &Mobj) {
	actor.flags &= ~mf_solid
	actor.z = actor.floorz
}

pub fn a_keen_die(actor &Mobj) {
	a_fall(actor)
}

pub fn a_look(actor &Mobj) {
	if p_look(actor) {
		p_set_mobj_state(actor, unsafe { &MobjInfo(actor.info) }.seestate)
	}
}

pub fn a_chase(actor &Mobj) {
	p_chase(actor)
}

pub fn a_face_target(actor &Mobj) {
	p_face_target(actor)
}

pub fn a_pos_attack(actor &Mobj) {
	p_pos_attack(actor)
}

pub fn a_spos_attack(actor &Mobj) {
	p_spos_attack(actor)
}

pub fn a_cpos_attack(actor &Mobj) {
	p_cpos_attack(actor)
}

pub fn a_cpos_refire(actor &Mobj) {
	p_cpos_refire(actor)
}

pub fn a_spid_refire(actor &Mobj) {
	p_spid_refire(actor)
}

pub fn a_bspi_attack(actor &Mobj) {
	p_bspi_attack(actor)
}

pub fn a_troop_attack(actor &Mobj) {
	p_troop_attack(actor)
}

pub fn a_sarg_attack(actor &Mobj) {
	_ = actor
}

pub fn a_head_attack(actor &Mobj) {
	_ = actor
}

pub fn a_brain_explode(actor &Mobj) {
	_ = actor
}

pub fn a_brain_scream(actor &Mobj) {
	_ = actor
}

pub fn a_brain_die(actor &Mobj) {
	_ = actor
}

pub fn a_brain_awake(actor &Mobj) {
	p_brain_awake(actor)
}

pub fn p_revenge_need_player(actor &Mobj) bool {
	_ = actor
	return false
}
