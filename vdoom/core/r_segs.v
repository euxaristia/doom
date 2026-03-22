@[has_globals]
module core

import math

__global (
	rw_x = 0
	rw_stopx = 0
	rw_centerangle = u32(0)
	rw_offset = Fixed(0)
	rw_scale = Fixed(0)
	rw_scalestep = Fixed(0)
	rw_midtexturemid = Fixed(0)
	rw_toptexturemid = Fixed(0)
	rw_bottomtexturemid = Fixed(0)

	worldtop = Fixed(0)
	worldbottom = Fixed(0)
	worldhigh = Fixed(0)
	worldlow = Fixed(0)

	topfrac = i64(0)
	topstep = Fixed(0)
	bottomfrac = i64(0)
	bottomstep = Fixed(0)
	pixhigh = i64(0)
	pixhighstep = Fixed(0)
	pixlow = i64(0)
	pixlowstep = Fixed(0)

	markfloor = false
	markceiling = false
	maskedtexture = false
	segtextured = false

	midtexture = i16(0)
	toptexture = i16(0)
	bottomtexture = i16(0)

	sidedef = &Side(unsafe { nil })
	linedef = &Line(unsafe { nil })

	drawsegs = []DrawSeg{}
	ds_p = 0 
	numdrawsegs = 0
	maskedtexturecol = []Fixed{}
	walllights = []u8{}
)

const ml_dontpegtop = i16(8)
const ml_dontpegbottom = i16(16)

pub fn r_init_segs() {
	drawsegs = []DrawSeg{len: 256}
	maskedtexturecol = []Fixed{len: 321}
	walllights = []u8{len: 256}
}

pub fn r_render_segs() {}

pub fn r_render_masked_seg_range(ds &DrawSeg, x1 int, x2 int) {
	_ = ds
	_ = x1
	_ = x2
}

pub fn r_check_sight() {
}

