module core

// Fixed point math (16.16) ported from m_fixed.c.

pub fn fixed_mul(a Fixed, b Fixed) Fixed {
    return Fixed(i32((i64(a) * i64(b)) >> frac_bits))
}

pub fn fixed_div(a Fixed, b Fixed) Fixed {
    if (i32(abs(a)) >> 14) >= i32(abs(b)) {
        return if (a ^ b) < 0 { int_min } else { int_max }
    }
    return Fixed(i32((i64(a) * i64(1 << frac_bits)) / i64(b)))
}

fn abs(v Fixed) Fixed {
    return if v < 0 { -v } else { v }
}
