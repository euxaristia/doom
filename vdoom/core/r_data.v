module core

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
	_ = name
	return -1
}

pub fn r_texture_num_for_name(name string) int {
	_ = name
	return -1
}

pub fn r_check_texture_num_for_name(name string) int {
	_ = name
	return -1
}
