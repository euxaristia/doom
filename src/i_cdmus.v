@[translated]
module main

// Hexen CD interface stubs (CD audio is no longer supported).

__global (
	cd_error int
)

@[export: 'I_CDMusInit']
pub fn i_cdmus_init() int {
	eprintln('I_CDMusInit: CD music playback is no longer supported! Please use digital music packs instead.')
	return -1
}

// We cannot print status messages inline during startup; kept for API parity.
@[export: 'I_CDMusPrintStartup']
pub fn i_cdmus_print_startup() {}

@[export: 'I_CDMusPlay']
pub fn i_cdmus_play(track int) int {
	_ = track
	return 0
}

@[export: 'I_CDMusStop']
pub fn i_cdmus_stop() int {
	return 0
}

@[export: 'I_CDMusResume']
pub fn i_cdmus_resume() int {
	return 0
}

@[export: 'I_CDMusSetVolume']
pub fn i_cdmus_set_volume(volume int) int {
	_ = volume
	return 0
}

@[export: 'I_CDMusFirstTrack']
pub fn i_cdmus_first_track() int {
	return 0
}

@[export: 'I_CDMusLastTrack']
pub fn i_cdmus_last_track() int {
	return 0
}

@[export: 'I_CDMusTrackLength']
pub fn i_cdmus_track_length(track_num int) int {
	_ = track_num
	return 0
}
