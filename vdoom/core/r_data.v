@[has_globals]
module core

import math

__global patch_nums = map[string]int{}
__global next_patch_num = 0

// Retrieve column data for span blitting.
pub fn r_get_column(tex int, col int) []u8 {
	_ = tex
	_ = col
	return []u8{}
}

// I/O, setting up the stuff.
pub fn r_init_data() {
    // Initialize sine/cosine tables
    println('r_init_data: finesine.len=${finesine.len}')
    if finesine.len == 0 {
        println('r_init_data: initializing tables...')
        finesine = []Fixed{len: fine_angles}
        finecosine = []Fixed{len: fine_angles}
        
        for i in 0 .. fine_angles {
            angle := f64(i) * 2.0 * 3.141592653589793 / f64(fine_angles)
            finesine[i] = Fixed(i32(f64(1 << frac_bits) * f64(math.sin(angle))))
            finecosine[i] = Fixed(i32(f64(1 << frac_bits) * f64(math.cos(angle))))
        }
        println('r_init_data: tables initialized, len=${finesine.len}')
    }
}
pub fn r_precache_level() {}

// Retrieval helpers.
pub fn r_flat_num_for_name(name string) int {
	return get_flat_num_for_name(name)
}

pub fn r_texture_num_for_name(name string) int {
	return get_wall_texture_num_for_name(name)
}

pub fn r_check_texture_num_for_name(name string) int {
	return get_wall_texture_num_for_name(name)
}

pub fn r_patch_num_for_name(name string) int {
	key := name.to_upper()
	if key in patch_nums {
		return patch_nums[key]
	}
	idx := next_patch_num
	patch_nums[key] = idx
	next_patch_num++
	return idx
}
