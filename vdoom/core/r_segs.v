module core

pub fn r_render_segs() {}

pub fn r_render_masked_seg_range(ds &DrawSeg, x1 int, x2 int) {
	_ = ds
	_ = x1
	_ = x2
}

pub fn r_check_sight() {
	_ = 0
}

pub fn r_clip_silhouette(bottom int, top int, x1 int, x2 int) {
	_ = bottom
	_ = top
	_ = x1
	_ = x2
}

pub fn r_add_silhouette(ld &Line, silside int, backsector voidptr) {
	_ = ld
	_ = silside
	_ = backsector
}

pub fn r_render_wall_segment(x1 int, x2 int, ds &DrawSeg) {
	_ = x1
	_ = x2
	_ = ds
}

pub fn r_project_line_x2(ld &Line, x1 int, x2 int, ds &DrawSeg) {
	_ = ld
	_ = x1
	_ = x2
	_ = ds
}

pub fn r_project_line(ld &Line, x1 int, x2 int, ds &DrawSeg) {
	_ = ld
	_ = x1
	_ = x2
	_ = ds
}

pub fn r_check_line(ld &Line) {
	_ = ld
}

pub fn r_store_wall_range(x1 int, x2 int) {
	_ = x1
	_ = x2
}
