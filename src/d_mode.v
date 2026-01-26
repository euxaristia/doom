@[translated]
module main

enum GameMission {
	doom = 0
	doom2 = 1
	pack_tnt = 2
	pack_plut = 3
	heretic = 4
	hexen = 5
	strife = 6
}

enum GameMode {
	shareware = 0
	registered = 1
	commercial = 2
}

fn C.D_ValidateMissionMode(int, int) bool
fn C.D_MissionName(int) &char

fn d_validate_mission_mode(mission GameMission, mode GameMode) bool {
	return C.D_ValidateMissionMode(int(mission), int(mode))
}

fn d_mission_name(mission GameMission) &char {
	return C.D_MissionName(int(mission))
}
