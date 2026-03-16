module core

// Max ammo amounts per ammo type
const max_ammo_values = [200, 50, 300, 50]! // clip, shell, cell, misl
const clip_ammo_values = [10, 4, 20, 1]! // per pickup

// DOOM Thing Types for pickupable items
const thing_clip = 2001
const thing_clipbox = 2002
const thing_shell = 2003
const thing_shellbox = 2004
const thing_rocket = 2005
const thing_rocketbox = 2006
const thing_cell = 2007
const thing_cellpack = 2008
const thing_stimpack = 2011
const thing_medikit = 2012
const thing_soulsphere = 2013
const thing_megasphere = 2014
const thing_backpack = 2015
const thing_bfg9000 = 2046
const thing_chaingun = 2047
const thing_chainsaw = 2045
const thing_rocketlauncher = 2048
const thing_plasmarifle = 2049
const thing_shotgun = 2045
const thing_supershotgun = 2046

// Keys
const thing_bluecard = 5
const thing_yellowcard = 6
const thing_redcard = 13
const thing_blueskull = 40
const thing_yellowskull = 39
const thing_redskull = 38

// Armor
const thing_greenarmor = 2018
const thing_bluearmor = 2019

// Powerups
const thing_invulnerability = 2022
const thing_berserk = 2023
const thing_invisibility = 2024
const thing_radsuit = 2025
const thing_map = 2026
const thing_lightamp = 2027

// Check for special things in player's sector and handle pickup
pub fn p_check_player_pickup(player &Player) {
	if player == unsafe { nil } || player.mo == unsafe { nil } {
		return
	}
	mo := player.mo
	if mo.subsector == unsafe { nil } {
		return
	}
	ss := unsafe { &Subsector(mo.subsector) }
	if ss == unsafe { nil } || ss.sector == unsafe { nil } {
		return
	}
	sec := ss.sector
	if sec.thinglist == unsafe { nil } {
		return
	}
	// Iterate through things in the sector
	mut thing := sec.thinglist
	for thing != unsafe { nil } {
		if (thing.flags & mf_special) != 0 && (thing.flags & mf_pickup) != 0 {
			// Check if player is close enough to pick up
			dx := thing.x - mo.x
			dy := thing.y - mo.y
			dist_sq := (dx >> frac_bits) * (dx >> frac_bits) + (dy >> frac_bits) * (dy >> frac_bits)
			// Use radius for pickup check (combine radii, convert back to fixed)
			radius_sum := (mo.radius + thing.radius) >> frac_bits
			if dist_sq <= radius_sum * radius_sum {
				p_touch_thing(thing, mo)
			}
		}
		thing = thing.snext
	}
}

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

pub fn p_touch_thing(thing &Mobj, toucher &Mobj) {
	if thing == unsafe { nil } || toucher == unsafe { nil } {
		return
	}
	// Not pickupable?
	if (thing.flags & mf_special) == 0 {
		return
	}
	// Get player from toucher
	mut player := unsafe { &Player(toucher.player) }
	if player == unsafe { nil } {
		return
	}
	// Dead thing touching
	if toucher.health <= 0 {
		return
	}
	// Check reachability
	delta := thing.z - toucher.z
	if delta > toucher.height || delta < -8 * frac_unit {
		return
	}
	// Get the thing type to identify the item
	mobj_type := thing.mobj_type
	// Handle pickup based on thing type
	match mobj_type {
		// Health
		thing_stimpack {
			p_give_health(player, 10, 100)
		}
		thing_medikit {
			p_give_health(player, 25, 100)
		}
		thing_soulsphere {
			p_give_health(player, 100, 200)
		}
		thing_megasphere {
			p_give_health(player, 200, 200)
			p_give_armor(player, 200)
		}
		// Armor
		thing_greenarmor {
			p_give_armor(player, 100)
		}
		thing_bluearmor {
			p_give_armor(player, 200)
		}
		// Ammo - Clip
		thing_clip {
			dropped := (thing.flags & mf_dropped) != 0
			count := if dropped { 5 } else { 10 }
			p_give_ammo(player, int(AmmoType.clip), count)
		}
		thing_clipbox {
			p_give_ammo(player, int(AmmoType.clip), 50)
		}
		// Ammo - Shell
		thing_shell {
			dropped := (thing.flags & mf_dropped) != 0
			count := if dropped { 2 } else { 4 }
			p_give_ammo(player, int(AmmoType.shell), count)
		}
		thing_shellbox {
			p_give_ammo(player, int(AmmoType.shell), 20)
		}
		// Ammo - Rocket
		thing_rocket {
			p_give_ammo(player, int(AmmoType.misl), 1)
		}
		thing_rocketbox {
			p_give_ammo(player, int(AmmoType.misl), 5)
		}
		// Ammo - Cell
		thing_cell {
			p_give_ammo(player, int(AmmoType.cell), 20)
		}
		thing_cellpack {
			p_give_ammo(player, int(AmmoType.cell), 100)
		}
		// Weapons
		thing_shotgun {
			if player.weaponowned[int(WeaponType.shotgun)] == 0 {
				player.weaponowned[int(WeaponType.shotgun)] = 1
				player.pendingweapon = WeaponType.shotgun
			}
		}
		thing_supershotgun {
			if player.weaponowned[int(WeaponType.supershotgun)] == 0 {
				player.weaponowned[int(WeaponType.supershotgun)] = 1
				player.pendingweapon = WeaponType.supershotgun
			}
		}
		thing_chaingun {
			if player.weaponowned[int(WeaponType.chaingun)] == 0 {
				player.weaponowned[int(WeaponType.chaingun)] = 1
				player.pendingweapon = WeaponType.chaingun
			}
		}
		thing_rocketlauncher {
			if player.weaponowned[int(WeaponType.missile)] == 0 {
				player.weaponowned[int(WeaponType.missile)] = 1
				player.pendingweapon = WeaponType.missile
			}
		}
		thing_plasmarifle {
			if player.weaponowned[int(WeaponType.plasma)] == 0 {
				player.weaponowned[int(WeaponType.plasma)] = 1
				player.pendingweapon = WeaponType.plasma
			}
		}
		thing_bfg9000 {
			if player.weaponowned[int(WeaponType.bfg)] == 0 {
				player.weaponowned[int(WeaponType.bfg)] = 1
				player.pendingweapon = WeaponType.bfg
			}
		}
		thing_chainsaw {
			if player.weaponowned[int(WeaponType.chainsaw)] == 0 {
				player.weaponowned[int(WeaponType.chainsaw)] = 1
				player.pendingweapon = WeaponType.chainsaw
			}
		}
		thing_backpack {
			p_give_backpack(player)
			for i in 0 .. numammo {
				p_give_ammo(player, i, 1)
			}
		}
		// Powerups
		thing_invulnerability {
			p_give_power(player, int(PowerType.invulnerability))
		}
		thing_berserk {
			p_give_power(player, int(PowerType.strength))
		}
		thing_invisibility {
			p_give_power(player, int(PowerType.invisibility))
		}
		thing_radsuit {
			p_give_power(player, int(PowerType.ironfeet))
		}
		thing_map {
			p_give_power(player, int(PowerType.allmap))
		}
		thing_lightamp {
			p_give_power(player, int(PowerType.infrared))
		}
		else {
			// Unknown item type - just ignore
		}
	}
	// Remove the thing if it's a pickup
	if (thing.flags & mf_pickup) != 0 {
		p_remove_mobj(thing)
	}
}
