module core

pub fn p_enemy_think(mobj &Mobj) {
	p_noise_alert(mobj, mobj)
}

pub fn p_spawn_brain_targets() {}
pub fn p_clear_brain_targets() {}

pub fn p_check_melee_range(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_check_missile_range(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_move(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_try_walk(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_new_chase_dir(actor &Mobj) {
	_ = actor
}

pub fn p_look(actor &Mobj) bool {
	_ = actor
	return false
}

pub fn p_chase(actor &Mobj) {
	_ = actor
}

pub fn p_face_target(actor &Mobj) {
	_ = actor
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
	_ = actor
}

pub fn a_keen_die(actor &Mobj) {
	_ = actor
}

pub fn a_look(actor &Mobj) {
	_ = actor
}

pub fn a_chase(actor &Mobj) {
	_ = actor
}

pub fn a_face_target(actor &Mobj) {
	_ = actor
}

pub fn a_pos_attack(actor &Mobj) {
	_ = actor
}

pub fn a_spos_attack(actor &Mobj) {
	_ = actor
}

pub fn a_cpos_attack(actor &Mobj) {
	_ = actor
}

pub fn a_cpos_refire(actor &Mobj) {
	_ = actor
}

pub fn a_spid_refire(actor &Mobj) {
	_ = actor
}

pub fn a_bspi_attack(actor &Mobj) {
	_ = actor
}

pub fn a_troop_attack(actor &Mobj) {
	_ = actor
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
	_ = actor
}

pub fn p_revenge_need_player(actor &Mobj) bool {
	_ = actor
	return false
}
