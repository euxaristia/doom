@[has_globals]
module core

pub const max_mouse_buttons = 8

__global mouse_acceleration = f32(2.0)
__global mouse_threshold = int(10)
__global novert = int(0)
__global vanilla_keyboard_mapping = int(1)

pub fn i_bind_input_variables() {
}

pub fn i_read_mouse() {
}

pub fn i_start_text_input(x1 int, y1 int, x2 int, y2 int) {
	_ = x1
	_ = y1
	_ = x2
	_ = y2
}

pub fn i_stop_text_input() {
}
