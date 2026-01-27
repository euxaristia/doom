module core

pub fn p_lights_turn_on_stub(line &Line, bright int) {
	ev_light_turn_on(line, bright)
}

pub fn p_lights_start_strobing_stub(line &Line) {
	ev_start_light_strobing(line)
}
