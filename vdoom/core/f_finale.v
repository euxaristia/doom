@[has_globals]
module core

pub enum FinaleStage {
	text
	artscreen
	cast
}

__global finale_stage = FinaleStage.text
__global finale_count = u32(0)

pub const textspeed = 3
pub const textwait = 250

pub fn f_responder(ev &Event) bool {
	_ = ev
	return false
}

pub fn f_ticker() {}
pub fn f_drawer() {}
pub fn f_start_finale() {}
