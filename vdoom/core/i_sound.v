@[has_globals]
module core

pub const norm_pitch = 127

pub struct SfxInfo {
pub:
	tagname string
pub mut:
	name        string
	priority    int
	link        &SfxInfo = unsafe { nil }
	pitch       int
	volume      int
	usefulness  int
	lumpnum     int
	numchannels int
	driver_data voidptr
}

pub struct MusicInfo {
pub:
	name   string
pub mut:
	lumpnum int
	data    voidptr
	handle  voidptr
}

pub enum SndDevice {
	none = 0
	pcspeaker = 1
	adlib = 2
	sb = 3
	pas = 4
	gus = 5
	waveblaster = 6
	soundcanvas = 7
	genmidi = 8
	awe32 = 9
	cd = 10
}

pub struct SoundModule {
pub:
	sound_devices []SndDevice
	num_sound_devices int
}

pub struct MusicModule {
pub:
	sound_devices []SndDevice
	num_sound_devices int
}

pub enum OplDriverVer {
	opl_doom1_1_666
	opl_doom2_1_666
	opl_doom_1_9
}

__global snd_sfxdevice = int(0)
__global snd_musicdevice = int(0)
__global snd_samplerate = int(0)
__global snd_cachesize = int(0)
__global snd_maxslicetime_ms = int(0)
__global snd_musiccmd = ''
__global snd_pitchshift = int(0)

pub fn i_init_sound(use_sfx_prefix bool) {
	_ = use_sfx_prefix
}

pub fn i_shutdown_sound() {
}

pub fn i_get_sfx_lump_num(sfxinfo &SfxInfo) int {
	return sfxinfo.lumpnum
}

pub fn i_update_sound() {
}

pub fn i_update_sound_params(channel int, vol int, sep int) {
	_ = channel
	_ = vol
	_ = sep
}

pub fn i_start_sound(sfxinfo &SfxInfo, channel int, vol int, sep int, pitch int) int {
	_ = sfxinfo
	_ = channel
	_ = vol
	_ = sep
	_ = pitch
	return -1
}

pub fn i_stop_sound(channel int) {
	_ = channel
}

pub fn i_sound_is_playing(channel int) bool {
	_ = channel
	return false
}

pub fn i_precache_sounds(sounds []SfxInfo, num_sounds int) {
	_ = sounds
	_ = num_sounds
}

pub fn i_init_music() {
}

pub fn i_shutdown_music() {
}

pub fn i_set_music_volume(volume int) {
	_ = volume
}

pub fn i_pause_song() {
}

pub fn i_resume_song() {
}

pub fn i_register_song(data voidptr, len int) voidptr {
	_ = data
	_ = len
	return unsafe { nil }
}

pub fn i_unregister_song(handle voidptr) {
	_ = handle
}

pub fn i_play_song(handle voidptr, looping bool) {
	_ = handle
	_ = looping
}

pub fn i_stop_song() {
}

pub fn i_music_is_playing() bool {
	return false
}

pub fn i_bind_sound_variables() {
}

pub fn i_set_opl_driver_ver(ver OplDriverVer) {
	_ = ver
}
