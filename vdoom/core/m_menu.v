@[has_globals]
module core

__global detail_level = 0
__global screenblocks = 0
__global mouse_sensitivity = 5
__global show_messages = 1
__global inhelpscreens = false
__global quick_save_slot = -1
__global message_to_print = 0
__global message_string = ''
__global message_needs_input = false
__global save_string_enter = 0
__global save_slot = 0
__global save_char_index = 0

pub fn m_responder(ev &Event) bool {
	_ = ev
	return false
}

pub fn m_ticker() {}
pub fn m_drawer() {}
pub fn m_init() {}
pub fn m_start_control_panel() {}
