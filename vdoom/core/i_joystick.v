@[has_globals]
module core

pub const num_virtual_buttons = 11
pub const button_axis = 0x10000
pub const hat_axis = 0x20000
pub const hat_axis_horizontal = 1
pub const hat_axis_vertical = 2

pub fn is_button_axis(axis int) bool {
	return axis >= 0 && (axis & button_axis) != 0
}

pub fn button_axis_neg(axis int) int {
	return axis & 0xff
}

pub fn button_axis_pos(axis int) int {
	return (axis >> 8) & 0xff
}

pub fn create_button_axis(neg int, pos int) int {
	return button_axis | neg | (pos * 256)
}

pub fn is_hat_axis(axis int) bool {
	return axis >= 0 && (axis & hat_axis) != 0
}

pub fn hat_axis_hat(axis int) int {
	return axis & 0xff
}

pub fn hat_axis_direction(axis int) int {
	return (axis >> 8) & 0xff
}

pub fn create_hat_axis(hat int, direction int) int {
	return hat_axis | hat | (direction * 256)
}

__global usejoystick = int(0)
__global joystick_guid = ''
__global joystick_index = int(-1)
__global joystick_x_axis = int(0)
__global joystick_x_invert = int(0)
__global joystick_y_axis = int(1)
__global joystick_y_invert = int(0)
__global joystick_strafe_axis = int(-1)
__global joystick_strafe_invert = int(0)
__global joystick_look_axis = int(-1)
__global joystick_look_invert = int(0)
__global joystick_physical_buttons = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

pub fn i_init_joystick() {
}

pub fn i_shutdown_joystick() {
}

pub fn i_update_joystick() {
}

pub fn i_bind_joystick_variables() {
}
