module core

pub type ActionfV = fn ()
pub type ActionfP1 = fn (voidptr)
pub type ActionfP2 = fn (voidptr, voidptr)

pub struct Actionf {
pub mut:
	acv  ActionfV = unsafe { nil }
	acp1 ActionfP1 = unsafe { nil }
	acp2 ActionfP2 = unsafe { nil }
}

pub type ThinkT = Actionf

@[heap]
pub struct Thinker {
pub mut:
	prev     &Thinker = unsafe { nil }
	next     &Thinker = unsafe { nil }
	function ThinkT
	removed  bool
}
