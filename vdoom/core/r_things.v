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

pub fn r_clear_sprites() {
	validcount++
	vissprite_p = &vissprites[0]
	vsprsortedhead.prev = unsafe { nil }
	vsprsortedhead.next = unsafe { nil }
	for i in 0 .. maxvissprites {
		vissprites[i].prev = unsafe { nil }
		vissprites[i].next = unsafe { nil }
	}
}

pub fn r_add_sprites(sec &Sector) {
	if voidptr(sec) == unsafe { nil } {
		return
	}
	for mobj := sec.thinglist; mobj != unsafe { nil }; mobj = mobj.snext {
		if voidptr(mobj) == unsafe { nil } {
			break
		}
		if mobj.validcount == validcount {
			continue
		}
		mobj.validcount = validcount

		if mobj.flags & mf_special != 0 {
			continue
		}

		if mobj.z > mobj.ceilingz {
			continue
		}

		r_project_sprite(mobj)
	}
}

fn r_project_sprite(mobj &Mobj) {
	if voidptr(vissprite_p) == unsafe { nil } {
		return
	}
	mut vs := vissprite_p

	mut gzt := mobj.z + mobj.height
	if mobj.flags & mf_float != 0 && mobj.target != unsafe { nil } {
		target := mobj.target
		if voidptr(target) != unsafe { nil } {
			gzt = target.z + (mobj.height >> 1)
		}
	}

	dz := mobj.x - viewx
	dy := mobj.y - viewy

	dx := fixed_mul(dz, viewcos) + fixed_mul(dy, viewsin)
	dy2 := fixed_mul(dy, viewcos) - fixed_mul(dz, viewsin)

	if dy2 <= 0 {
		return
	}

	scale := Fixed(int(i64(projection) / i64(dy)))

	gx := mobj.x - viewx
	gy := mobj.y - viewy
	gz := mobj.z - viewz
	mut gzt_view := gzt - viewz

	mut x1 := centerx - fixed_mul(scale, fixed_mul(gy, viewcos) - fixed_mul(gx, viewsin))
	mut x2 := centerx + fixed_mul(scale, fixed_mul(gy, viewcos) - fixed_mul(gx, viewsin))

	if x1 >= screenwidth || x2 < 0 {
		return
	}

	if x1 < 0 {
		x1 = 0
	}
	if x2 >= screenwidth {
		x2 = screenwidth - 1
	}

	mut y1 := centery - fixed_mul(scale, gzt_view)
	mut y2 := centery - fixed_mul(scale, gz)

	if y1 >= screenheight || y2 < 0 {
		return
	}

	if y1 < 0 {
		y1 = 0
	}
	if y2 >= screenheight {
		y2 = screenheight - 1
	}

	vs.x1 = int(x1)
	vs.x2 = int(x2)
	vs.gx = mobj.x
	vs.gy = mobj.y
	vs.gz = gz
	vs.gzt = gzt_view
	vs.startfrac = Fixed(0)
	vs.scale = scale
	vs.xiscale = Fixed(int(i64(frac_unit) / i64(scale)))
	vs.texturemid = Fixed(frac_unit >> 1) - (gz - (gzt_view - mobj.height))
	vs.patch = 0
	vs.colormap = unsafe { nil }
	vs.mobjflags = mobj.flags

	vissprite_p = unsafe { &vissprites[int(vissprite_p) + 1] }
}

pub fn r_sort_vis_sprites() {
	if vissprite_p == unsafe { nil } {
		return
	}

	for i := 0; i < maxvissprites; i++ {
		vissprites[i].next = unsafe { nil }
		vissprites[i].prev = unsafe { nil }
	}

	mut first := &VisSprite(unsafe { nil })
	mut count := 0

	for i in 0 .. maxvissprites {
		mut vs := &vissprites[i]
		if vs.scale == Fixed(0) {
			continue
		}
		count++

		if first == unsafe { nil } {
			first = vs
			continue
		}

		mut other := first
		mut inserted := false
		for other != unsafe { nil } {
			if vs.scale > other.scale {
				if other.prev != unsafe { nil } {
					other.prev.next = vs
					vs.prev = other.prev
				} else {
					first = vs
				}
				vs.next = other
				other.prev = vs
				inserted = true
				break
			}
			other = other.next
		}
		if !inserted {
			vs.prev = other
			if other != unsafe { nil } {
				other.next = vs
			}
		}
	}

	if first != unsafe { nil } {
		vsprsortedhead.next = first
		first.prev = &vsprsortedhead
	}
}

pub fn r_draw_sprites() {
	for vs := vsprsortedhead.next; vs != unsafe { nil }; vs = vs.next {
		r_draw_vis_sprite(vs)
	}
}

fn r_draw_vis_sprite(vs &VisSprite) {
	mut x1 := vs.x1
	mut x2 := vs.x2

	if x1 >= screenwidth || x2 < 0 {
		return
	}
	if x1 < 0 {
		x1 = 0
	}
	if x2 >= screenwidth {
		x2 = screenwidth - 1
	}

	mut scale := vs.scale
	mut iscale := vs.xiscale
	mut texturemid := vs.texturemid

	half_h := screenheight / 2
	mut top := int(centery - scale * vs.gzt)
	mut bot := int(centery - scale * vs.gz)

	if top < 0 {
		top = 0
	}
	if bot >= screenheight {
		bot = screenheight - 1
	}

	if top > bot {
		return
	}

	mut lump_num := 0

	mut basecol := u8(150)
	if vs.mobjflags & mf_special != 0 {
		basecol = u8(230)
	} else if vs.mobjflags & mf_shootable != 0 {
		basecol = u8(175)
	}

	for dc_x := x1; dc_x <= x2; dc_x++ {
		dc_yl := top
		dc_yh := bot
		dc_iscale = iscale
		dc_texturemid = texturemid
		dc_x = dc_x

		frac := texturemid + Fixed(dc_x - centerx) * iscale

		mut color := basecol
		if vs.mobjflags & mf_special != 0 {
			color = 231
		} else if vs.mobjflags & mf_shootable != 0 {
			color = 175
		} else {
			color = 176
		}

		dc_color = color
		dc_source = []u8{}
		dc_texheight = 0

		r_draw_column()
	}
}

pub fn r_add_psprites() {
}

pub fn r_init_sprites(namelist []string) {
	_ = namelist
}

pub fn r_draw_masked() {
	r_draw_sprites()
}

pub fn r_clip_vis_sprite(vis &VisSprite, xl int, xh int) {
	_ = vis
	_ = xl
	_ = xh
}
