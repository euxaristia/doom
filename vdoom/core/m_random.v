module core

// Doom expects 0-255 pseudo-random values.
fn next_rand() int {
	rndindex = (rndindex + 1) & 0xff
	// Simple xorshift-like mix on the index for determinism.
	mut x := u32(rndindex)
	x ^= x << 13
	x ^= x >> 17
	x ^= x << 5
	return int(x & 0xff)
}

pub fn m_random() int {
	return next_rand()
}

pub fn p_random() int {
	return next_rand()
}

pub fn m_clear_random() {
	rndindex = 0
}

pub fn p_sub_random() int {
	return p_random() - p_random()
}
