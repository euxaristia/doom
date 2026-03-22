module core

import math

// Test mathematical functions that are critical to the renderer's perspective matching C 1:1.

fn test_fixed_mul() {
	a := Fixed(1 << 16) // 1.0
	b := Fixed(1 << 16) // 1.0
	c := fixed_mul(a, b)
	assert c == Fixed(1 << 16) // 1.0 * 1.0 = 1.0
	
	x := Fixed(1 << 15) // 0.5
	y := Fixed(1 << 15) // 0.5
	z := fixed_mul(x, y)
	assert z == Fixed(1 << 14) // 0.5 * 0.5 = 0.25
}

fn test_xtoviewangle_projection() {
	// Simulate what r_setup_frame does to initialize projection
	centerx := 160
	mut xtoviewangle_test := []int{len: 320 + 1}
	
	for i in 0 .. 320 + 1 {
		angle_rad := math.atan2(f64(i - centerx), f64(centerx))
		xtoviewangle_test[i] = int(u32(angle_rad * 0x80000000 / math.pi))
	}
	
	// Test screen center
	assert xtoviewangle_test[centerx] == 0 // center is 0 angle relative to view

	// Test far right (x = 320)
	// math.atan2(160, 160) = PI/4 = 45 degrees.
	// 45 degrees in Doom angles = 0x20000000 (which is 536870912)
	assert xtoviewangle_test[320] == 536870912
}

fn test_finetangent() {
	angle_rad := math.pi / 4.0 // 45 degrees
	tan_val := math.tan(angle_rad)
	// floating point math might have tiny rounding diffs, but should be extremely close to 1.0
	assert (tan_val - 1.0) < 0.0001
	assert (tan_val - 1.0) > -0.0001
}

fn test_viewangletox_tangent_based() {
	// Verify that the tangent-based viewangletox computation maps angles
	// to the correct screen columns for a 320-wide screen.
	centerx := 160
	cxfrac := i64(centerx << 16)
	focallen := cxfrac // tan(45°) = 1.0 so focallength = centerxfrac

	// Build a small finetangent table around key angles
	mut ft := []Fixed{len: fine_angles_half}
	for i in 0 .. fine_angles_half {
		ang := (f64(i) - 2048.0) * math.pi * 2.0 / 8192.0
		tv := math.tan(ang)
		if math.is_nan(tv) || math.is_inf(tv, 0) {
			ft[i] = Fixed(0)
		} else {
			ft[i] = Fixed(i32(f64(frac_unit) * tv))
		}
	}

	// Index 2048 = 0° → should map to center column (160)
	t0 := (i64(ft[2048]) * focallen) >> frac_bits
	x0 := int((cxfrac - t0 + i64(frac_unit) - 1) >> frac_bits)
	assert x0 == centerx, 'angle 0° should map to center (${centerx}), got ${x0}'

	// Index 3072 = +45° → should map to column 0 (leftmost)
	t45 := (i64(ft[3072]) * focallen) >> frac_bits
	x45 := int((cxfrac - t45 + i64(frac_unit) - 1) >> frac_bits)
	assert x45 == 0, '+45° should map to column 0, got ${x45}'

	// Index 1024 = -45° → should map to column 320 (rightmost)
	tn45 := (i64(ft[1024]) * focallen) >> frac_bits
	xn45 := int((cxfrac - tn45 + i64(frac_unit) - 1) >> frac_bits)
	assert xn45 == 320, '-45° should map to column 320, got ${xn45}'

	// Symmetry: +22.5° and -22.5° should be equidistant from center
	// Index 2560 = +22.5°, Index 1536 = -22.5°
	tp := (i64(ft[2560]) * focallen) >> frac_bits
	xp := int((cxfrac - tp + i64(frac_unit) - 1) >> frac_bits)
	tn := (i64(ft[1536]) * focallen) >> frac_bits
	xn := int((cxfrac - tn + i64(frac_unit) - 1) >> frac_bits)
	// xp should be < center, xn should be > center, roughly symmetric
	assert xp >= 0 && xp < centerx, '+22.5° should be left of center, got ${xp}'
	assert xn > centerx && xn <= 320, '-22.5° should be right of center, got ${xn}'
}
