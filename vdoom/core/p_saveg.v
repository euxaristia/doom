@[has_globals]
module core

pub const savegame_eof = 0x1d
pub const versionsize = 16
pub const savestringsize = 24

__global save_stream = unsafe { nil }
__global savegame_error = false

pub fn p_temp_save_game_file() string { return '' }
pub fn p_save_game_file(slot int) string { _ = slot; return '' }

pub fn p_read_save_game_header() bool { return false }
pub fn p_write_save_game_header(description string) { _ = description }

pub fn p_read_save_game_eof() bool { return false }
pub fn p_write_save_game_eof() {}

pub fn p_archive_players() {}
pub fn p_unarchive_players() {}
pub fn p_archive_world() {}
pub fn p_unarchive_world() {}
pub fn p_archive_thinkers() {}
pub fn p_unarchive_thinkers() {}
pub fn p_archive_specials() {}
pub fn p_unarchive_specials() {}
