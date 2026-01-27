@[has_globals]
module core

__global maplumpinfo = &LumpInfo(unsafe { nil })
__global level_setup_count = 0
__global last_setup_episode = 0
__global last_setup_map = 0

pub fn p_setup_level(episode int, mapnum int, playermask int, skill int) {
	level_setup_count++
	last_setup_episode = episode
	last_setup_map = mapnum
	gameskill = skill
	gameepisode = episode
	gamemap = mapnum
	_ = playermask
	leveltime = 0
	gamestate = .level
	p_init_thinkers()
}

pub fn p_init() {
	level_setup_count = 0
}
