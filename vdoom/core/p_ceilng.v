module core

pub fn p_ceilng_do_ceiling_stub(line &Line, ceilingtype int) int {
	typ := unsafe { CeilingE(ceilingtype) }
	return ev_do_ceiling(line, typ)
}

pub fn p_spawn_ceiling(line &Line) {
	_ = line
}

pub fn p_ceilng_think() {}

pub fn p_move_ceiling(ceiling &Ceiling) {
	_ = ceiling
}

pub fn p_do_ceilings() {}

pub fn p_ceilng_explode(line &Line) {
	_ = line
}

pub fn p_ceilng_open_by_id(tag int) {
	_ = tag
}

pub fn p_ceilng_close_by_id(tag int) {
	_ = tag
}
