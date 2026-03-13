module core

pub fn p_check_sight_stub(t1 &Mobj, t2 &Mobj) bool {
	return p_check_sight(t1, t2)
}

pub fn p_check_sight(t1 &Mobj, t2 &Mobj) bool {
	if t1 == unsafe { nil } || t2 == unsafe { nil } {
		return false
	}
	return true
}

pub fn p_line_to_intercept(line &Line, p_x Fixed, p_y Fixed, p_z Fixed, p_dz Fixed) Fixed {
	_ = line
	_ = p_x
	_ = p_y
	_ = p_z
	_ = p_dz
	return Fixed(0)
}

pub fn p_sight_check_line(ln int) bool {
	_ = ln
	return false
}

pub fn p_sight_glob_z(z Fixed) bool {
	_ = z
	return true
}
