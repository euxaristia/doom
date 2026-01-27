@[has_globals]
module core

pub enum WiStateEnum {
	no_state = -1
	stat_count
	show_next_loc
}

__global wi_state = WiStateEnum.no_state
__global wi_count = 0
__global wi_finished = false

pub fn wi_ticker() {
	wi_count++
	if wi_state == .stat_count && wi_count > 300 {
		wi_state = .show_next_loc
	}
	if wi_state == .show_next_loc && wi_count > 600 {
		wi_state = .no_state
	}
	if wi_state == .no_state && !wi_finished {
		wi_end()
	}
}

pub fn wi_drawer() {}

pub fn wi_start(wbstartstruct &WbStartStruct) {
	_ = wbstartstruct
	wi_state = .stat_count
	wi_count = 0
	wi_finished = false
	set_game_state(.intermission)
	set_game_action(.nothing)
}

pub fn wi_end() {
	wi_state = .no_state
	wi_finished = true
	set_game_state(.level)
	set_game_action(.loadlevel)
}
