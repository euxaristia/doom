module core

// Minimal placeholders for sprite/state/mobj types.
pub enum SpriteNum {
	none
}

pub enum StateNum {
	none
}

pub enum MobjType {
	none
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

pub const states = []State{len: numstates}
