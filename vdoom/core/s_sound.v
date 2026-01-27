@[has_globals]
module core

__global snd_channels = 0

pub fn s_init(sfx_volume int, music_volume int) {
	_ = sfx_volume
	_ = music_volume
}

pub fn s_shutdown() {}
pub fn s_start() {}

pub fn s_start_sound(origin voidptr, sound_id int) {
	_ = origin
	_ = sound_id
}

pub fn s_stop_sound(origin &Mobj) {
	_ = origin
}

pub fn s_start_music(music_id int) {
	_ = music_id
}

pub fn s_change_music(music_id int, looping int) {
	_ = music_id
	_ = looping
}

pub fn s_music_playing() bool {
	return false
}

pub fn s_stop_music() {}
pub fn s_pause_sound() {}
pub fn s_resume_sound() {}

pub fn s_update_sounds(listener &Mobj) {
	_ = listener
}

pub fn s_set_music_volume(volume int) {
	_ = volume
}

pub fn s_set_sfx_volume(volume int) {
	_ = volume
}
