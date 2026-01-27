@[has_globals]
module core

// Fast deterministic PRNG shim for aes_prng.c functionality.
__global prng_state = u64(0x9e3779b97f4a7c15)

pub fn aes_prng_seed(seed u64) {
	prng_state = if seed == 0 { u64(0x9e3779b97f4a7c15) } else { seed }
}

fn prng_next_u64() u64 {
	// xorshift64*
	mut x := prng_state
	x ^= x >> 12
	x ^= x << 25
	x ^= x >> 27
	prng_state = x
	return x * u64(0x2545f4914f6cdd1d)
}

pub fn aes_prng_random_u32() u32 {
	return u32(prng_next_u64() >> 32)
}

pub fn aes_prng_random_byte() u8 {
	return u8(prng_next_u64() & 0xff)
}

pub fn aes_prng_random_range(max u32) u32 {
	if max == 0 {
		return 0
	}
	return aes_prng_random_u32() % max
}
