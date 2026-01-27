@[has_globals]
module core

__global flat_nums = map[string]int{}
__global texture_nums = map[string]int{}
__global next_flat_num = 0
__global next_texture_num = 0

// Retrieve column data for span blitting.
pub fn r_get_column(tex int, col int) []u8 {
	_ = tex
	_ = col
	return []u8{}
}

// I/O, setting up the stuff.
pub fn r_init_data() {}
pub fn r_precache_level() {}

// Retrieval helpers.
pub fn r_flat_num_for_name(name string) int {
	key := name.to_upper()
	if key in flat_nums {
		return flat_nums[key]
	}
	idx := next_flat_num
	flat_nums[key] = idx
	next_flat_num++
	return idx
}

pub fn r_texture_num_for_name(name string) int {
	key := name.to_upper()
	if key in texture_nums {
		return texture_nums[key]
	}
	idx := next_texture_num
	texture_nums[key] = idx
	next_texture_num++
	return idx
}

pub fn r_check_texture_num_for_name(name string) int {
	key := name.to_upper()
	if key in texture_nums {
		return texture_nums[key]
	}
	return -1
}
