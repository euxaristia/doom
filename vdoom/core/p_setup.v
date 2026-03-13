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
	set_game_state(.level)
	p_init_thinkers()
	r_init_data()
	p_pspr_init()
	p_apply_time_limit()
	v_clear_screen(0)
	_ = r_patch_num_for_name('TITLEPIC')
}

pub fn p_init() {
	level_setup_count = 0
}

pub fn p_load_vertexes(lump int) {
	_ = lump
}

pub fn p_load_sectors(lump int) {
	_ = lump
}

pub fn p_load_sidedefs(lump int) {
	_ = lump
}

pub fn p_load_linedefs(lump int) {
	_ = lump
}

pub fn p_load_segs(lump int) {
	_ = lump
}

pub fn p_load_subsectors(lump int) {
	_ = lump
}

pub fn p_load_nodes(lump int) {
	_ = lump
}

pub fn p_load_blockmap(lump int) {
	_ = lump
}

pub fn p_load_reject(lump int) {
	_ = lump
}

pub fn p_group_lines() {}

pub fn p_spawn_map_thing(mthing voidptr) {
	_ = mthing
}

pub fn p_get_num_for_map(episode int, mapnum int) int {
	_ = episode
	_ = mapnum
	return 0
}

pub fn p_remove_slime_trails() {}

pub fn p_check_lump_for_emerald() {
	// Check if level has emerald
}
