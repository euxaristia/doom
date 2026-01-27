module core

pub fn p_approx_distance(dx Fixed, dy Fixed) Fixed {
	mut adx := abs(dx)
	mut ady := abs(dy)
	if adx < ady {
		return adx + ady - (adx >> 1)
	}
	return adx + ady - (ady >> 1)
}

pub fn p_point_on_line_side_impl(x Fixed, y Fixed, line &Line) int {
	if line.dx == 0 {
		if x <= line.v1.x {
			return if line.dy > 0 { 1 } else { 0 }
		}
		return if line.dy < 0 { 1 } else { 0 }
	}
	if line.dy == 0 {
		if y <= line.v1.y {
			return if line.dx < 0 { 1 } else { 0 }
		}
		return if line.dx > 0 { 1 } else { 0 }
	}
	dx := x - line.v1.x
	dy := y - line.v1.y
	left := fixed_mul(line.dy >> frac_bits, dx)
	right := fixed_mul(dy, line.dx >> frac_bits)
	return if right < left { 0 } else { 1 }
}

pub fn p_box_on_line_side_impl(tmbox []Fixed, ld &Line) int {
	mut p1 := 0
	mut p2 := 0
	match ld.slopetype {
		.horizontal {
			p1 = if tmbox[box_top] > ld.v1.y { 1 } else { 0 }
			p2 = if tmbox[box_bottom] > ld.v1.y { 1 } else { 0 }
			if ld.dx < 0 {
				p1 ^= 1
				p2 ^= 1
			}
		}
		.vertical {
			p1 = if tmbox[box_right] < ld.v1.x { 1 } else { 0 }
			p2 = if tmbox[box_left] < ld.v1.x { 1 } else { 0 }
			if ld.dy < 0 {
				p1 ^= 1
				p2 ^= 1
			}
		}
		.positive {
			p1 = p_point_on_line_side_impl(tmbox[box_left], tmbox[box_top], ld)
			p2 = p_point_on_line_side_impl(tmbox[box_right], tmbox[box_bottom], ld)
		}
		.negative {
			p1 = p_point_on_line_side_impl(tmbox[box_right], tmbox[box_top], ld)
			p2 = p_point_on_line_side_impl(tmbox[box_left], tmbox[box_bottom], ld)
		}
	}
	return if p1 == p2 { p1 } else { -1 }
}
