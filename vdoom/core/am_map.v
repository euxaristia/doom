@[has_globals]
module core

pub const am_msgheader = int(`a`) * 16777216 + int(`m`) * 65536
pub const am_msgentered = am_msgheader + int(`e`) * 256
pub const am_msgexited = am_msgheader + int(`x`) * 256

__global cheat_amap = CheatSeq{}

pub fn am_responder(ev &Event) bool {
	_ = ev
	return false
}

pub fn am_ticker() {}
pub fn am_drawer() {}
pub fn am_stop() {}
