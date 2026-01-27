module core

pub fn p_map_try_move_stub(thing &Mobj, x Fixed, y Fixed) bool {
	_ = thing
	_ = x
	_ = y
	return true
}

pub fn p_map_slide_move_stub(mo &Mobj) {
	_ = mo
}
