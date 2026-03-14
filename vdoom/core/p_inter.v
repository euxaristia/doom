module core

pub fn p_give_power(player voidptr, power int) bool {
	if player == unsafe { nil } {
		return false
	}
	mut pl := unsafe { &Player(player) }
	if power < 0 || power >= pl.powers.len {
		return false
	}
	pl.powers[power] = 1
	return true
}

pub fn p_damage_mobj(target &Mobj, inflictor &Mobj, source &Mobj, damage int) {
	if target == unsafe { nil } {
		return
	}
	if (target.flags & mf_shootable) == 0 {
		return
	}
	if target.health <= 0 {
		return
	}
	if target.flags & mf_skullfly != 0 {
		target.momx = 0
		target.momy = 0
		target.momz = 0
	}
	player := unsafe { &Player(target.player) }
	if player != unsafe { nil } && gameskill == .baby {
		// Half damage in baby mode
	}
	if inflictor != unsafe { nil } && (target.flags & mf_noclip) == 0 {
		ang := r_point_to_angle_2(inflictor.x, inflictor.y, target.x, target.y)
		thrust := damage * (frac_unit >> 3) * 100 / 100
		ang >>= angletofineshift
		target.momx += fixed_mul(thrust, finecosine[ang])
		target.momy += fixed_mul(thrust, finesine[ang])
	}
	if player != unsafe { nil } {
		target.health -= damage
		if target.health < 0 {
			target.health = 0
		}
		player.damagecount += damage
		if player.damagecount > 100 {
			player.damagecount = 100
		}
	} else {
		target.health -= damage
		if target.health < 0 {
			target.health = 0
		}
	}
	if target.health <= 0 {
		p_kill_mobj(target, inflictor, source)
		return
	}
	if target.flags & mf_ambush == 0 {
		target.flags |= mf_justattacked
	}
	if player != unsafe { nil } && inflictor != unsafe { nil } && inflictor != target {
		if target.z < inflictor.z {
			player.lookdir = (inflictor.z - target.z) >> 2
		}
	}
}

pub fn p_kill_mobj(target &Mobj, inflictor &Mobj, source &Mobj) {
	_ = target
	_ = inflictor
	_ = source
}

pub fn p_touch_special_thing(special &Mobj, toucher &Mobj) {
	if special == unsafe { nil } || toucher == unsafe { nil } {
		return
	}
	if (special.flags & mf_special) == 0 {
		return
	}
	specialplayer := unsafe { &Player(special.player) }
	if specialplayer != unsafe { nil } {
		return
	}
	_ = toucher
}

pub fn p_check_cheats() {}

pub fn p_commander_cheat(actor &Mobj) {
	_ = actor
}

pub fn p_god_cheat(actor &Mobj) {
	_ = actor
}

pub fn p_massacre_cheat() {}

pub fn p_give_armor(player &Player, armor int) bool {
	_ = player
	_ = armor
	return false
}

pub fn p_give_backpack(player &Player) bool {
	_ = player
	return false
}

pub fn p_give_card(player &Player, card Card) bool {
	_ = player
	_ = card
	return false
}

pub fn p_give_key(player &Player, key int) bool {
	_ = player
	_ = key
	return false
}

pub fn p_give_health(player &Player, amount int) bool {
	_ = player
	_ = amount
	return false
}

pub fn p_give_weapon(player &Player, weapon WeaponType, ammo int) bool {
	_ = player
	_ = weapon
	_ = ammo
	return false
}

pub fn p_give_ammo(player &Player, ammo AmmoType, amount int) bool {
	_ = player
	_ = ammo
	_ = amount
	return false
}
