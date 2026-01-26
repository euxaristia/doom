// Copyright(C) 1993-1996 Id Software, Inc.
// Copyright(C) 1993-2008 Raven Software
// Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// DESCRIPTION:
// Configuration file interface.

import os

pub const (
	config_dir_default = '.doom'
)

// Configuration variable types
enum DefaultType {
	int
	int_hex
	string
	float
	key
}

// Single configuration variable
struct ConfigVariable {
	name                string
	value_ptr           voidptr
	var_type            DefaultType
	untranslated        int      // Original value before translation
	original_translated int      // Translated value
	bound               bool     // Has been bound to code
}

// Configuration set
pub struct ConfigSet {
mut:
	variables     map[string]ConfigVariable
	main_config   string
	extra_config  string
	config_dir    string
}

__global config = ConfigSet{
	variables: map[string]ConfigVariable{}
	main_config: 'default.cfg'
	extra_config: ''
	config_dir: config_dir_default
}

pub fn config_dir() string {
	return config.config_dir
}

// Load default configuration from file
pub fn load_defaults() {
	config_path := os.join_path(config.config_dir, config.main_config)

	if os.exists(config_path) {
		content := os.read_file(config_path) or { return }
		lines := content.split('\n')

		for line in lines {
			trimmed := line.trim_space()
			if trimmed == '' || trimmed.starts_with('//') {
				continue
			}

			parts := trimmed.split(' ')
			if parts.len >= 2 {
				key := parts[0]
				value := parts[1..].join(' ')
				set_variable(key, value)
			}
		}
	}
}

// Save defaults to configuration file
pub fn save_defaults() {
	save_defaults_alternate(config.main_config, config.extra_config)
}

// Save to alternate config files
pub fn save_defaults_alternate(main string, extra string) {
	if !os.exists(config.config_dir) {
		os.mkdir_all(config.config_dir) or { return }
	}

	main_path := os.join_path(config.config_dir, main)
	mut content := ''

	// Write configuration variables
	for key, var in config.variables {
		if !var.bound {
			continue
		}

		value_str := match var.var_type {
			.int { (unsafe { &int(var.value_ptr) }).str() }
			.int_hex { '0x' + (unsafe { &int(var.value_ptr) }).hex() }
			.string { unsafe { (&string(var.value_ptr)).str() } }
			.float { (unsafe { &f32(var.value_ptr) }).str() }
			.key { (unsafe { &int(var.value_ptr) }).str() }
		}

		content += '${key} ${value_str}\n'
	}

	os.write_file(main_path, content) or { return }

	if extra != '' {
		extra_path := os.join_path(config.config_dir, extra)
		os.write_file(extra_path, '') or { return }
	}
}

// Bind int variable to configuration system
pub fn bind_int_variable(name string, location &int) {
	config.variables[name] = ConfigVariable{
		name: name
		value_ptr: voidptr(location)
		var_type: .int
		bound: true
	}
}

// Bind float variable to configuration system
pub fn bind_float_variable(name string, location &f32) {
	config.variables[name] = ConfigVariable{
		name: name
		value_ptr: voidptr(location)
		var_type: .float
		bound: true
	}
}

// Bind string variable to configuration system
pub fn bind_string_variable(name string, location &&string) {
	config.variables[name] = ConfigVariable{
		name: name
		value_ptr: voidptr(location)
		var_type: .string
		bound: true
	}
}

// Set a configuration variable by name and value
pub fn set_variable(name string, value string) bool {
	variable := config.variables[name] or {
		return false
	}

	match variable.var_type {
		.int {
			if val := value.int() {
				unsafe { (&int(variable.value_ptr))[] = val }
				return true
			}
			return false
		}
		.int_hex {
			val := if value.starts_with('0x') {
				value.hex() or { return false }
			} else {
				value.int() or { return false }
			}
			unsafe { (&int(variable.value_ptr))[] = val }
			return true
		}
		.float {
			if val := value.f32() {
				unsafe { (&f32(variable.value_ptr))[] = val }
				return true
			}
			return false
		}
		.string {
			unsafe { (&string(variable.value_ptr))[] = value }
			return true
		}
		.key {
			if val := value.int() {
				unsafe { (&int(variable.value_ptr))[] = val }
				return true
			}
			return false
		}
	}
}

// Get int variable value
pub fn get_int_variable(name string) int {
	variable := config.variables[name] or { return 0 }
	if variable.var_type != .int && variable.var_type != .int_hex {
		return 0
	}
	return unsafe { (&int(variable.value_ptr))[] }
}

// Get float variable value
pub fn get_float_variable(name string) f32 {
	variable := config.variables[name] or { return 0.0 }
	if variable.var_type != .float {
		return 0.0
	}
	return unsafe { (&f32(variable.value_ptr))[] }
}

// Get string variable value
pub fn get_string_variable(name string) string {
	variable := config.variables[name] or { return '' }
	if variable.var_type != .string {
		return ''
	}
	return unsafe { (&string(variable.value_ptr))[] }
}

// Set config filenames
pub fn set_config_filenames(main string, extra string) {
	config.main_config = main
	config.extra_config = extra
}

// Set configuration directory
pub fn set_config_dir(dir string) {
	config.config_dir = dir
}

// Get save game directory for IWAD
pub fn get_savegame_dir(iwadname string) string {
	return os.join_path(config.config_dir, 'savegames')
}

// Get autoload directory for IWAD
pub fn get_autoload_dir(iwadname string) string {
	return os.join_path(config.config_dir, 'autoload')
}

// Set music pack directory
pub fn set_music_pack_dir() {
	// Placeholder implementation
}
