module core

pub const hu_charerase = key_backspace
pub const hu_maxlines = 4
pub const hu_maxlinelength = 80

pub struct HuTextLine {
pub mut:
	x           int
	y           int
	f           []&Patch
	sc          int
	l           string
	len         int
	needsupdate int
}

pub struct HuSText {
pub mut:
	l      []HuTextLine = []HuTextLine{len: hu_maxlines}
	h      int
	cl     int
	on     &bool = unsafe { nil }
	laston bool
}

pub struct HuIText {
pub mut:
	l      HuTextLine
	lm     int
	on     &bool = unsafe { nil }
	laston bool
}

pub fn hulib_init() {}

// Textline routines
pub fn hulib_clear_text_line(mut t HuTextLine) {
	t.l = ''
	t.len = 0
	t.needsupdate = 1
}

pub fn hulib_init_text_line(mut t HuTextLine, x int, y int, f []&Patch, sc int) {
	t.x = x
	t.y = y
	t.f = f
	t.sc = sc
	hulib_clear_text_line(mut t)
}

pub fn hulib_add_char_to_text_line(mut t HuTextLine, ch u8) bool {
	if t.l.len >= hu_maxlinelength {
		return false
	}
	t.l += [ch].bytestr()
	t.len = t.l.len
	t.needsupdate = 4
	return true
}

pub fn hulib_del_char_from_text_line(mut t HuTextLine) bool {
	if t.l.len == 0 {
		return false
	}
	t.l = t.l[..t.l.len - 1]
	t.len = t.l.len
	t.needsupdate = 4
	return true
}

pub fn hulib_draw_text_line(l &HuTextLine, drawcursor bool) {
	_ = l
	_ = drawcursor
}

pub fn hulib_erase_text_line(l &HuTextLine) {
	_ = l
}

// Scrolling text routines
pub fn hulib_init_stext(mut s HuSText, x int, y int, h int, font []&Patch, startchar int, on &bool) {
	s.h = h
	s.cl = 0
	unsafe { s.on = on }
	s.laston = if on != unsafe { nil } { *on } else { false }
	for i in 0 .. s.l.len {
		hulib_init_text_line(mut s.l[i], x, y + i * 8, font, startchar)
	}
}

pub fn hulib_add_line_to_stext(mut s HuSText) {
	s.cl = (s.cl + 1) % hu_maxlines
	hulib_clear_text_line(mut s.l[s.cl])
}

pub fn hulib_add_message_to_stext(mut s HuSText, prefix string, msg string) {
	hulib_add_line_to_stext(mut s)
	_ = hulib_add_char_to_text_line(mut s.l[s.cl], ` `)
	for ch in (prefix + msg).bytes() {
		_ = hulib_add_char_to_text_line(mut s.l[s.cl], ch)
	}
}

pub fn hulib_draw_stext(s &HuSText) {
	_ = s
}

pub fn hulib_erase_stext(s &HuSText) {
	_ = s
}

// Input text routines
pub fn hulib_init_itext(mut it HuIText, x int, y int, font []&Patch, startchar int, on &bool) {
	unsafe { it.on = on }
	it.laston = if on != unsafe { nil } { *on } else { false }
	hulib_init_text_line(mut it.l, x, y, font, startchar)
	it.lm = 0
}

pub fn hulib_del_char_from_itext(mut it HuIText) {
	if it.l.len > it.lm {
		_ = hulib_del_char_from_text_line(mut it.l)
	}
}

pub fn hulib_erase_line_from_itext(mut it HuIText) {
	it.l.l = it.l.l[..it.lm]
	it.l.len = it.l.l.len
	it.l.needsupdate = 4
}

pub fn hulib_reset_itext(mut it HuIText) {
	hulib_clear_text_line(mut it.l)
	it.lm = 0
}

pub fn hulib_add_prefix_to_itext(mut it HuIText, str string) {
	it.l.l = str + it.l.l
	it.l.len = it.l.l.len
	it.lm = str.len
	it.l.needsupdate = 4
}

pub fn hulib_key_in_itext(mut it HuIText, ch u8) bool {
	if ch == u8(hu_charerase) {
		hulib_del_char_from_itext(mut it)
		return true
	}
	return hulib_add_char_to_text_line(mut it.l, ch)
}

pub fn hulib_draw_itext(it &HuIText) {
	_ = it
}

pub fn hulib_erase_itext(it &HuIText) {
	_ = it
}
