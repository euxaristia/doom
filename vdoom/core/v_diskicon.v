module core

pub const loading_disk_w = 16
pub const loading_disk_h = 16

pub fn v_enable_loading_disk(lump_name string, xoffs int, yoffs int) {
	_ = lump_name
	_ = xoffs
	_ = yoffs
}

pub fn v_begin_read(nbytes usize) {
	_ = nbytes
}

pub fn v_draw_disk_icon() {
}

pub fn v_restore_disk_background() {
}
