@[has_globals]
module core

pub const hu_fontstart = int(`!`)
pub const hu_fontend = int(`_`)
pub const hu_fontsize = hu_fontend - hu_fontstart + 1
pub const hu_broadcast = 5
pub const hu_msgx = 0
pub const hu_msgy = 0
pub const hu_msgwidth = 64
pub const hu_msgheight = 1
pub const hu_msgtimeout = 4 * ticrate

__global chat_macros = []string{len: 10}

pub fn hu_init() {}
pub fn hu_start() {}

pub fn hu_responder(ev &Event) bool {
	_ = ev
	return false
}

pub fn hu_ticker() {}
pub fn hu_drawer() {}

pub fn hu_dequeue_chat_char() u8 {
	return 0
}

pub fn hu_erase() {}
