@[has_globals]
module core

pub const savegame_eof = 0x1d
pub const versionsize = 16
pub const savestringsize = 24

__global save_stream = unsafe { nil }
__global savegame_error = false
__global last_save_description = ''
__global savegame_serial = 0

pub fn p_temp_save_game_file() string { return '' }
pub fn p_save_game_file(slot int) string { _ = slot; return '' }

pub fn p_read_save_game_header() bool {
	return !savegame_error && last_save_description.len > 0
}

pub fn p_write_save_game_header(description string) {
	last_save_description = description
	savegame_serial++
}

pub fn p_read_save_game_eof() bool {
	return !savegame_error && savegame_serial > 0
}

pub fn p_write_save_game_eof() {
	// Mark that a save completed without wiring a full serializer yet.
	savegame_serial++
}

pub fn p_archive_players() {}
pub fn p_unarchive_players() {}
pub fn p_archive_world() {}
pub fn p_unarchive_world() {}
pub fn p_archive_thinkers() {}
pub fn p_unarchive_thinkers() {}
pub fn p_archive_specials() {}
pub fn p_unarchive_specials() {}
