module core

pub fn p_switch_change_texture_stub(line &Line, use_again int) {
	p_change_switch_texture(line, use_again)
}

pub fn p_switch_use_special_line_stub(mobj &Mobj, line &Line, side int) bool {
	return p_use_special_line(mobj, line, side)
}
