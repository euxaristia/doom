module core

// Simple FNV-1a style hashing shim used where upstream expects SHA1.
const fnv64_offset = u64(0xcbf29ce484222325)
const fnv64_prime = u64(0x100000001b3)

pub fn hash_init() u64 {
	return fnv64_offset
}

pub fn hash_update_u8(state u64, b u8) u64 {
	mut s := state
	s ^= u64(b)
	s *= fnv64_prime
	return s
}

pub fn hash_update_u32(state u64, v u32) u64 {
	mut s := state
	for i in 0 .. 4 {
		s = hash_update_u8(s, u8((v >> (i * 8)) & 0xff))
	}
	return s
}

pub fn hash_update_str(state u64, s string) u64 {
	mut st := state
	for b in s.bytes() {
		st = hash_update_u8(st, b)
	}
	// Include a separator so adjacent strings do not alias.
	st = hash_update_u8(st, 0xff)
	return st
}

pub fn hash_finish(state u64) u64 {
	return state
}
