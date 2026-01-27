module core

// Map lump order constants.
pub const ml_label = 0
pub const ml_things = 1
pub const ml_linedefs = 2
pub const ml_sidedefs = 3
pub const ml_vertexes = 4
pub const ml_segs = 5
pub const ml_ssectors = 6
pub const ml_nodes = 7
pub const ml_sectors = 8
pub const ml_reject = 9
pub const ml_blockmap = 10

// Minimal map thing definition used widely by gameplay.
pub struct MapThing {
pub mut:
	x       i16
	y       i16
	angle   i16
	typ     i16
	options i16
}
