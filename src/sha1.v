// Copyright(C) 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
// Portions Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// DESCRIPTION:
// SHA-1 cryptographic hash function implementation.

import encoding.binary

pub const sha1_digest_size = 20

pub type Sha1Digest = [sha1_digest_size]u8

pub struct Sha1Context {
pub mut:
	h0      u32
	h1      u32
	h2      u32
	h3      u32
	h4      u32
	nblocks u32
	buf     [64]u8
	count   int
}

// Constants
const (
	k1 = u32(0x5A827999)
	k2 = u32(0x6ED9EBA1)
	k3 = u32(0x8F1BBCDC)
	k4 = u32(0xCA62C1D6)
)

// Initialize SHA-1 context
pub fn (mut ctx Sha1Context) init() {
	ctx.h0 = 0x67452301
	ctx.h1 = 0xefcdab89
	ctx.h2 = 0x98badcfe
	ctx.h3 = 0x10325476
	ctx.h4 = 0xc3d2e1f0
	ctx.nblocks = 0
	ctx.count = 0
}

// Rotate left
fn rol(x u32, n u32) u32 {
	return (x << n) | (x >> (32 - n))
}

// SHA-1 logical functions
fn f1(x u32, y u32, z u32) u32 {
	return z ^ (x & (y ^ z))
}

fn f2(x u32, y u32, z u32) u32 {
	return x ^ y ^ z
}

fn f3(x u32, y u32, z u32) u32 {
	return (x & y) | (z & (x | y))
}

fn f4(x u32, y u32, z u32) u32 {
	return x ^ y ^ z
}

// Transform message block
fn (mut ctx Sha1Context) transform(data []u8) {
	mut x := [16]u32{}

	// Convert bytes to 32-bit words (big-endian)
	for i := 0; i < 16; i++ {
		x[i] = binary.big_endian_u32(data[i*4..i*4+4])
	}

	mut a := ctx.h0
	mut b := ctx.h1
	mut c := ctx.h2
	mut d := ctx.h3
	mut e := ctx.h4

	// Main loop - 80 rounds
	for i := 0; i < 20; i++ {
		temp := rol(a, 5) + f1(b, c, d) + e + k1 + x[i]
		e = d
		d = c
		c = rol(b, 30)
		b = a
		a = temp
	}

	for i := 20; i < 40; i++ {
		xi := if i < 16 { x[i] } else { rol(x[(i-3)&15] ^ x[(i-8)&15] ^ x[(i-14)&15] ^ x[i&15], 1) }
		temp := rol(a, 5) + f2(b, c, d) + e + k2 + xi
		e = d
		d = c
		c = rol(b, 30)
		b = a
		a = temp
	}

	for i := 40; i < 60; i++ {
		xi := if i < 16 { x[i] } else { rol(x[(i-3)&15] ^ x[(i-8)&15] ^ x[(i-14)&15] ^ x[i&15], 1) }
		temp := rol(a, 5) + f3(b, c, d) + e + k3 + xi
		e = d
		d = c
		c = rol(b, 30)
		b = a
		a = temp
	}

	for i := 60; i < 80; i++ {
		xi := if i < 16 { x[i] } else { rol(x[(i-3)&15] ^ x[(i-8)&15] ^ x[(i-14)&15] ^ x[i&15], 1) }
		temp := rol(a, 5) + f4(b, c, d) + e + k4 + xi
		e = d
		d = c
		c = rol(b, 30)
		b = a
		a = temp
	}

	// Update hash values
	ctx.h0 += a
	ctx.h1 += b
	ctx.h2 += c
	ctx.h3 += d
	ctx.h4 += e
}

// Update hash with data
pub fn (mut ctx Sha1Context) update(data []u8) {
	if ctx.count == 64 {
		// Flush buffer
		ctx.transform(ctx.buf[..])
		ctx.count = 0
		ctx.nblocks++
	}

	if data.len == 0 {
		return
	}

	mut offset := 0

	if ctx.count > 0 {
		// Fill buffer first
		for offset < data.len && ctx.count < 64 {
			ctx.buf[ctx.count] = data[offset]
			ctx.count++
			offset++
		}

		if ctx.count == 64 {
			ctx.transform(ctx.buf[..])
			ctx.count = 0
			ctx.nblocks++
		}
	}

	// Process full blocks
	for offset + 64 <= data.len {
		ctx.transform(data[offset..offset + 64])
		ctx.nblocks++
		offset += 64
	}

	// Buffer remaining bytes
	for offset < data.len {
		ctx.buf[ctx.count] = data[offset]
		ctx.count++
		offset++
	}
}

// Finalize hash and get digest
pub fn (mut ctx Sha1Context) final() Sha1Digest {
	mut digest := Sha1Digest{}

	// Flush buffer
	if ctx.count > 0 || true {
		if ctx.count == 64 {
			ctx.transform(ctx.buf[..])
			ctx.count = 0
		}

		// Pad message
		t := ctx.nblocks
		lsb := (t << 6) + u32(ctx.count)
		msb := t >> 26

		ctx.buf[ctx.count] = 0x80
		ctx.count++

		if ctx.count <= 56 {
			for ctx.count < 56 {
				ctx.buf[ctx.count] = 0
				ctx.count++
			}
		} else {
			for ctx.count < 64 {
				ctx.buf[ctx.count] = 0
				ctx.count++
			}
			ctx.transform(ctx.buf[..])

			for i := 0; i < 56; i++ {
				ctx.buf[i] = 0
			}
		}

		// Append bit count
		bit_count_msb := (msb << 3) | (lsb >> 29)
		bit_count_lsb := lsb << 3

		binary.big_endian_put_u32(mut ctx.buf[56..60], bit_count_msb)
		binary.big_endian_put_u32(mut ctx.buf[60..64], bit_count_lsb)

		ctx.transform(ctx.buf[..])
	}

	// Convert hash to big-endian
	binary.big_endian_put_u32(mut digest[0..4], ctx.h0)
	binary.big_endian_put_u32(mut digest[4..8], ctx.h1)
	binary.big_endian_put_u32(mut digest[8..12], ctx.h2)
	binary.big_endian_put_u32(mut digest[12..16], ctx.h3)
	binary.big_endian_put_u32(mut digest[16..20], ctx.h4)

	return digest
}

// Update with 32-bit integer
pub fn (mut ctx Sha1Context) update_int32(val u32) {
	mut buf := [4]u8{}
	binary.big_endian_put_u32(mut buf[..], val)
	ctx.update(buf[..])
}

// Update with string
pub fn (mut ctx Sha1Context) update_string(str string) {
	ctx.update(str.bytes())
	ctx.update([u8(0)])
}
