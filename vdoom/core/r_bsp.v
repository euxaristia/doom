@[has_globals]
module core

__global curline = &Seg(unsafe { nil })
__global sidedef = &Side(unsafe { nil })
__global linedef = &Line(unsafe { nil })
__global frontsector = &Sector(unsafe { nil })
__global backsector = &Sector(unsafe { nil })

__global rw_x = 0
__global rw_stopx = 0
__global segtextured = false
__global markfloor = false
__global markceiling = false
__global skymap = false

__global drawsegs = []DrawSeg{len: maxdrawsegs}
__global ds_p = &DrawSeg(unsafe { nil })

__global hscalelight = []voidptr{}
__global vscalelight = []voidptr{}
__global dscalelight = []voidptr{}

pub type DrawFunc = fn (start int, stop int)

pub fn r_clear_clip_segs() {}
pub fn r_clear_draw_segs() {}
pub fn r_render_bsp_node(bspnum int) { _ = bspnum }
