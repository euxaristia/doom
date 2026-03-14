@[has_globals]
module core

const di_northeast = -1
const di_northwest = -2
const di_southwest = -3
const di_southeast = -4

pub fn p_enemy_think(mobj &Mobj) {
	_ = mobj
}

pub fn p_spawn_brain_targets() {}
pub fn p_clear_brain_targets() {}

pub fn p_check_melee_range(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_look_forplayers(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_mobj_collision(actor &Mobj, thing &Mobj) bool {
	_ = actor
	_ = thing
	return false
}

pub fn p_move_ai(actor &Mobj) bool {
	_ = actor
	return true
}

pub fn p_chase(actor &Mobj) bool {
	_ = actor
	return true
}

pub fn a_brain_scream(actor &Mobj) {
	_ = actor
}

pub fn a_brain_die(actor &Mobj) {
	_ = actor
}

pub fn a_brain_awake(actor &Mobj) {
	_ = actor
}

pub fn p_revenge_need_player(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_brain_awake(actor &Mobj) {
	_ = actor
}
