@[has_globals]
module core

__global detail_level = 0
__global screenblocks = 0

pub fn m_responder(ev &Event) bool {
	_ = ev
	return false
}

pub fn m_ticker() {}
pub fn m_drawer() {}
pub fn m_init() {}
pub fn m_start_control_panel() {}
