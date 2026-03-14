module core

pub fn p_give_power(player voidptr, power int) bool {
	_ = player
	_ = power
	return false
}

pub fn p_damage_mobj(target &Mobj, inflictor &Mobj, source &Mobj, damage int) {
	_ = target
	_ = inflictor
	_ = source
	_ = damage
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
	_ = actor
}

pub fn a_itemrespawn(actor &Mobj) {
	_ = actor
}

pub fn a_minotaur_sonar(actor &Mobj) {
	_ = actor
}

pub fn p_kill_mobj(target &Mobj, source &Mobj, inflictor &Mobj) {
	_ = target
	_ = source
	_ = inflictor
}

pub fn p_give_backpack(player &Player) {
	_ = player
}

pub fn p_give_weapon(player &Player, weapon int, ammogive int) bool {
	_ = player
	_ = weapon
	_ = ammogive
	return false
}

pub fn p_give_ammo(player &Player, ammo int, ammount int) bool {
	_ = player
	_ = ammo
	_ = ammount
	return false
}

pub fn p_give_health(player &Player, ammount int, max int) bool {
	_ = player
	_ = ammount
	_ = max
	return false
}

pub fn p_give_armor(player &Player, ammount int) bool {
	_ = player
	_ = ammount
	return false
}

pub fn p_give_card(player &Player, card int) bool {
	_ = player
	_ = card
	return false
}

pub fn p_give_key_card(player &Player, key int) bool {
	_ = player
	_ = key
	return false
}

pub fn p_give_body(player &Player, ammount int, max int) bool {
	_ = player
	_ = ammount
	_ = max
	return false
}

pub fn p_give_powerup(player &Player, power int, time int) bool {
	_ = player
	_ = power
	_ = time
	return false
}

pub fn p_touch_thing(thing &Mobj) {
	_ = thing
}
