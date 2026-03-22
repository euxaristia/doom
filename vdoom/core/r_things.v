@[has_globals]
module core

pub const maxvissprites = 128

__global (
	vissprites = []VisSprite{len: maxvissprites}
	vissprite_count = 0
	vsprsortedhead = VisSprite{}
)

__global (
	negonearray = []i16{len: screenwidth, init: -1}
	screenheightarray = []i16{len: screenwidth, init: i16(screenheight)}

	mfloorclip = []i16{}
	mceilingclip = []i16{}
	spryscale = Fixed(0)
	sprtopscreen = Fixed(0)
	pspritescale = Fixed(0)
	pspriteiscale = Fixed(0)
)

pub fn r_draw_masked_column(column voidptr) {
	_ = column
}

pub fn r_clear_sprites() {
	validcount++
	vissprite_count = 0
	vsprsortedhead.prev = unsafe { nil }
	vsprsortedhead.next = unsafe { nil }
	for i in 0 .. maxvissprites {
		vissprites[i].prev = unsafe { nil }
		vissprites[i].next = unsafe { nil }
		vissprites[i].scale = Fixed(0)
	}
}

pub fn r_add_sprites(sec &Sector) {
	if voidptr(sec) == unsafe { nil } {
		return
	}
	mut mobj := sec.thinglist
	for mobj != unsafe { nil } {
		if mobj.validcount == validcount {
			mobj = mobj.snext
			continue
		}
		mobj.validcount = validcount

		// skip logic simplified for now
		r_project_sprite(mobj)
		mobj = mobj.snext
	}
}

fn r_project_sprite(mobj &Mobj) {
	if vissprite_count >= maxvissprites {
		return
	}
	mut vs := &vissprites[vissprite_count]

	mut gzt := mobj.z + mobj.height
	
	dz := mobj.x - viewx
	dy := mobj.y - viewy

	dx := fixed_mul(dz, viewcos) + fixed_mul(dy, viewsin)
	dy2 := fixed_mul(dy, viewcos) - fixed_mul(dz, viewsin)

	if dx <= Fixed(frac_unit / 4) { // Near plane
		return
	}

	scale := Fixed(i32(i64(projection) * i64(frac_unit) / i64(dx)))

	gz := mobj.z - viewz
	gzt_view := gzt - viewz

	mut x1 := v_centerx + int(i64(dy2) * i64(v_centerx) / i64(dx))
	mut x2 := x1

	if x1 >= screenwidth || x2 < 0 {
		return
	}

	vs.x1 = int(x1)
	vs.x2 = int(x2)
	vs.gx = mobj.x
	vs.gy = mobj.y
	vs.gz = gz
	vs.gzt = gzt_view
	vs.startfrac = Fixed(0)
	vs.scale = scale
	vs.xiscale = Fixed(int(i64(frac_unit) * i64(frac_unit) / i64(scale)))
	
	vs.patch = 0
	vs.colormap = unsafe { nil }
	vs.mobjflags = mobj.flags

	vissprite_count++
}

pub fn r_sort_vis_sprites() {
	// Simplified sorting logic
	// For now, we'll just link them linearly
	if vissprite_count == 0 {
		return
	}
	
	mut last := &vsprsortedhead
	for i in 0 .. vissprite_count {
		mut vs := &vissprites[i]
		if vs.scale == 0 { continue }
		
		last.next = vs
		vs.prev = last
		vs.next = unsafe { nil }
		last = vs
	}
}

pub fn r_draw_sprites() {
	r_sort_vis_sprites()
	mut vs := vsprsortedhead.next
	for vs != unsafe { nil } {
		r_draw_vis_sprite(vs)
		vs = vs.next
	}
}

fn r_draw_vis_sprite(vs &VisSprite) {
	mut x1 := vs.x1
	mut x2 := vs.x2

	if x1 >= screenwidth || x2 < 0 {
		return
	}
	
	mut scale := vs.scale
	
	mut top := int(v_centery - int(i64(scale) * i64(vs.gzt) >> frac_bits))
	mut bot := int(v_centery - int(i64(scale) * i64(vs.gz) >> frac_bits))

	if top < 0 { top = 0 }
	if bot >= screenheight { bot = screenheight - 1 }
	if top > bot { return }

	for x := x1; x <= x2; x++ {
		if x < 0 || x >= screenwidth { continue }
		
		dc_x = x
		dc_yl = top
		dc_yh = bot
		dc_iscale = vs.xiscale
		dc_texturemid = 0
		dc_color = u8(170) // Recognition color
		dc_source = []u8{}
		dc_texheight = 0

		r_draw_column()
	}
}

pub fn r_add_psprites() {}
pub fn r_init_sprites(namelist []string) { _ = namelist }
pub fn r_draw_masked() { r_draw_sprites() }
pub fn r_clip_vis_sprite(vis &VisSprite, xl int, xh int) { _ = vis; _ = xl; _ = xh }
