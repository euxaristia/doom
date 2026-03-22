@[translated]
module main

// Joystick binding and init hooks.

const num_virtual_buttons = 17

@[weak]
__global (
	joystick_initialized        bool
	usejoystick                = int(0)
	use_gamepad                = int(0)
	gamepad_type               = int(0)
	joystick_guid              = &u8(c'')
	joystick_index             = int(-1)
	joystick_x_axis            = int(0)
	joystick_x_invert          = int(0)
	joystick_y_axis            = int(1)
	joystick_y_invert          = int(0)
	joystick_strafe_axis       = int(-1)
	joystick_strafe_invert     = int(0)
	joystick_look_axis         = int(-1)
	joystick_look_invert       = int(0)
	joystick_x_dead_zone       = int(33)
	joystick_y_dead_zone       = int(33)
	joystick_strafe_dead_zone  = int(33)
	joystick_look_dead_zone    = int(33)
	use_analog                 = int(1)
	joystick_turn_sensitivity  = int(10)
	joystick_move_sensitivity  = int(10)
	joystick_look_sensitivity  = int(10)
	joystick_physical_buttons  = [num_virtual_buttons]int{init: index}
)

@[export: 'I_BindJoystickVariables']
pub fn i_bind_joystick_variables() {
	m_bind_int_variable(c'use_joystick', &usejoystick)
	m_bind_int_variable(c'use_gamepad', &use_gamepad)
	m_bind_int_variable(c'gamepad_type', &gamepad_type)
	m_bind_string_variable(c'joystick_guid', &joystick_guid)
	m_bind_int_variable(c'joystick_index', &joystick_index)
	m_bind_int_variable(c'joystick_x_axis', &joystick_x_axis)
	m_bind_int_variable(c'joystick_y_axis', &joystick_y_axis)
	m_bind_int_variable(c'joystick_strafe_axis', &joystick_strafe_axis)
	m_bind_int_variable(c'joystick_x_invert', &joystick_x_invert)
	m_bind_int_variable(c'joystick_y_invert', &joystick_y_invert)
	m_bind_int_variable(c'joystick_strafe_invert', &joystick_strafe_invert)
	m_bind_int_variable(c'joystick_look_axis', &joystick_look_axis)
	m_bind_int_variable(c'joystick_look_invert', &joystick_look_invert)
	m_bind_int_variable(c'joystick_x_dead_zone', &joystick_x_dead_zone)
	m_bind_int_variable(c'joystick_y_dead_zone', &joystick_y_dead_zone)
	m_bind_int_variable(c'joystick_strafe_dead_zone', &joystick_strafe_dead_zone)
	m_bind_int_variable(c'joystick_look_dead_zone', &joystick_look_dead_zone)
	m_bind_int_variable(c'use_analog', &use_analog)
	m_bind_int_variable(c'joystick_turn_sensitivity', &joystick_turn_sensitivity)
	m_bind_int_variable(c'joystick_move_sensitivity', &joystick_move_sensitivity)
	m_bind_int_variable(c'joystick_look_sensitivity', &joystick_look_sensitivity)
	for i := 0; i < joystick_physical_buttons.len; i++ {
		name := 'joystick_physical_button${i}'
		m_bind_int_variable(name.str, &joystick_physical_buttons[i])
	}
}

@[export: 'I_InitJoystick']
pub fn i_init_joystick() {
	joystick_initialized = usejoystick != 0
}

@[export: 'I_UpdateJoystick']
pub fn i_update_joystick() {
	if !joystick_initialized {
		return
	}
	// Input backend polling is not implemented in this baseline port.
}

@[export: 'I_ShutdownJoystick']
pub fn i_shutdown_joystick() {
	joystick_initialized = false
}
