module core

pub fn p_approx_distance(dx Fixed, dy Fixed) Fixed {
	mut adx := abs(dx)
	mut ady := abs(dy)
	if adx < ady {
		return adx + ady - (adx >> 1)
	}
	return adx + ady - (ady >> 1)
}
