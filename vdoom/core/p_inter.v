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
	pl.message = 'power ${power} on'
	return true
}

pub fn p_damage_mobj(target &Mobj, inflictor &Mobj, source &Mobj, damage int) {
	_ = target
	_ = inflictor
	_ = source
	_ = damage
}

pub fn p_touch_special_thing(special &Mobj, toucher &Mobj) {
	_ = special
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

pub fn p_player_in_special_sector(player &Player) {
	_ = player
}

pub fn p_touch_other_special_thing(special &Mobj, toucher &Mobj) {
	_ = special
	_ = toucher
}
