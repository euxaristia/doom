@[has_globals]
module core

pub enum WiStateEnum {
	no_state = -1
	stat_count
	show_next_loc
}

__global wi_state = WiStateEnum.no_state
__global wi_count = 0

pub fn wi_ticker() {
	wi_count++
}

pub fn wi_drawer() {}

pub fn wi_start(wbstartstruct &WbStartStruct) {
	_ = wbstartstruct
	wi_state = .stat_count
	wi_count = 0
}

pub fn wi_end() {
	wi_state = .no_state
}
