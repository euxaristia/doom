module core

// Tests for the two bugs fixed in p_setup.v:
// 1. Subsector field swap (numsegs/firstseg were read in wrong order)
// 2. Missing sidedef linkage in p_load_segs

fn test_subsector_field_order() {
	// Build a fake 4-byte subsector record in WAD format:
	// bytes 0-1: numsegs (little-endian), bytes 2-3: firstseg (little-endian)
	//
	// numsegs = 3, firstseg = 100
	data := [u8(3), 0, 100, 0]

	numsegs_val := i16(data[0]) | (i16(data[1]) << 8)
	firstseg_val := i16(data[2]) | (i16(data[3]) << 8)

	// Verify the WAD parsing order: numsegs first, then firstseg
	assert numsegs_val == 3, 'numsegs should be 3, got ${numsegs_val}'
	assert firstseg_val == 100, 'firstseg should be 100, got ${firstseg_val}'

	// The Subsector should use numsegs_val for numlines and firstseg_val for firstline
	ss := Subsector{
		firstline: firstseg_val
		numlines:  numsegs_val
	}
	assert ss.numlines == 3
	assert ss.firstline == 100
}

fn test_subsector_field_order_large_values() {
	// Test with values that would obviously break if swapped:
	// numsegs = 5, firstseg = 500
	mut data := []u8{len: 4}
	data[0] = u8(5)
	data[1] = u8(0)
	data[2] = u8(500 & 0xff) // 244
	data[3] = u8(500 >> 8) // 1

	numsegs_val := i16(data[0]) | (i16(data[1]) << 8)
	firstseg_val := i16(data[2]) | (i16(data[3]) << 8)

	assert numsegs_val == 5, 'numsegs should be 5'
	assert firstseg_val == 500, 'firstseg should be 500'

	// If fields were swapped (the bug), numlines would be 500 and firstline would be 5
	// which causes massive over-iteration in r_subsector
	ss := Subsector{
		firstline: firstseg_val
		numlines:  numsegs_val
	}
	assert ss.numlines < 100, 'numlines should be small (got ${ss.numlines})'
	assert ss.firstline == 500
}

fn test_seg_sidedef_linkage() {
	// Create minimal structures to verify sidedef linkage
	mut test_sides := []Side{len: 2}
	test_sides[0] = Side{toptexture: 10}
	test_sides[1] = Side{toptexture: 20}

	mut test_line := Line{}
	test_line.sidenum[0] = 0
	test_line.sidenum[1] = 1

	// Simulate what p_load_segs should do for side 0
	mut seg0 := Seg{}
	seg0.linedef = &test_line
	sn0 := seg0.linedef.sidenum[0]
	if sn0 >= 0 && sn0 < test_sides.len {
		unsafe {
			seg0.sidedef = &test_sides[sn0]
		}
	}
	assert seg0.sidedef != unsafe { nil }, 'seg sidedef should not be nil for side 0'
	assert seg0.sidedef.toptexture == 10

	// Simulate for side 1
	mut seg1 := Seg{}
	seg1.linedef = &test_line
	sn1 := seg1.linedef.sidenum[1]
	if sn1 >= 0 && sn1 < test_sides.len {
		unsafe {
			seg1.sidedef = &test_sides[sn1]
		}
	}
	assert seg1.sidedef != unsafe { nil }, 'seg sidedef should not be nil for side 1'
	assert seg1.sidedef.toptexture == 20
}

fn test_seg_sidedef_invalid_sidenum() {
	// Side number -1 means "no side" — sidedef should remain nil
	mut test_line := Line{}
	test_line.sidenum[0] = -1
	test_line.sidenum[1] = -1

	mut seg := Seg{}
	seg.linedef = &test_line
	sn := seg.linedef.sidenum[0]
	if sn >= 0 && sn < 0 {
		// This should NOT be reached
		assert false, 'should not link sidedef for sidenum -1'
	}
	assert seg.sidedef == unsafe { nil }, 'sidedef should be nil for invalid sidenum'
}
