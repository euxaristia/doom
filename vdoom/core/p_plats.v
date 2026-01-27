module core

pub fn p_plats_do_plat_stub(line &Line, plattype int, amount int) int {
	typ := unsafe { PlatTypeE(plattype) }
	return ev_do_plat(line, typ, amount)
}

pub fn p_plats_activate_in_stasis_stub(tag int) {
	p_activate_in_stasis(tag)
}
