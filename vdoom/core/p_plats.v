module core

pub fn p_plats_do_plat_stub(line &Line, plattype int, amount int) int {
	typ := unsafe { PlatTypeE(plattype) }
	return ev_do_plat(line, typ, amount)
}

pub fn p_plats_activate_in_stasis_stub(tag int) {
	p_activate_in_stasis(tag)
}

pub fn p_remove_activating_plat(sector &Sector) {
	_ = sector
}

pub fn p_think_activate_elevator(plat &Plat) {
	_ = plat
}

pub fn p_do_plats() {}

pub fn p_move_plat(plat &Plat) {
	_ = plat
}

pub fn p_ticker_plats() {}

pub fn p_spawn_plat(line &Line) {
	_ = line
}

pub fn p_activate_bounce_up(line &Line) {
	_ = line
}

pub fn p_activate_down_by_line(line &Line, tag int) int {
	_ = line
	_ = tag
	return 0
}

pub fn p_activate_up_by_line(line &Line, tag int) int {
	_ = line
	_ = tag
	return 0
}

pub fn p_plats_explode(line &Line) {
	_ = line
}
