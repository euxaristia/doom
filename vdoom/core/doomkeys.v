module core

pub const key_rightarrow = 0xae
pub const key_leftarrow = 0xac
pub const key_uparrow = 0xad
pub const key_downarrow = 0xaf
pub const key_escape = 27
pub const key_enter = 13
pub const key_tab = 9
pub const key_f1 = 0x80 + 0x3b
pub const key_f2 = 0x80 + 0x3c
pub const key_f3 = 0x80 + 0x3d
pub const key_f4 = 0x80 + 0x3e
pub const key_f5 = 0x80 + 0x3f
pub const key_f6 = 0x80 + 0x40
pub const key_f7 = 0x80 + 0x41
pub const key_f8 = 0x80 + 0x42
pub const key_f9 = 0x80 + 0x43
pub const key_f10 = 0x80 + 0x44
pub const key_f11 = 0x80 + 0x57
pub const key_f12 = 0x80 + 0x58
pub const key_backspace = 0x7f
pub const key_pause = 0xff
pub const key_equals = 0x3d
pub const key_minus = 0x2d
pub const key_rshift = 0x80 + 0x36
pub const key_rctrl = 0x80 + 0x1d
pub const key_ralt = 0x80 + 0x38
pub const key_lalt = key_ralt
pub const key_capslock = 0x80 + 0x3a
pub const key_numlock = 0x80 + 0x45
pub const key_scrlck = 0x80 + 0x46
pub const key_prtscr = 0x80 + 0x59
pub const key_home = 0x80 + 0x47
pub const key_end = 0x80 + 0x4f
pub const key_pgup = 0x80 + 0x49
pub const key_pgdn = 0x80 + 0x51
pub const key_ins = 0x80 + 0x52
pub const key_del = 0x80 + 0x53
pub const keyp_0 = key_ins
pub const keyp_1 = key_end
pub const keyp_2 = key_downarrow
pub const keyp_3 = key_pgdn
pub const keyp_4 = key_leftarrow
pub const keyp_5 = 0x80 + 0x4c
pub const keyp_6 = key_rightarrow
pub const keyp_7 = key_home
pub const keyp_8 = key_uparrow
pub const keyp_9 = key_pgup
pub const keyp_divide = int(`/`)
pub const keyp_plus = int(`+`)
pub const keyp_minus = int(`-`)
pub const keyp_multiply = int(`*`)
pub const keyp_period = 0
pub const keyp_equals = key_equals
pub const keyp_enter = key_enter

pub const scancode_to_keys = [
	0, 0, 0, 0, int(`a`),
	int(`b`), int(`c`), int(`d`), int(`e`), int(`f`),
	int(`g`), int(`h`), int(`i`), int(`j`), int(`k`),
	int(`l`), int(`m`), int(`n`), int(`o`), int(`p`),
	int(`q`), int(`r`), int(`s`), int(`t`), int(`u`),
	int(`v`), int(`w`), int(`x`), int(`y`), int(`z`),
	int(`1`), int(`2`), int(`3`), int(`4`), int(`5`),
	int(`6`), int(`7`), int(`8`), int(`9`), int(`0`),
	key_enter, key_escape, key_backspace, key_tab, int(` `),
	key_minus, key_equals, int(`[`), int(`]`), int(`\\`),
	0, int(`;`), int(`'`), 96, int(`,`),
	int(`.`), int(`/`), key_capslock, key_f1, key_f2,
	key_f3, key_f4, key_f5, key_f6, key_f7,
	key_f8, key_f9, key_f10, key_f11, key_f12,
	key_prtscr, key_scrlck, key_pause, key_ins, key_home,
	key_pgup, key_del, key_end, key_pgdn, key_rightarrow,
	key_leftarrow, key_downarrow, key_uparrow,
	key_numlock, keyp_divide,
	keyp_multiply, keyp_minus, keyp_plus, keyp_enter, keyp_1,
	keyp_2, keyp_3, keyp_4, keyp_5, keyp_6,
	keyp_7, keyp_8, keyp_9, keyp_0, keyp_period,
	0, 0, 0, keyp_equals,
]

pub struct KeyName {
pub:
	key  int
	name string
}

