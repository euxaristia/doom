@[translated]
module main

const fracbits = 16
const fracunit = 1 << fracbits

type FixedT = i32

fn int_to_fixed(x int) FixedT {
	return FixedT(x << fracbits)
}

fn fixed_to_int(x FixedT) int {
	return int(x >> fracbits)
}

fn fixed_mul(a FixedT, b FixedT) FixedT {
	return FixedT(i32((i64(a) * i64(b)) >> fracbits))
}

fn fixed_div(a FixedT, b FixedT) FixedT {
	if b == 0 { return 0 }
	return FixedT(i32((i64(a) << fracbits) / i64(b)))
}

fn fixed_abs(x FixedT) FixedT {
	if x < 0 { return -x }
	return x
}
