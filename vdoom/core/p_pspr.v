module core

pub const ff_fullbright = 0x8000
pub const ff_framemask = 0x7fff

@[_allow_multiple_values]
pub enum PsprNum {
	weapon
	flash
	numpsprites
}

pub const numpsprites = 2

pub struct PspDef {
pub mut:
	state voidptr
	tics  int
	sx    Fixed
	sy    Fixed
}
