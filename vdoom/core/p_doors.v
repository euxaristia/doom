module core

pub fn p_doors_do_door_stub(line &Line, doortype int) int {
	typ := unsafe { VlDoorE(doortype) }
	return ev_do_door(line, typ)
}

pub fn p_doors_vertical_door_stub(line &Line, mobj &Mobj) {
	ev_vertical_door(line, mobj)
}

pub fn p_doors_think() {}

pub fn p_doors_vld_door(door &VlDoor) {
	_ = door
}

pub fn p_spawn_door(line &Line) {
	_ = line
}

pub fn p_doors_open_by_id(tag int) {
	_ = tag
}

pub fn p_doors_close_by_id(tag int) {
	_ = tag
}

pub fn p_doors_wait_and_close(line &Line) {
	_ = line
}

pub fn p_doors_explode(line &Line) {
	_ = line
}
