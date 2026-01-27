@[has_globals]
module core

pub const st_height = 32
pub const st_width = screenwidth
pub const st_y = screenheight - st_height

pub enum StStateEnum {
	automap_state
	first_person_state
}

pub enum StChatStateEnum {
	start_chat_state
	wait_dest_state
	get_chat_state
}

__global st_backing_screen = []u8{}
__global cheat_mus = CheatSeq{}
__global cheat_god = CheatSeq{}
__global cheat_ammo = CheatSeq{}
__global cheat_ammonokey = CheatSeq{}
__global cheat_noclip = CheatSeq{}
__global cheat_commercial_noclip = CheatSeq{}
__global cheat_powerup = []CheatSeq{len: 7}
__global cheat_choppers = CheatSeq{}
__global cheat_clev = CheatSeq{}
__global cheat_mypos = CheatSeq{}

pub fn st_responder(ev &Event) bool {
	_ = ev
	return false
}

pub fn st_ticker() {}

pub fn st_drawer(fullscreen bool, refresh bool) {
	_ = fullscreen
	_ = refresh
}

pub fn st_start() {}
pub fn st_init() {}
