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

pub fn f_ticker() {
	finale_count++
	// Minimal finale progression: eventually return to demoscreen.
	if finale_count > u32(textwait * 4) {
		set_game_state(.demoscreen)
		finale_count = 0
	}
}
pub fn f_drawer() {}
pub fn f_start_finale() {
	set_game_state(.finale)
	finale_stage = .text
	finale_count = 0
	set_game_action(.nothing)
}
