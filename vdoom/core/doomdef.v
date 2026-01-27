module core

pub const doom_version = 109
pub const doom_191_version = 111
pub const maxplayers = 4
pub const rangecheck = true
pub const mtf_easy = 1
pub const mtf_normal = 2
pub const mtf_hard = 4
pub const mtf_ambush = 8

pub enum GameState {
	level
	intermission
	finale
	demoscreen
}

pub enum GameAction {
	nothing
	loadlevel
	newgame
	loadgame
	savegame
	playdemo
	completed
	victory
	worlddone
	screenshot
}

@[_allow_multiple_values]
pub enum Card {
	bluecard
	yellowcard
	redcard
	blueskull
	yellowskull
	redskull
	numcards
}

@[_allow_multiple_values]
pub enum WeaponType {
	fist
	pistol
	shotgun
	chaingun
	missile
	plasma
	bfg
	chainsaw
	supershotgun
	numweapons
	nochange
}

pub const numweapons = 9

@[_allow_multiple_values]
pub enum AmmoType {
	clip
	shell
	cell
	misl
	numammo
	noammo
}

pub const numammo = 4

@[_allow_multiple_values]
pub enum PowerType {
	invulnerability
	strength
	invisibility
	ironfeet
	allmap
	infrared
	numpowers
}

pub const invulntics = 30 * ticrate
pub const invistics = 60 * ticrate
pub const infratics = 120 * ticrate
pub const irontics = 60 * ticrate
