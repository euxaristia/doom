@[has_globals]
module core

__global floor_events = 0
__global last_floor_special = 0

pub fn ev_do_floor(line &Line, floortype int) int {
	floor_events++
	last_floor_special = int(line.special)
	_ = floortype
	return if line.special != 0 { 1 } else { 0 }
}

pub enum FloorTypeE {
	floor_lower = 0
	floor_raise = 1
	floor_lower_and_change = 2
	floor_raise_and_change = 3
	floor_change = 4
	floor_raise_to_nearest = 5
	floor_raise_and_crusher = 6
	floor_raise_stair_up = 7
	floor_lower_stair_down = 8
	floor_lower_to_nearest = 9
	floor_lower_to_lowest = 10
	floor_lower_to_highest = 11
	floor_lower_by_texture = 12
	floor_raise_by_texture = 13
}

pub struct Floor {
pub mut:
	type_   FloorTypeE
	sector  &Sector = unsafe { nil }
	crush   bool
	dir     int
	newspecial int
	texture int
	speed   Fixed
}

pub fn p_spawn_floor(line &Line) {
	_ = line
}

pub fn p_floor_think() {}

pub fn p_move_floor(floor &Floor) {
	_ = floor
}

pub fn p_do_floors() {}

pub fn p_floor_explode(line &Line) {
	_ = line
}

pub fn p_build_stair(line &Line, stair_type int) {
	_ = line
	_ = stair_type
}

pub fn p_floor_open_by_id(tag int) {
	_ = tag
}

pub fn p_floor_close_by_id(tag int) {
	_ = tag
}

pub fn p_floor_hit_sector(sector &Sector) {
	_ = sector
}
