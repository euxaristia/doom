module core

pub fn p_doors_do_door_stub(line &Line, doortype int) int {
	typ := unsafe { VlDoorE(doortype) }
	return ev_do_door(line, typ)
}

pub fn p_doors_vertical_door_stub(line &Line, mobj &Mobj) {
	ev_vertical_door(line, mobj)
}
