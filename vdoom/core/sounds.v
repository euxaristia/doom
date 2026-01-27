@[has_globals]
module core

pub const num_sfx = 109
pub const num_music = 68

pub enum MusicEnum {
	none
	num_music_enum
}

pub enum SfxEnum {
	none
	num_sfx_enum
}

__global s_sfx = []SfxInfo{len: num_sfx}
__global s_music = []MusicInfo{len: num_music}
