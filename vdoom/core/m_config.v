@[has_globals]
module core

__global configdir = ''

pub fn m_load_defaults() {
}

pub fn m_save_defaults() {
}

pub fn m_save_defaults_alternate(main string, extra string) {
	_ = main
	_ = extra
}

pub fn m_set_config_dir(dir string) {
	configdir = dir
}

pub fn m_set_music_pack_dir() {
}

pub fn m_bind_int_variable(name string, variable &int) {
	_ = name
	_ = variable
}

pub fn m_bind_float_variable(name string, variable &f32) {
	_ = name
	_ = variable
}

pub fn m_bind_string_variable(name string, variable &string) {
	_ = name
	_ = variable
}

pub fn m_set_variable(name string, value string) bool {
	_ = name
	_ = value
	return false
}

pub fn m_get_int_variable(name string) int {
	_ = name
	return 0
}

pub fn m_get_string_variable(name string) string {
	_ = name
	return ''
}

pub fn m_get_float_variable(name string) f32 {
	_ = name
	return 0.0
}

pub fn m_set_config_filenames(main_config string, extra_config string) {
	_ = main_config
	_ = extra_config
}

pub fn m_get_save_game_dir(iwadname string) string {
	_ = iwadname
	return ''
}

pub fn m_get_autoload_dir(iwadname string) string {
	_ = iwadname
	return ''
}
