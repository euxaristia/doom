module core

// Max ammo amounts per ammo type
const max_ammo_values = [200, 50, 300, 50]!  // clip, shell, cell, misl
const clip_ammo_values = [10, 4, 20, 1]!     // per pickup

pub fn p_give_ammo(player &Player, ammo int, count int) bool {
	if ammo < 0 || ammo >= numammo {
		return false
	}
	if player.ammo[ammo] >= player.maxammo[ammo] {
		return false
	}
	mut give := count
	if give == 0 {
		give = clip_ammo_values[ammo]
	}
	// Double ammo in lower skills
	if gameskill == 0 || gameskill == 4 { // baby or nightmare
		give <<= 1
	}
	unsafe {
		player.ammo[ammo] += give
		if player.ammo[ammo] > player.maxammo[ammo] {
			player.ammo[ammo] = player.maxammo[ammo]
		}
	}
	return true
}

pub fn p_give_weapon(player &Player, weapon int, ammogive int) bool {
	if weapon < 0 || weapon >= numweapons {
		return false
	}
	gave_weapon := player.weaponowned[weapon] == 0
	unsafe {
		player.weaponowned[weapon] = 1
	}
	// Give ammo associated with the weapon
	gave_ammo := if ammogive >= 0 && ammogive < numammo {
		p_give_ammo(player, ammogive, 0)
	} else {
		false
	}
	if gave_weapon {
		unsafe {
			player.pendingweapon = WeaponType(weapon)
		}
	}
	return gave_weapon || gave_ammo
}

pub fn p_give_health(player &Player, amount int, max int) bool {
	if player.health >= max {
		return false
	}
	unsafe {
		player.health += amount
		if player.health > max {
			player.health = max
		}
		player.mo.health = player.health
	}
	return true
}

pub fn p_give_armor(player &Player, amount int) bool {
	if player.armorpoints >= amount {
		return false
	}
	unsafe {
		player.armorpoints = amount
		player.armortype = 1
	}
	return true
}

pub fn p_give_card(player &Player, card int) bool {
	if card < 0 || card >= numcards {
		return false
	}
	if player.cards[card] {
		return false
	}
	unsafe {
		player.bonuscount = 6
		player.cards[card] = true
	}
	return true
}

pub fn p_give_key_card(player &Player, key int) bool {
	return p_give_card(player, key)
}

pub fn p_give_body(player &Player, amount int, max int) bool {
	return p_give_health(player, amount, max)
}

pub fn p_give_power(player voidptr, power int) bool {
	if player == unsafe { nil } {
		return false
	}
	p := unsafe { &Player(player) }
	if power < 0 || power >= numpowers {
		return false
	}
	match unsafe { PowerType(power) } {
		.invulnerability {
			unsafe { p.powers[power] = invulntics }
		}
		.invisibility {
			unsafe {
				p.powers[power] = invistics
				p.mo.flags |= mf_shadow
			}
		}
		.infrared {
			unsafe { p.powers[power] = infratics }
		}
		.ironfeet {
			unsafe { p.powers[power] = irontics }
		}
		.strength {
			p_give_health(p, 100, deh_max_health)
			unsafe { p.powers[power] = 1 }
		}
		.allmap {
			unsafe { p.powers[power] = 1 }
		}
		else {
			return false
		}
	}
	return true
}

pub fn p_give_powerup(player &Player, power int, time int) bool {
	if power < 0 || power >= numpowers {
		return false
	}
	unsafe {
		player.powers[power] = time
	}
	return true
}

pub fn p_give_backpack(player &Player) {
	for i in 0 .. numammo {
		if player.maxammo[i] < max_ammo_values[i] * 2 {
			unsafe {
				player.maxammo[i] = max_ammo_values[i] * 2
			}
		}
	}
	unsafe {
		player.backpack = true
	}
}

pub fn p_damage_mobj(target &Mobj, inflictor &Mobj, source &Mobj, damage int) {
	if target == unsafe { nil } {
		return
	}
	// Dead things don't take more damage
	if target.health <= 0 {
		return
	}
	mut actual_damage := damage
	// Player damage
	if target.player != unsafe { nil } {
		player := unsafe { &Player(target.player) }
		// Reduce damage by armor
		mut saved := 0
		if player.armortype != 0 {
			if player.armortype == 1 {
				saved = actual_damage / 3
			} else {
				saved = actual_damage / 2
			}
			if saved >= player.armorpoints {
				saved = player.armorpoints
			}
			unsafe {
				player.armorpoints -= saved
				if player.armorpoints <= 0 {
					player.armortype = 0
				}
			}
			actual_damage -= saved
		}
		unsafe {
			player.health -= actual_damage
			target.health = player.health
			player.attacker = &Mobj(source)
			player.damagecount += actual_damage
			if player.damagecount > 100 {
				player.damagecount = 100
			}
		}
		if player.health <= 0 {
			p_kill_mobj(target, source, inflictor)
		}
	} else {
		// Non-player (monster)
		unsafe {
			target.health -= actual_damage
		}
		if target.health <= 0 {
			p_kill_mobj(target, source, inflictor)
		} else {
			// Wake up monster
			unsafe {
				target.target = &Mobj(source)
			}
		}
	}
}

pub fn p_kill_mobj(target &Mobj, source &Mobj, inflictor &Mobj) {
	_ = inflictor
	if target == unsafe { nil } {
		return
	}
	unsafe {
		target.flags &= ~(mf_shootable | mf_float | mf_skullfly)
		target.flags |= mf_corpse | mf_dropoff
		target.height >>= 2
	}
	if target.player != unsafe { nil } {
		unsafe {
			player := &Player(target.player)
			player.playerstate = .dead
		}
		// Credit the killer
		if source != unsafe { nil } && source.player != unsafe { nil } {
			killer := unsafe { &Player(source.player) }
			_ = killer
		}
	}
}

pub fn p_explode_mobj(mobj &Mobj) {
	_ = mobj
}

pub fn a_decide(actor &Mobj) {
	_ = actor
}

pub fn a_spawn(actor &Mobj) {
	_ = actor
}

pub fn a_smoke(actor &Mobj) {
	_ = actor
}

pub fn a_blood(actor &Mobj) {
	_ = actor
}

pub fn a_headfire(actor &Mobj) {
	_ = actor
}

pub fn a_spawnflash(actor &Mobj) {
	_ = actor
}

pub fn a_bfgsound(actor &Mobj) {
	_ = actor
}

pub fn a_manattack(actor &Mobj) {
	_ = actor
}

pub fn a_skullfly(actor &Mobj) {
	_ = actor
}

pub fn a_playdemon(actor &Mobj) {
	_ = actor
}

pub fn a_playedsound(actor &Mobj) {
	_ = actor
}

pub fn a_scream(actor &Mobj) {
	_ = actor
}

pub fn a_xscream(actor &Mobj) {
	_ = actor
}

pub fn a_fall(actor &Mobj) {
	if actor == unsafe { nil } {
		return
	}
	unsafe {
		actor.flags &= ~mf_solid
	}
}

pub fn a_itemrespawn(actor &Mobj) {
	_ = actor
}

pub fn a_minotaur_sonar(actor &Mobj) {
	_ = actor
}

pub fn p_touch_thing(thing &Mobj) {
	_ = thing
}