pub fn r_clip_silhouette(bottom int, top int, x1 int, x2 int, ds &DrawSeg) {
	_ = bottom
	_ = top
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

pub fn r_render_seg_loop() {
	mut angle := u32(0)
	mut index := u32(0)
	mut yl := 0
	mut yh := 0
	mut mid := 0
	mut texturecolumn := Fixed(0)
	mut top := 0
	mut bottom := 0

	heightbits := 16
	heightunit := i64(1) << heightbits

	for rw_x < rw_stopx {
		if rw_x < 0 || rw_x >= ceilingclip.len || rw_x >= floorclip.len {
			rw_x++
			continue
		}

		yl = int((topfrac + heightunit - 1) >> heightbits)

		if yl < ceilingclip[rw_x] + 1 {
			yl = ceilingclip[rw_x] + 1
		}

		if markceiling {
			top = ceilingclip[rw_x] + 1
			bottom = yl - 1

			if bottom >= floorclip[rw_x] {
				bottom = floorclip[rw_x] - 1
			}

			if top <= bottom {
				if ceilingplane != unsafe { nil } && rw_x < ceilingplane.top.len && rw_x < ceilingplane.bottom.len {
					if ceilingplane.top[rw_x] == 0xff {
						ceilingplane.top[rw_x] = u8(top)
						ceilingplane.bottom[rw_x] = u8(bottom)
					}
				}
			}
		}

		yh = int(bottomfrac >> heightbits)

		if yh >= floorclip[rw_x] {
			yh = floorclip[rw_x] - 1
		}

		if markfloor {
			top = yh + 1
			bottom = floorclip[rw_x] - 1
			if top <= ceilingclip[rw_x] {
				top = ceilingclip[rw_x] + 1
			}
			if top <= bottom {
				if floorplane != unsafe { nil } && rw_x < floorplane.top.len && rw_x < floorplane.bottom.len {
					if floorplane.top[rw_x] == 0xff {
						floorplane.top[rw_x] = u8(top)
						floorplane.bottom[rw_x] = u8(bottom)
					}
				}
			}
		}

		if segtextured {
			if rw_x >= xtoviewangle.len {
				rw_x++
				continue
			}
			angle = (rw_centerangle + u32(xtoviewangle[rw_x])) >> u32(angle_to_fineshift)
			
			angle_rad := f64(angle) * math.pi * 2.0 / 8192.0
			finetan := f64(math.tan(angle_rad))
			
			texturecolumn = rw_offset - Fixed(i32(finetan * f64(rw_distance)))
			texturecolumn >>= frac_bits
			index = u32(rw_scale) >> u32(lightscaleshift)

			if index >= u32(maxlightscale) {
				index = u32(maxlightscale) - 1
			}

			dc_x = rw_x
			dc_iscale = Fixed(i32(u32(4294967295) / u32(rw_scale)))
		} else {
			texturecolumn = Fixed(0)
		}

		if midtexture >= 0 {
			if int(midtexture) < textureheight.len {
				dc_yl = yl
				dc_yh = yh
				dc_texturemid = rw_midtexturemid
				dc_source = r_get_column(int(midtexture), int(texturecolumn))
				dc_texheight = int(textureheight[midtexture] >> frac_bits)
				r_draw_column()
				ceilingclip[rw_x] = i16(viewheight)
				floorclip[rw_x] = -1
			}
		} else {
			if toptexture >= 0 {
				mid = int(pixhigh >> heightbits)
				pixhigh += i64(pixhighstep)

				if mid >= floorclip[rw_x] {
					mid = floorclip[rw_x] - 1
				}

				if mid >= yl {
					if int(toptexture) < textureheight.len {
						dc_yl = yl
						dc_yh = mid
						dc_texturemid = rw_toptexturemid
						dc_source = r_get_column(int(toptexture), int(texturecolumn))
						dc_texheight = int(textureheight[toptexture] >> frac_bits)
						r_draw_column()
						ceilingclip[rw_x] = i16(mid)
					}
				} else {
					ceilingclip[rw_x] = i16(yl - 1)
				}
			} else {
				if markceiling {
					ceilingclip[rw_x] = i16(yl - 1)
				}
			}

			if bottomtexture >= 0 {
				mid = int((pixlow + heightunit - 1) >> heightbits)
				pixlow += i64(pixlowstep)

				if mid <= ceilingclip[rw_x] {
					mid = ceilingclip[rw_x] + 1
				}

				if mid <= yh {
					if int(bottomtexture) < textureheight.len {
						dc_yl = mid
						dc_yh = yh
						dc_texturemid = rw_bottomtexturemid
						dc_source = r_get_column(int(bottomtexture), int(texturecolumn))
						dc_texheight = int(textureheight[bottomtexture] >> frac_bits)
						r_draw_column()
						floorclip[rw_x] = i16(mid)
					}
				} else {
					floorclip[rw_x] = i16(yh + 1)
				}
			} else {
				if markfloor {
					floorclip[rw_x] = i16(yh + 1)
				}
			}
		}

		rw_scale += rw_scalestep
		topfrac += i64(topstep)
		bottomfrac += i64(bottomstep)
		rw_x++
	}
}

pub fn r_store_wall_range(start int, stop int) {
	rw_x = start
	rw_stopx = stop + 1

	if drawsegs.len == 0 {
		r_init_segs()
	}

	if ds_p < 0 || ds_p >= drawsegs.len {
		return
	}

	if voidptr(curline) == unsafe { nil } { return }

	mut ds := DrawSeg{}

	unsafe {
		sidedef = curline.sidedef
		linedef = curline.linedef
	}

	if sidedef == unsafe { nil } || linedef == unsafe { nil } { return }

	if voidptr(curline.v1) == unsafe { nil } || voidptr(curline.v2) == unsafe { nil } { return }

	v1x := i64(curline.v1.x)
	v1y := i64(curline.v1.y)
	v2x := i64(curline.v2.x)
	v2y := i64(curline.v2.y)

	dx := v2x - v1x
	dy := v2y - v1y
	dx1 := i64(viewx) - v1x
	dy1 := i64(viewy) - v1y
	
	mut len_fix := p_approx_distance(Fixed(i32(dx)), Fixed(i32(dy)))
	if len_fix == 0 { len_fix = Fixed(1) }

	dist := (dy * dx1 - dx * dy1) / i64(len_fix)
	rw_distance = Fixed(i32(dist))

	ds.x1 = start
	rw_x = start
	ds.x2 = stop
	ds.curline = curline
	rw_stopx = stop + 1

	if start < 0 || start >= xtoviewangle.len { return }

	ds.scale1 = r_scale_from_global_angle(viewangle + u32(xtoviewangle[start]))
	rw_scale = ds.scale1

	if stop > start {
		if stop < 0 || stop >= xtoviewangle.len { return }
		ds.scale2 = r_scale_from_global_angle(viewangle + u32(xtoviewangle[stop]))
		ds.scalestep = (ds.scale2 - rw_scale) / Fixed(stop - start)
		rw_scalestep = ds.scalestep
	} else {
		ds.scale2 = ds.scale1
		ds.scalestep = Fixed(0)
		rw_scalestep = Fixed(0)
	}

	if frontsector == unsafe { nil } { return }

	worldtop = frontsector.ceilingheight - viewz
	worldbottom = frontsector.floorheight - viewz

	mut mid_v := i16(-1)
	mut top_v := i16(-1)
	mut bot_v := i16(-1)
	mut mask_v := false

	if backsector == unsafe { nil } {
		mid_v = i16(sidedef.midtexture)
		markfloor = true
		markceiling = true
		
		if (int(linedef.flags) & 16) != 0 {
			vtop := if mid_v >= 0 && int(mid_v) < textureheight.len { frontsector.floorheight + textureheight[mid_v] } else { frontsector.floorheight }
			rw_midtexturemid = vtop - viewz
		} else {
			rw_midtexturemid = worldtop
		}
		rw_midtexturemid += sidedef.rowoffset
		
		ds.silhouette = sil_both
		ds.bsilheight = int_max
		ds.tsilheight = int_min
	} else {
		ds.silhouette = 0

		if frontsector.floorheight > backsector.floorheight {
			ds.silhouette = sil_bottom
			ds.bsilheight = frontsector.floorheight
		} else if backsector.floorheight > viewz {
			ds.silhouette = sil_bottom
			ds.bsilheight = int_max
		}

		if frontsector.ceilingheight < backsector.ceilingheight {
			ds.silhouette |= sil_top
			ds.tsilheight = frontsector.ceilingheight
		} else if backsector.ceilingheight < viewz {
			ds.silhouette |= sil_top
			ds.tsilheight = int_min
		}

		w_high := backsector.ceilingheight - viewz
		w_low := backsector.floorheight - viewz

		if w_low != worldbottom || backsector.floorpic != frontsector.floorpic || backsector.lightlevel != frontsector.lightlevel {
			markfloor = true
		} else {
			markfloor = false
		}

		if w_high != worldtop || backsector.ceilingpic != frontsector.ceilingpic || backsector.lightlevel != frontsector.lightlevel {
			markceiling = true
		} else {
			markceiling = false
		}

		if backsector.ceilingheight <= frontsector.floorheight || backsector.floorheight >= frontsector.ceilingheight {
			markceiling = true
			markfloor = true
		}

		if w_high < worldtop {
			top_v = i16(sidedef.toptexture)
			if (int(linedef.flags) & 8) != 0 {
				rw_toptexturemid = worldtop
			} else {
				vtop := if top_v >= 0 && int(top_v) < textureheight.len { backsector.ceilingheight + textureheight[top_v] } else { backsector.ceilingheight }
				rw_toptexturemid = vtop - viewz
			}
		}

		if w_low > worldbottom {
			bot_v = i16(sidedef.bottomtexture)
			if (int(linedef.flags) & 16) != 0 {
				rw_bottomtexturemid = worldtop
			} else {
				rw_bottomtexturemid = w_low
			}
		}
		rw_toptexturemid += sidedef.rowoffset
		rw_bottomtexturemid += sidedef.rowoffset

		if sidedef.midtexture >= 0 {
			mask_v = true
		}
	}

	midtexture = mid_v
	toptexture = top_v
	bottomtexture = bot_v
	maskedtexture = mask_v

	segtextured = midtexture >= 0 || toptexture >= 0 || bottomtexture >= 0 || maskedtexture
	if segtextured {
		rw_offset = Fixed(i32((dx * dx1 + dy * dy1) / i64(len_fix)))
		rw_offset += sidedef.textureoffset + curline.offset
		rw_centerangle = ang90 + viewangle - u32(rw_normalangle)
	}

	if frontsector.floorheight >= viewz {
		markfloor = false
	}
	if frontsector.ceilingheight <= viewz {
		markceiling = false
	}

	if markceiling {
		ceilingplane = r_find_plane(frontsector.ceilingheight, int(frontsector.ceilingpic), int(frontsector.lightlevel))
		if ceilingplane != unsafe { nil } {
			ceilingplane = r_check_plane(ceilingplane, start, stop)
		}
	} else {
		ceilingplane = unsafe { nil }
	}

	if markfloor {
		floorplane = r_find_plane(frontsector.floorheight, int(frontsector.floorpic), int(frontsector.lightlevel))
		if floorplane != unsafe { nil } {
			floorplane = r_check_plane(floorplane, start, stop)
		}
	} else {
		floorplane = unsafe { nil }
	}

	topstep = -fixed_mul(rw_scalestep, worldtop)
	topfrac = i64(centeryfrac) - (i64(worldtop) * i64(rw_scale) >> 16)

	bottomstep = -fixed_mul(rw_scalestep, worldbottom)
	bottomfrac = i64(centeryfrac) - (i64(worldbottom) * i64(rw_scale) >> 16)

	if backsector != unsafe { nil } {
		worldhigh := backsector.ceilingheight - viewz
		worldlow := backsector.floorheight - viewz

		if worldhigh < worldtop {
			pixhigh = i64(centeryfrac) - (i64(worldhigh) * i64(rw_scale) >> 16)
			pixhighstep = -fixed_mul(rw_scalestep, worldhigh)
		}

		if worldlow > worldbottom {
			pixlow = i64(centeryfrac) - (i64(worldlow) * i64(rw_scale) >> 16)
			pixlowstep = -fixed_mul(rw_scalestep, worldlow)
		}
	}

	r_render_seg_loop()

	if ds_p >= 0 && ds_p < drawsegs.len {
		drawsegs[ds_p] = ds
		ds_p++
	}
}
