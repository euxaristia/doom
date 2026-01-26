// Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// DESCRIPTION:
// This implements a cryptographically secure pseudorandom number
// generator for implementing secure demos. The approach taken is to
// use the AES (Rijndael) stream cipher in "counter" mode, encrypting
// an incrementing counter. The cipher key acts as the random seed.

import encoding.binary

const (
	aes_min_key_size = 16
	aes_max_key_size = 32
	aes_keysize_128  = 16
	aes_keysize_192  = 24
	aes_keysize_256  = 32
	aes_block_size   = 16
)

pub type PrngSeed = [16]u8

// AES context for PRNG
struct AesContext {
mut:
	key_enc    []u32 // Encryption key schedule
	key_dec    []u32 // Decryption key schedule
	key_length int
}

// PRNG state
struct PrngState {
mut:
	enabled        bool
	context        AesContext
	input_counter  u32
	values         [4]u32
	value_index    int
}

__global prng_state = PrngState{
	enabled: false
	value_index: 4
}

// Start PRNG with a 128-bit key
pub fn prng_start(key PrngSeed) {
	prng_state.context = AesContext{
		key_enc: []u32{len: 60}
		key_dec: []u32{len: 60}
		key_length: 0
	}

	// Set the key for the AES cipher
	prng_state.context.key_length = 16
	for i := 0; i < 4; i++ {
		val := binary.little_endian_u32(key[i*4..i*4+4])
		prng_state.context.key_enc[i] = val
		prng_state.context.key_dec[60 - 4 + i] = val
	}

	prng_state.value_index = 4
	prng_state.input_counter = 0
	prng_state.enabled = true
}

// Stop PRNG
pub fn prng_stop() {
	prng_state.enabled = false
}

// Generate a new block of PRNG values
fn prng_generate() {
	if !prng_state.enabled {
		return
	}

	mut input := [16]u8{}
	for i := 0; i < 4; i++ {
		val := prng_state.input_counter
		input[4*i] = u8(val & 0xff)
		input[4*i + 1] = u8((val >> 8) & 0xff)
		input[4*i + 2] = u8((val >> 16) & 0xff)
		input[4*i + 3] = u8((val >> 24) & 0xff)
		prng_state.input_counter++
	}

	// In a full implementation, this would call AES_Encrypt
	// For now, we provide a placeholder that uses the input as-is
	// A real implementation would include the AES encryption algorithm
	for i := 0; i < 4; i++ {
		val := binary.little_endian_u32(input[i*4..i*4+4])
		prng_state.values[i] = val
	}

	prng_state.value_index = 0
}

// Get a random 32-bit integer from PRNG
pub fn prng_random() u32 {
	if !prng_state.enabled {
		return 0
	}

	if prng_state.value_index >= 4 {
		prng_generate()
	}

	result := prng_state.values[prng_state.value_index]
	prng_state.value_index++

	return result
}
