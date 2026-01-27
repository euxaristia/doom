@[has_globals]
module core

__global teleport_events = 0

pub fn ev_teleport(line &Line, side int, thing &Mobj) int {
	_ = line
	_ = side
	teleport_events++
	// Delegate to the existing movement hook; it is still a stub but keeps flow.
	return if p_teleport_move(thing, Fixed(0), Fixed(0)) { 1 } else { 0 }
}
