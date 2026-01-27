module core

pub fn p_ceilng_do_ceiling_stub(line &Line, ceilingtype int) int {
	typ := unsafe { CeilingE(ceilingtype) }
	return ev_do_ceiling(line, typ)
}
