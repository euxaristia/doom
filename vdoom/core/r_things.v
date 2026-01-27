@[has_globals]
module core

pub const maxvissprites = 128

__global vissprites = []VisSprite{len: maxvissprites}
__global vissprite_p = &VisSprite(unsafe { nil })
__global vsprsortedhead = VisSprite{}

__global negonearray = []i16{len: screenwidth, init: -1}
__global screenheightarray = []i16{len: screenwidth, init: i16(screenheight)}

__global mfloorclip = []i16{}
__global mceilingclip = []i16{}
__global spryscale = Fixed(0)
__global sprtopscreen = Fixed(0)
__global pspritescale = Fixed(0)
__global pspriteiscale = Fixed(0)

pub fn r_draw_masked_column(column voidptr) {
	_ = column
}

pub fn r_sort_vis_sprites() {}
pub fn r_add_sprites(sec &Sector) { _ = sec }
pub fn r_add_psprites() {}
pub fn r_draw_sprites() {}
pub fn r_init_sprites(namelist []string) { _ = namelist }
pub fn r_clear_sprites() {}
pub fn r_draw_masked() {}

pub fn r_clip_vis_sprite(vis &VisSprite, xl int, xh int) {
	_ = vis
	_ = xl
	_ = xh
}
