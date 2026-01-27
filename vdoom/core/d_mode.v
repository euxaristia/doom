module core

pub enum GameMode {
	shareware
	registered
	commercial
	retail
	indetermined
}

pub enum GameMission {
	none
	doom
	doom2
	tnt
	plutonia
}

pub enum GameVersion {
	exe_doom_1_2
	exe_doom_1_666
	exe_doom_1_7
	exe_doom_1_8
	exe_doom_1_9
	exe_hacx
	exe_ultimate
	exe_final
	exe_final2
	exe_chex
}

pub enum GameVariant {
	vanilla
	freedoom
	freedm
	bfgedition
}
