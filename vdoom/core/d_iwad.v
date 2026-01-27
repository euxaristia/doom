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

pub fn d_iwad_init(path string) {
	base := os.base(path)
	info := detect_iwad(base) or {
		// Fall back to doom defaults when unknown.
		set_game_identity(.doom, .indetermined, d_game_mission_string(.doom))
		iwad_detected = false
		return
	}
	set_game_identity(info.mission, info.mode, info.description)
	selected_iwad = info
	iwad_detected = true
}

pub fn d_detected_iwad() (bool, string) {
	return iwad_detected, selected_iwad.name
}
