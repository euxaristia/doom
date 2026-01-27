@[has_globals]
module core

// Command line params
__global nomonsters = false
__global respawnparm = false
__global fastparm = false
__global devparm = false

// Game mode/mission
__global gamemode = GameMode.indetermined
__global gamemission = GameMission.doom
__global gameversion = int(GameVersion.exe_final2)
__global gamevariant = int(GameVariant.vanilla)
__global gamedescription = ''
__global modifiedgame = false
__global iwadfile = ''

// Skill/map selection
__global startskill = 0
__global startepisode = 0
__global startmap = 0
__global startloadgame = -1
__global autostart = false
__global gameskill = 0
__global gameepisode = 0
__global gamemap = 0
__global timelimit = 0
__global respawnmonsters = false
__global netgame = false
__global deathmatch = 0

// Sound parameters
__global sfx_volume = 0
__global music_volume = 0
__global snd_music_device = 0
__global snd_sfx_device = 0
__global snd_desired_music_device = 0
__global snd_desired_sfx_device = 0

// Refresh/status flags
__global statusbaractive = false
__global automapactive = false
__global menuactive = false
__global paused = false
__global viewactive = false
__global nodrawers = false
__global testcontrols = false
__global testcontrols_mousespeed = 0
__global viewangleoffset = 0
__global consoleplayer = 0
__global displayplayer = 0

// Scores/ratings
__global totalkills = 0
__global totalitems = 0
__global totalsecret = 0
__global levelstarttic = 0
__global leveltime = 0

// Demo
__global usergame = false
__global demoplayback = false
__global demorecording = false
__global lowres_turn = false
__global singledemo = false

__global gamestate = GameState.level

// Players/world
__global players = []Player{}
__global playeringame = []bool{}

pub const max_dm_starts = 10
__global deathmatchstarts = []MapThing{}
__global deathmatch_p = &MapThing(unsafe { nil })
__global playerstarts = []MapThing{}
__global playerstartsingame = []bool{}
__global wminfo = WbStartStruct{
	plyr: []WbPlayerStruct{}
}

// Engine internals
__global savegamedir = ''
__global precache = false
__global wipegamestate = GameState.level
__global mouse_sensitivity_cfg = 0
__global bodyqueslot = 0
__global skyflatnum = 0
__global rndindex = 0
__global prndindex = 0
__global netcmds = []TicCmd{}

pub fn set_game_identity(mission GameMission, mode GameMode, description string) {
	gamemission = mission
	gamemode = mode
	gamedescription = description
	modifiedgame = false
}

pub fn game_mission() GameMission {
	return gamemission
}

pub fn game_mode() GameMode {
	return gamemode
}

pub fn game_description() string {
	return gamedescription
}

pub fn logical_game_mission() GameMission {
	return d_logical_mission(gamemission)
}

pub fn set_game_state(state GameState) {
	gamestate = state
}

pub fn game_state() GameState {
	return gamestate
}

pub fn set_modified_game(modified bool) {
	modifiedgame = modified
}

pub fn is_modified_game() bool {
	return modifiedgame
}

pub fn set_intermission_secret(didsecret bool) {
	unsafe {
		wminfo.didsecret = didsecret
	}
}

pub fn set_time_limit(minutes int) {
	timelimit = minutes
}

pub fn set_start_params(skill int, episode int, mapnum int) {
	startskill = skill
	startepisode = episode
	startmap = mapnum
}

fn doomstat_init() {
	if players.len == 0 {
		players = []Player{len: maxplayers}
	}
	if playeringame.len == 0 {
		playeringame = []bool{len: maxplayers}
	}
	if netcmds.len == 0 {
		netcmds = []TicCmd{len: maxplayers}
	}
	if deathmatchstarts.len == 0 {
		deathmatchstarts = []MapThing{len: max_dm_starts}
	}
	if playerstarts.len == 0 {
		playerstarts = []MapThing{len: maxplayers}
	}
	if playerstartsingame.len == 0 {
		playerstartsingame = []bool{len: maxplayers}
	}
	if wminfo.plyr.len == 0 {
		unsafe {
			wminfo.plyr = []WbPlayerStruct{len: maxplayers}
		}
	}
	if gamedescription.len == 0 {
		gamedescription = d_game_mission_string(gamemission)
	}
}
