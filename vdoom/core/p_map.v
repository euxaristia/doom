@[has_globals]
module core

const mf_momx = 0x20000
const mf_momy = 0x40000

const ml_blocking = 0x1
const ml_blockmonsters = 0x8

__global tmthing &Mobj
__global tmflags int
__global tmx Fixed
__global tmy Fixed
__global tmbbox [4]Fixed
__global tmdropoffz Fixed

pub fn p_thing_height_clip(thing &Mobj) bool {
	_ = thing
	return true
}

pub fn p_check_thing2(thing &Mobj) bool {
	_ = thing
	return false
}

pub fn p_unblock_mobj(thing &Mobj) {
	_ = thing
}

pub fn p_block_linesearch(flags int, fn_n &int) {
	_ = flags
	_ = fn_n
}

pub fn p_block_thingssearch(flags int, fn_n &int) {
	_ = flags
	_ = fn_n
}

pub fn p_check_line_side(ld &Line, x Fixed, y Fixed) int {
	_ = ld
	_ = x
	_ = y
	return 0
}

pub fn p_check_position_impl(thing &Mobj, x Fixed, y Fixed) bool {
	_ = thing
	_ = x
	_ = y
	return true
}

pub fn p_try_move_impl(thing &Mobj, x Fixed, y Fixed) bool {
	_ = thing
	_ = x
	_ = y
	return true
}

pub fn p_teleport_move_impl(thing &Mobj, x Fixed, y Fixed) bool {
	_ = thing
	_ = x
	_ = y
	return false
}

pub fn p_slide_move_impl(mo &Mobj) {
	_ = mo
}

pub fn p_thing_height_clip_impl(thing &Mobj) bool {
	_ = thing
	return true
}
