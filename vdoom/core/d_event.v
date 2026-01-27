module core

pub enum EvType {
	keydown
	keyup
	mouse
	joystick
	quit
}

pub struct Event {
pub mut:
	typ   EvType
	data1 int
	data2 int
	data3 int
	data4 int
	data5 int
}

@[_allow_multiple_values]
pub enum ButtonCode {
	bt_attack = 1
	bt_use = 2
	bt_special = 128
	bt_specialmask = 3
	bt_change = 4
	bt_weaponmask = 8 + 16 + 32
	bt_weaponshift = 3
	bts_pause = 1
	bts_savegame = 2
	bts_savemask = 4 + 8 + 16
	bts_saveshift = 2
}

@[_allow_multiple_values]
pub enum ButtonCode2 {
	bt2_lookup = 1
	bt2_lookdown = 2
	bt2_centerview = 4
	bt2_invuse = 8
	bt2_invdrop = 16
	bt2_jump = 32
	bt2_health = 128
}

pub fn d_post_event(ev &Event) {
	_ = ev
}

pub fn d_pop_event() ?Event {
	return none
}
