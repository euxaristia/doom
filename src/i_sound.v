@[translated]
module main

// Sound and music system hooks: minimal stubs.

__global (
	mut music_playing bool
	mut music_volume int
	mut opl_dev_messages bool
)

@[export: 'I_BindSoundVariables']
pub fn i_bind_sound_variables() {
	// No-op placeholder.
}

@[export: 'I_InitSound']
pub fn i_init_sound(_use_sfx_prefix bool) {
	_ = _use_sfx_prefix
}

@[export: 'I_InitMusic']
pub fn i_init_music() {
	music_playing = false
	music_volume = 127
}

@[export: 'I_ShutdownSound']
pub fn i_shutdown_sound_export() {}

@[export: 'I_GetSfxLumpNum']
pub fn i_get_sfx_lump_num_export(_sfxinfo &Sfxinfo_t) int {
	_ = _sfxinfo
	return 0
}

@[export: 'I_UpdateSound']
pub fn i_update_sound_export() {}

@[export: 'I_UpdateSoundParams']
pub fn i_update_sound_params_export(_channel int, _vol int, _sep int) {
	_ = _channel
	_ = _vol
	_ = _sep
}

@[export: 'I_StartSound']
pub fn i_start_sound_export(_sfxinfo &Sfxinfo_t, _channel int, _vol int, _sep int, _pitch int) int {
	_ = _sfxinfo
	_ = _channel
	_ = _vol
	_ = _sep
	_ = _pitch
	return 0
}

@[export: 'I_StopSound']
pub fn i_stop_sound_export(_channel int) {
	_ = _channel
}

@[export: 'I_SoundIsPlaying']
pub fn i_sound_is_playing_export(_channel int) bool {
	_ = _channel
	return false
}

@[export: 'I_PrecacheSounds']
pub fn i_precache_sounds_export(_sounds &Sfxinfo_t, _num_sounds int) {
	_ = _sounds
	_ = _num_sounds
}

@[export: 'I_ShutdownMusic']
pub fn i_shutdown_music_export() {
	music_playing = false
}

@[export: 'I_SetMusicVolume']
pub fn i_set_music_volume_export(volume int) {
	music_volume = volume
}

@[export: 'I_PauseSong']
pub fn i_pause_song_export() {
	music_playing = false
}

@[export: 'I_ResumeSong']
pub fn i_resume_song_export() {}

@[export: 'I_RegisterSong']
pub fn i_register_song_export(_data voidptr, _len int) voidptr {
	_ = _data
	_ = _len
	// Return a stable non-nil handle.
	return z_malloc(1, pu_static, unsafe { nil })
}

@[export: 'I_UnRegisterSong']
pub fn i_un_register_song_export(handle voidptr) {
	if handle != unsafe { nil } {
		z_free(handle)
	}
}

@[export: 'I_PlaySong']
pub fn i_play_song_export(_handle voidptr, _looping bool) {
	_ = _handle
	_ = _looping
	music_playing = true
}

@[export: 'I_StopSong']
pub fn i_stop_song_export() {
	music_playing = false
}

@[export: 'I_MusicIsPlaying']
pub fn i_music_is_playing_export() bool {
	return music_playing
}

@[export: 'I_SetOPLDriverVer']
pub fn i_set_opl_driver_ver_export(_ver Opl_driver_ver_t) {
	_ = _ver
}

@[export: 'I_OPL_DevMessages']
pub fn i_opl_dev_messages_export(on bool) {
	opl_dev_messages = on
}
