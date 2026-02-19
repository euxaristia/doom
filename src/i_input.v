@[translated]
module main

// Input binding and text-input hooks.

@[weak]
__global (
	mut text_input_enabled       = true
	mut novert                  = int(1)
	mut vanilla_keyboard_mapping = int(1)
	mut mouse_acceleration      = f32(2.0)
	mut mouse_threshold         = int(10)
	mut mouse_acceleration_y    = f32(1.0)
	mut mouse_threshold_y       = int(0)
	mut mouse_y_invert          = int(0)
	mut runcentering            = int(1)
)

@[c: 'M_BindFloatVariable']
fn m_bind_float_variable(name &i8, variable &f32)

@[export: 'I_BindInputVariables']
pub fn i_bind_input_variables() {
	m_bind_float_variable(c'mouse_acceleration', &mouse_acceleration)
	m_bind_int_variable(c'mouse_threshold', &mouse_threshold)
	m_bind_int_variable(c'vanilla_keyboard_mapping', &vanilla_keyboard_mapping)
	m_bind_int_variable(c'novert', &novert)
	m_bind_float_variable(c'mouse_acceleration_y', &mouse_acceleration_y)
	m_bind_int_variable(c'mouse_threshold_y', &mouse_threshold_y)
	m_bind_int_variable(c'mouse_y_invert', &mouse_y_invert)
}

@[export: 'I_BindStrifeInputVariables']
pub fn i_bind_strife_input_variables() {
	m_bind_int_variable(c'runcentering', &runcentering)
}

@[export: 'I_StartTextInput']
pub fn i_start_text_input(_x1 int, _y1 int, _x2 int, _y2 int) {
	_ = _x1
	_ = _y1
	_ = _x2
	_ = _y2
	text_input_enabled = true
}

@[export: 'I_StopTextInput']
pub fn i_stop_text_input() {
	text_input_enabled = false
}

@[export: 'I_Tactile']
pub fn i_tactile_export(_on int, _off int, _total int) {
	_ = _on
	_ = _off
	_ = _total
	// No-op placeholder.
}