pub const key_names = [
	KeyName{key: key_backspace, name: 'BACKSP'},
	KeyName{key: key_tab, name: 'TAB'},
	KeyName{key: key_ins, name: 'INS'},
	KeyName{key: key_del, name: 'DEL'},
	KeyName{key: key_pgup, name: 'PGUP'},
	KeyName{key: key_pgdn, name: 'PGDN'},
	KeyName{key: key_enter, name: 'ENTER'},
	KeyName{key: key_escape, name: 'ESC'},
	KeyName{key: key_f1, name: 'F1'},
	KeyName{key: key_f2, name: 'F2'},
	KeyName{key: key_f3, name: 'F3'},
	KeyName{key: key_f4, name: 'F4'},
	KeyName{key: key_f5, name: 'F5'},
	KeyName{key: key_f6, name: 'F6'},
	KeyName{key: key_f7, name: 'F7'},
	KeyName{key: key_f8, name: 'F8'},
	KeyName{key: key_f9, name: 'F9'},
	KeyName{key: key_f10, name: 'F10'},
	KeyName{key: key_f11, name: 'F11'},
	KeyName{key: key_f12, name: 'F12'},
	KeyName{key: key_home, name: 'HOME'},
	KeyName{key: key_end, name: 'END'},
	KeyName{key: key_minus, name: '-'},
	KeyName{key: key_equals, name: '='},
	KeyName{key: key_numlock, name: 'NUMLCK'},
	KeyName{key: key_scrlck, name: 'SCRLCK'},
	KeyName{key: key_pause, name: 'PAUSE'},
	KeyName{key: key_prtscr, name: 'PRTSC'},
	KeyName{key: key_uparrow, name: 'UP'},
	KeyName{key: key_downarrow, name: 'DOWN'},
	KeyName{key: key_leftarrow, name: 'LEFT'},
	KeyName{key: key_rightarrow, name: 'RIGHT'},
	KeyName{key: key_ralt, name: 'ALT'},
	KeyName{key: key_lalt, name: 'ALT'},
	KeyName{key: key_rshift, name: 'SHIFT'},
	KeyName{key: key_capslock, name: 'CAPS'},
	KeyName{key: key_rctrl, name: 'CTRL'},
	KeyName{key: keyp_5, name: 'NUM5'},
	KeyName{key: int(` `), name: 'SPACE'},
	KeyName{key: int(`a`), name: 'A'},
	KeyName{key: int(`b`), name: 'B'},
	KeyName{key: int(`c`), name: 'C'},
	KeyName{key: int(`d`), name: 'D'},
	KeyName{key: int(`e`), name: 'E'},
	KeyName{key: int(`f`), name: 'F'},
	KeyName{key: int(`g`), name: 'G'},
	KeyName{key: int(`h`), name: 'H'},
	KeyName{key: int(`i`), name: 'I'},
	KeyName{key: int(`j`), name: 'J'},
	KeyName{key: int(`k`), name: 'K'},
	KeyName{key: int(`l`), name: 'L'},
	KeyName{key: int(`m`), name: 'M'},
	KeyName{key: int(`n`), name: 'N'},
	KeyName{key: int(`o`), name: 'O'},
	KeyName{key: int(`p`), name: 'P'},
	KeyName{key: int(`q`), name: 'Q'},
	KeyName{key: int(`r`), name: 'R'},
	KeyName{key: int(`s`), name: 'S'},
	KeyName{key: int(`t`), name: 'T'},
	KeyName{key: int(`u`), name: 'U'},
	KeyName{key: int(`v`), name: 'V'},
	KeyName{key: int(`w`), name: 'W'},
	KeyName{key: int(`x`), name: 'X'},
	KeyName{key: int(`y`), name: 'Y'},
	KeyName{key: int(`z`), name: 'Z'},
	KeyName{key: int(`0`), name: '0'},
	KeyName{key: int(`1`), name: '1'},
	KeyName{key: int(`2`), name: '2'},
	KeyName{key: int(`3`), name: '3'},
	KeyName{key: int(`4`), name: '4'},
	KeyName{key: int(`5`), name: '5'},
	KeyName{key: int(`6`), name: '6'},
	KeyName{key: int(`7`), name: '7'},
	KeyName{key: int(`8`), name: '8'},
	KeyName{key: int(`9`), name: '9'},
	KeyName{key: int(`[`), name: '['},
	KeyName{key: int(`]`), name: ']'},
	KeyName{key: int(`;`), name: ';'},
	KeyName{key: 96, name: '`'},
	KeyName{key: int(`,`), name: ','},
	KeyName{key: int(`.`), name: '.'},
	KeyName{key: int(`/`), name: '/'},
	KeyName{key: int(`\\`), name: '\\'},
	KeyName{key: int(`'`), name: '\''},
]
