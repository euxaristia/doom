module core

pub fn p_map_try_move_stub(thing &Mobj, x Fixed, y Fixed) bool {
	return p_try_move(thing, x, y)
}

pub fn p_map_slide_move_stub(mo &Mobj) {
	p_slide_move(mo)
}
