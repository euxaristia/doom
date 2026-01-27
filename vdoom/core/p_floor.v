@[has_globals]
module core

__global floor_events = 0
__global last_floor_special = 0

pub fn ev_do_floor(line &Line, floortype int) int {
	floor_events++
	last_floor_special = int(line.special)
	_ = floortype
	// Signal that something happened when a special line triggers.
	return if line.special != 0 { 1 } else { 0 }
}
