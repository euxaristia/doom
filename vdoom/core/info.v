module core

// Frame flags
pub const ff_solid = 0x8000
pub const ff_transmask = 0x7fff

pub enum SpriteNum {
	spritesentinel
	spr_troo
	spr_shtg
	spr_pist
	spr_shot
	spr_sg08
	spr_sgn2
	spr_chg
	sflmig
	spr_mgng
	spr_laun
	spr_plsm
	spr_bfgg
	spr_saw_
	spr_baxe
	spr_bpian
	spr_sarm
	spr_hlm1
	spr_hlm2
	spr_hlm3
	spr_hlm4
	spr_misl
	spr_bolt
	spr_ball
	spr_fire
	spr_flame
	spr_flsh
	spr_tfog
	spr_ifog
	spr_play
	spr_poss
	spr_sarg
	spr_fatso
	spr_skull
	spr_head
	spr_brus
	spr_boss
	spr_bosc
	spr_bosp
	spr_bosf
	spr_smin
	spr_sarg2
	spr_cybr
	spr_spnd
	spr_spch
	spr_spn2
	spr_bspd
	spr_bsp2
	spr_fist
	spr_imps
	spr_impt
	spr_imp2
	spr_pain
	spr_skel
	spr_man2
	spr_man3
	spr_vile
	spr_fire2
	spr_fcan
	spr_boner
	spr_boni
	spr_bexlp
	spr_bexl2
	spr_puff
	spr_blood
	spr_telep
	spr_stm
	spr_sbsp
	spr_aclo
	spr_tnt1
	spr_pdub
	spr_pols
	spr_gun2
	spr_gun3
	spr_gun4
	spr_gun5
	spr_gun6
	spr_gun7
	spr_gun8
	spr_gun9
	spr_gun10
	spr_chop
	spr_sawg
	spr_sawl
	spr_sawf
	spr_glu2
	spr_glu3
	spr_glu4
	spr_glu5
	spr_glu6
	spr_glu7
	spr_glu8
	spr_glu9
	spr_ray1
	spr_ray2
}

pub enum StateNum {
	s_null = 0
	s_lightdone = 1
	s_punch = 2
	s_punchdown = 3
	s_punchup = 4
	s_recoil = 5
}

pub enum MobjType {
	mt_player = 0
	mt_possessed = 1
	mt_shotguy = 2
	mt_vile = 3
	mt_fireflicker = 4
	mt_fleshboss = 5
	mt_flesh = 6
	mt_undead = 7
	mt_tracer = 8
	mt_smoke = 9
	mt_fatso = 10
	mt_fatshot = 11
	mt_chainsaw = 12
	mt_troop = 13
	mt_serpent = 14
	mt_head = 15
	mt_bruiser = 16
	mt_bruisershot = 17
	mt_trailing = 18
	mt_brain = 19
	mt_brainspike = 20
	mt_brainlava = 21
	mt_braindead = 22
}

pub struct MobjInfo {
pub mut:
	doomednum int
	spawnstate StateNum
	spawnhealth int
	seestate StateNum
	seelimit int
	seespell int
	painstate StateNum
	painchance int
	painflag int
	meleestate StateNum
	missilestate StateNum
	deathstate StateNum
	xdeathstate StateNum
	speed Fixed
	radius Fixed
	height Fixed
	mass int
	damage int
	activesound int
	flags int
	flags2 int
	respawnstate StateNum
}

pub struct State {
pub mut:
	sprite   SpriteNum
	frame    int
	tics     int
	action   Actionf
	nextstate StateNum
	misc1    int
	misc2    int
}

pub const numstates = 1
pub const num_mobj_types = 1
pub const num_sprites = 1

pub const states = []State{len: numstates}
pub const mobjinfo = []MobjInfo{len: num_mobj_types}
