@[has_globals]
module core

// Command line params
__global nomonsters = false
__global respawnparm = false
__global fastparm = false
__global devparm = false

// Game mode/mission
__global gamemode = GameMode.indetermined
__global gamemission = GameMission.none
__global gameversion = 0
__global gamevariant = 0
__global gamedescription = ''
__global modifiedgame = false

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
__global players = []voidptr{}
__global playeringame = []bool{}

pub const max_dm_starts = 10
__global deathmatchstarts = []voidptr{}
__global deathmatch_p = unsafe { nil }
__global playerstarts = []voidptr{}
__global playerstartsingame = []bool{}
__global wminfo = unsafe { nil }

// Engine internals
__global savegamedir = ''
__global precache = false
__global wipegamestate = GameState.level
__global mouse_sensitivity = 0
__global bodyqueslot = 0
__global skyflatnum = 0
__global rndindex = 0
__global netcmds = []TicCmd{}
