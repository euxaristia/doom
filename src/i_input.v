@[translated]
module main

// Input binding and text-input hooks.

@[export: 'I_BindInputVariables']
pub fn i_bind_input_variables() {
	// No-op placeholder.
}

@[export: 'I_StartTextInput']
pub fn i_start_text_input(_x1 int, _y1 int, _x2 int, _y2 int) {
	_ = _x1
	_ = _y1
	_ = _x2
	_ = _y2
	// No-op placeholder.
}

@[export: 'I_StopTextInput']
pub fn i_stop_text_input() {
	// No-op placeholder.
}

@[export: 'I_Tactile']
pub fn i_tactile_export(_on int, _off int, _total int) {
	_ = _on
	_ = _off
	_ = _total
	// No-op placeholder.
}
