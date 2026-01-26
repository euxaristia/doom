@[translated]
module main

fn C.PRNG_Start(&u8, int)
fn C.PRNG_Stop()
fn C.PRNG_Random() u32

fn prng_start(seed &u8, seed_len int) { C.PRNG_Start(seed, seed_len) }
fn prng_stop() { C.PRNG_Stop() }
fn prng_random() u32 { return C.PRNG_Random() }
