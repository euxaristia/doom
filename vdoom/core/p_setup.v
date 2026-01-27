@[has_globals]
module core

__global maplumpinfo = &LumpInfo(unsafe { nil })

pub fn p_setup_level(episode int, mapnum int, playermask int, skill int) {
	_ = episode
	_ = mapnum
	_ = playermask
	_ = skill
}

pub fn p_init() {}
