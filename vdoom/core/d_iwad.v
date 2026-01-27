@[has_globals]
module core

import os

struct IwadInfo {
	name        string
	mission     GameMission
	mode        GameMode
	description string
}

const iwads = [
	IwadInfo{name: 'doom2.wad', mission: .doom2, mode: .commercial, description: 'Doom II'},
	IwadInfo{name: 'plutonia.wad', mission: .pack_plut, mode: .commercial, description: 'Final Doom: Plutonia'},
	IwadInfo{name: 'tnt.wad', mission: .pack_tnt, mode: .commercial, description: 'Final Doom: TNT'},
	IwadInfo{name: 'doom.wad', mission: .doom, mode: .retail, description: 'Doom'},
	IwadInfo{name: 'doom1.wad', mission: .doom, mode: .shareware, description: 'Doom Shareware'},
	IwadInfo{name: 'chex.wad', mission: .pack_chex, mode: .retail, description: 'Chex Quest'},
	IwadInfo{name: 'hacx.wad', mission: .pack_hacx, mode: .commercial, description: 'Hacx'},
	IwadInfo{name: 'freedoom2.wad', mission: .doom2, mode: .commercial, description: 'Freedoom: Phase 2'},
	IwadInfo{name: 'freedoom1.wad', mission: .doom, mode: .retail, description: 'Freedoom: Phase 1'},
	IwadInfo{name: 'freedm.wad', mission: .doom2, mode: .commercial, description: 'FreeDM'},
	IwadInfo{name: 'heretic.wad', mission: .heretic, mode: .retail, description: 'Heretic'},
	IwadInfo{name: 'heretic1.wad', mission: .heretic, mode: .shareware, description: 'Heretic Shareware'},
	IwadInfo{name: 'hexen.wad', mission: .hexen, mode: .commercial, description: 'Hexen'},
	IwadInfo{name: 'strife1.wad', mission: .strife, mode: .commercial, description: 'Strife'},
]

__global selected_iwad = IwadInfo{}
__global iwad_detected = false
__global iwad_path = ''

pub fn d_is_iwad_name(name string) bool {
	lower := name.to_lower()
	for info in iwads {
		if lower == info.name {
			return true
		}
	}
	return false
}

fn detect_iwad(name string) ?IwadInfo {
	lower := name.to_lower()
	for info in iwads {
		if lower == info.name {
			return info
		}
	}
	return none
}

fn d_iwad_search_dirs() []string {
	mut dirs := []string{}
	env := os.getenv('DOOM_WADDIR')
	if env.len > 0 {
		dirs << env
	}
	dirs << os.join_path(os.getwd(), 'wads')
	dirs << os.getwd()
	return dirs
}

pub fn d_find_iwad() string {
	env_wad := os.getenv('DOOM_WAD')
	if env_wad.len > 0 && os.is_file(env_wad) {
		return env_wad
	}
	for dir in d_iwad_search_dirs() {
		for info in iwads {
			candidate := os.join_path(dir, info.name)
			if os.is_file(candidate) {
				return candidate
			}
		}
	}
	return ''
}

pub fn d_auto_iwad_init() string {
	path := d_find_iwad()
	if path.len > 0 {
		d_iwad_init(path)
	}
	return path
}

pub fn d_iwad_init_from_env() string {
	path := d_find_iwad()
	if path.len == 0 {
		return ''
	}
	d_iwad_init(path)
	return path
}

pub fn d_iwad_init(path string) {
	base := os.base(path)
	info := detect_iwad(base) or {
		// Fall back to doom defaults when unknown.
		set_game_identity(.doom, .indetermined, d_game_mission_string(.doom))
		iwad_detected = false
		iwad_path = ''
		return
	}
	set_game_identity(info.mission, info.mode, info.description)
	selected_iwad = info
	iwad_detected = true
	iwad_path = path
}

pub fn d_detected_iwad() (bool, string) {
	return iwad_detected, selected_iwad.name
}

pub fn d_iwad_description() string {
	if !iwad_detected {
		return ''
	}
	return selected_iwad.description
}

pub fn d_iwad_path() string {
	return iwad_path
}

pub fn d_iwad_title() string {
	if iwad_detected && selected_iwad.description.len > 0 {
		return selected_iwad.description
	}
	return 'DOOM'
}
