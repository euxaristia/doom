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

__global drawsegs &DrawSeg
__global ds_p &DrawSeg

__global hscalelight = []voidptr{}
__global vscalelight = []voidptr{}
__global dscalelight = []voidptr{}

// Debug counter for rendered segs
__global seg_render_count = 0

pub type DrawFunc = fn (start int, stop int)

pub fn r_clear_clip_segs() {}

pub fn r_clear_draw_segs() {
	validcount++
	ds_p = drawsegs
	seg_render_count = 0
}

pub fn r_init_bsp() {
	drawsegs = &DrawSeg(unsafe { nil })
	ds_p = &DrawSeg(unsafe { nil })
}

// NF_SUBSECTOR flag — bit 15 of a child index marks it as a subsector leaf.
const nf_subsector = u16(0x8000)

pub fn r_render_bsp_node(bspnum int) {
	if bspnum & int(nf_subsector) != 0 {
		ssec_idx := if bspnum == -1 { 0 } else { bspnum & int(~nf_subsector) }
		r_render_subsector(ssec_idx)
		return
	}

	if bspnum < 0 || bspnum >= numnodes {
		return
	}

	node := &nodes[bspnum]
	side := r_point_on_side(viewx, viewy, node)

	r_render_bsp_node(int(node.children[side]))

	if r_check_bbox(node.bbox[side ^ 1]) {
		r_render_bsp_node(int(node.children[side ^ 1]))
	}
}

fn r_check_bbox(bbox [4]Fixed) bool {
	_ = bbox
	return true
}

fn r_render_subsector(ssec_idx int) {
	if ssec_idx < 0 || ssec_idx >= numsubsectors {
		return
	}

	ssec := &subsectors[ssec_idx]
	first := int(ssec.firstline)
	count := int(ssec.numlines)

	if count == 0 {
		return
	}

	for i in 0 .. count {
		seg_idx := first + i
		if seg_idx >= numsegs {
			break
		}
		seg := &segs[seg_idx]
		r_render_seg(seg)
	}
}

// Debug counters
__global seg_total_calls = 0
__global seg_null_reject = 0
__global seg_behind_reject = 0
__global seg_offscreen_reject = 0

// shade_color applies distance-based darkening using the COLORMAP.
fn shade_color(base_idx u8, light int, depth Fixed) u8 {
	if colormap_data.len < 256 {
		return base_idx
	}
	maps := colormap_data.len / 256
	if maps <= 0 {
		return base_idx
	}
	// Compute light level from sector light and depth
	// depth is in fixed-point; convert to map units
	dist := int(depth) >> frac_bits
	// Doom-style light diminishing: further = darker
	mut level := (255 - light) / 8
	level += dist / 48
	if level < 0 {
		level = 0
	} else if level >= maps {
		level = maps - 1
	}
	off := level * 256
	idx := int(base_idx)
	if idx < 0 || idx >= 256 || off + idx >= colormap_data.len {
		return base_idx
	}
	return colormap_data[off + idx]
}

// r_render_seg projects a wall segment to screen space and draws it.
fn r_render_seg(seg &Seg) {
	seg_total_calls++

	if seg.v1 == unsafe { nil } || seg.v2 == unsafe { nil } {
		seg_null_reject++
		return
	}
	if seg.frontsector == unsafe { nil } {
		seg_null_reject++
		return
	}

	front := seg.frontsector

	// Transform vertices to view-relative coordinates
	wx1 := seg.v1.x - viewx
	wy1 := seg.v1.y - viewy
	wx2 := seg.v2.x - viewx
	wy2 := seg.v2.y - viewy

	sin := viewsin
	cos := viewcos

	// Rotate world-relative coords to view space.
	// Doom angle 0 faces east (+x). View-space: depth is forward, horiz is right.
	// depth  = wx * cos + wy * sin   (projection onto forward vector)
	// horiz  = wx * sin - wy * cos   (projection onto right vector)
	d1 := fixed_mul(wx1, cos) + fixed_mul(wy1, sin)
	h1 := fixed_mul(wx1, sin) - fixed_mul(wy1, cos)
	d2 := fixed_mul(wx2, cos) + fixed_mul(wy2, sin)
	h2 := fixed_mul(wx2, sin) - fixed_mul(wy2, cos)

	// Reject if both endpoints are behind the viewer
	near := Fixed(frac_unit / 4)
	if d1 < near && d2 < near {
		seg_behind_reject++
		return
	}

	// Clip to near plane
	mut cd1 := d1
	mut ch1 := h1
	mut cd2 := d2
	mut ch2 := h2

	if cd1 < near {
		dd := cd2 - cd1
		if dd == 0 {
			return
		}
		frac := fixed_div(near - cd1, dd)
		ch1 = ch1 + fixed_mul(frac, ch2 - ch1)
		cd1 = near
	}
	if cd2 < near {
		dd := cd1 - cd2
		if dd == 0 {
			return
		}
		frac := fixed_div(near - cd2, dd)
		ch2 = ch2 + fixed_mul(frac, ch1 - ch2)
		cd2 = near
	}

	// Project to screen x coordinates
	// screen_x = center + h * center / depth (using i64 to avoid overflow)
	half_w := screenwidth / 2
	sx1 := half_w + int(i64(ch1) * i64(half_w) / i64(cd1))
	sx2 := half_w + int(i64(ch2) * i64(half_w) / i64(cd2))

	// Ensure left-to-right ordering
	mut lx := sx1
	mut rx := sx2
	mut ld := cd1
	mut rd := cd2
	if lx > rx {
		lx, rx = rx, lx
		ld, rd = rd, ld
	}

	// Clip to screen
	if rx <= 0 || lx >= screenwidth {
		return
	}
	if lx < 0 {
		lx = 0
	}
	if rx >= screenwidth {
		rx = screenwidth - 1
	}
	if lx >= rx {
		return
	}

	seg_render_count++

	// Sector heights
	floor_h := front.floorheight
	ceil_h := front.ceilingheight

	has_back := seg.backsector != unsafe { nil }
	mut back := unsafe { &Sector(nil) }
	if has_back {
		back = seg.backsector
	}

	base_light := int(front.lightlevel)

	// Get wall textures from the sidedef
	mut mid_tex := i16(0)
	mut upper_tex := i16(0)
	mut lower_tex := i16(0)
	mut tex_xoffset := Fixed(0)
	mut tex_yoffset := Fixed(0)
	if seg.sidedef != unsafe { nil } {
		mid_tex = seg.sidedef.midtexture
		upper_tex = seg.sidedef.toptexture
		lower_tex = seg.sidedef.bottomtexture
		tex_xoffset = seg.sidedef.textureoffset
		tex_yoffset = seg.sidedef.rowoffset
	}

	// Load floor and ceiling flat textures
	floor_flat := get_flat_by_num(int(front.floorpic))
	ceil_flat := if front.ceilingpic != skyflatnum {
		get_flat_by_num(int(front.ceilingpic))
	} else {
		[]u8{}
	}

	// Compute segment length for texture U coordinate
	seg_dx := seg.v2.x - seg.v1.x
	seg_dy := seg.v2.y - seg.v1.y
	seg_len := p_approx_distance(seg_dx, seg_dy)

	// Get wall textures once per segment
	mut mid_wt := WallTexture{}
	mut upper_wt := WallTexture{}
	mut lower_wt := WallTexture{}
	if mid_tex >= 0 { mid_wt = get_wall_texture(int(mid_tex)) }
	if upper_tex >= 0 { upper_wt = get_wall_texture(int(upper_tex)) }
	if lower_tex >= 0 { lower_wt = get_wall_texture(int(lower_tex)) }

	// Draw columns
	span := rx - lx
	if span <= 0 {
		return
	}

	half_h := screenheight / 2
	for x in lx .. rx {
		// Interpolate depth
		frac := if span > 1 { Fixed((x - lx) * frac_unit / span) } else { Fixed(0) }
		depth := ld + fixed_mul(frac, rd - ld)
		if depth <= 0 {
			continue
		}

		// Project heights to screen y
		ceil_sy := half_h - int(i64(ceil_h - viewz) * i64(half_w) / i64(depth))
		floor_sy := half_h - int(i64(floor_h - viewz) * i64(half_w) / i64(depth))

		// Clamp to clipping arrays
		clip_top := int(ceilingclip[x]) + 1
		clip_bot := int(floorclip[x]) - 1

		mut top := ceil_sy
		mut bot := floor_sy
		if top < clip_top {
			top = clip_top
		}
		if bot > clip_bot {
			bot = clip_bot
		}
		if top > bot {
			continue
		}

		// Texture U coordinate: interpolate along the segment
		tex_u := fixed_mul(frac, seg_len) + seg.offset + tex_xoffset

		// Inverse scale: how much of texture per screen pixel vertically
		wall_height_pixels := bot - top
		wall_height_world := ceil_h - floor_h
		iscale := if wall_height_pixels > 0 {
			Fixed(int(i64(wall_height_world) / i64(wall_height_pixels)))
		} else {
			Fixed(frac_unit)
		}

		if !has_back {
			// CEILING flat
			if top > clip_top && ceil_flat.len >= flat_bytes {
				draw_flat_columns(x, clip_top, top - 1, front, ceil_flat, depth, base_light)
			} else if top > clip_top {
				dc_x = x
				dc_color = shade_color(u8(199), base_light, depth)
				dc_source = []u8{}
				dc_texheight = 0
				dc_yl = clip_top
				dc_yh = top - 1
				r_draw_column()
			}

			// WALL texture
			if mid_wt.width > 0 {
				u := int(tex_u >> frac_bits)
				c := ((u % mid_wt.width) + mid_wt.width) % mid_wt.width
				col := mid_wt.columns[c]
				if col.len > 0 {
					dc_x = x
					unsafe { dc_source = col }
					dc_texheight = col.len
					dc_texturemid = tex_yoffset
					dc_iscale = iscale
					dc_yl = top
					dc_yh = bot
					r_draw_column()
				} else {
					dc_x = x
					dc_color = shade_color(u8(103), base_light, depth)
					dc_source = []u8{}
					dc_texheight = 0
					dc_yl = top
					dc_yh = bot
					r_draw_column()
				}
			} else {
				dc_x = x
				dc_color = shade_color(u8(103), base_light, depth)
				dc_source = []u8{}
				dc_texheight = 0
				dc_yl = top
				dc_yh = bot
				r_draw_column()
			}

			// FLOOR flat
			if bot < clip_bot && floor_flat.len >= flat_bytes {
				draw_flat_columns(x, bot + 1, clip_bot, front, floor_flat, depth, base_light)
			} else if bot < clip_bot {
				dc_x = x
				dc_color = shade_color(u8(121), base_light, depth)
				dc_source = []u8{}
				dc_texheight = 0
				dc_yl = bot + 1
				dc_yh = clip_bot
				r_draw_column()
			}

			// Fully occlude this column
			ceilingclip[x] = i16(clip_bot)
			floorclip[x] = i16(clip_top)
		} else {
			// Two-sided line (portal)
			back_floor := back.floorheight
			back_ceil := back.ceilingheight
			back_ceil_sy := half_h - int(i64(back_ceil - viewz) * i64(half_w) / i64(depth))
			back_floor_sy := half_h - int(i64(back_floor - viewz) * i64(half_w) / i64(depth))

			mut bt := back_ceil_sy
			mut bb := back_floor_sy
			if bt < clip_top {
				bt = clip_top
			}
			if bb > clip_bot {
				bb = clip_bot
			}

			// Upper wall (ceiling step)
			if bt > top {
				// Ceiling flat
				if ceil_flat.len >= flat_bytes {
					draw_flat_columns(x, clip_top, top - 1, front, ceil_flat, depth, base_light)
				} else if top > clip_top {
					dc_x = x
					dc_color = shade_color(u8(199), base_light, depth)
					dc_source = []u8{}
					dc_texheight = 0
					dc_yl = clip_top
					dc_yh = top - 1
					r_draw_column()
				}

				// Upper wall texture
				if upper_wt.width > 0 {
					u := int(tex_u >> frac_bits)
					c := ((u % upper_wt.width) + upper_wt.width) % upper_wt.width
					col := upper_wt.columns[c]
					if col.len > 0 {
						upper_height := bt - 1 - top
						upper_iscale := if upper_height > 0 {
							Fixed(int(i64(ceil_h - back_ceil) / i64(upper_height)))
						} else {
							Fixed(frac_unit)
						}
						dc_x = x
						unsafe { dc_source = col }
						dc_texheight = col.len
						dc_texturemid = tex_yoffset
						dc_iscale = upper_iscale
						dc_yl = top
						dc_yh = bt - 1
						r_draw_column()
					} else {
						dc_x = x
						dc_color = shade_color(u8(103), base_light, depth)
						dc_source = []u8{}
						dc_texheight = 0
						dc_yl = top
						dc_yh = bt - 1
						r_draw_column()
					}
				} else {
					dc_x = x
					dc_color = shade_color(u8(103), base_light, depth)
					dc_source = []u8{}
					dc_texheight = 0
					dc_yl = top
					dc_yh = bt - 1
					r_draw_column()
				}

				ceilingclip[x] = i16(bt - 1)
			} else if top > clip_top {
				if ceil_flat.len >= flat_bytes {
					draw_flat_columns(x, clip_top, top - 1, front, ceil_flat, depth, base_light)
				} else {
					dc_x = x
					dc_color = shade_color(u8(199), base_light, depth)
					dc_source = []u8{}
					dc_texheight = 0
					dc_yl = clip_top
					dc_yh = top - 1
					r_draw_column()
				}
				ceilingclip[x] = i16(top - 1)
			}

			// Lower wall (floor step)
			if bb < bot {
				// Lower wall texture
				if lower_wt.width > 0 {
					u := int(tex_u >> frac_bits)
					c := ((u % lower_wt.width) + lower_wt.width) % lower_wt.width
					col := lower_wt.columns[c]
					if col.len > 0 {
						lower_height := bot - (bb + 1)
						lower_iscale := if lower_height > 0 {
							Fixed(int(i64(back_floor - floor_h) / i64(lower_height)))
						} else {
							Fixed(frac_unit)
						}
						dc_x = x
						unsafe { dc_source = col }
						dc_texheight = col.len
						dc_texturemid = tex_yoffset
						dc_iscale = lower_iscale
						dc_yl = bb + 1
						dc_yh = bot
						r_draw_column()
					} else {
						dc_x = x
						dc_color = shade_color(u8(103), base_light, depth)
						dc_source = []u8{}
						dc_texheight = 0
						dc_yl = bb + 1
						dc_yh = bot
						r_draw_column()
					}
				} else {
					dc_x = x
					dc_color = shade_color(u8(103), base_light, depth)
					dc_source = []u8{}
					dc_texheight = 0
					dc_yl = bb + 1
					dc_yh = bot
					r_draw_column()
				}

				// Floor flat
				if floor_flat.len >= flat_bytes {
					draw_flat_columns(x, bot + 1, clip_bot, front, floor_flat, depth, base_light)
				} else if bot < clip_bot {
					dc_x = x
					dc_color = shade_color(u8(121), base_light, depth)
					dc_source = []u8{}
					dc_texheight = 0
					dc_yl = bot + 1
					dc_yh = clip_bot
					r_draw_column()
				}

				floorclip[x] = i16(bb + 1)
			} else if bot < clip_bot {
				if floor_flat.len >= flat_bytes {
					draw_flat_columns(x, bot + 1, clip_bot, front, floor_flat, depth, base_light)
				} else {
					dc_x = x
					dc_color = shade_color(u8(121), base_light, depth)
					dc_source = []u8{}
					dc_texheight = 0
					dc_yl = bot + 1
					dc_yh = clip_bot
					r_draw_column()
				}
				floorclip[x] = i16(bot + 1)
			}
		}
	}
}

// draw_flat_columns draws a vertical strip of a flat texture for floor/ceiling.
fn draw_flat_columns(x int, y1 int, y2 int, sector &Sector, flat []u8, depth Fixed, light int) {
	if x < 0 || x >= screenwidth || flat.len < flat_bytes {
		return
	}
	mut ya := y1
	mut yb := y2
	if ya < 0 {
		ya = 0
	}
	if yb >= screenheight {
		yb = screenheight - 1
	}
	if ya > yb {
		return
	}
	mut buf := v_buffer()
	half_h := screenheight / 2
	half_w := screenwidth / 2
	for y in ya .. yb + 1 {
		// Compute the distance for this scanline
		dy := y - half_h
		if dy == 0 {
			continue
		}
		// distance = height * projection / dy
		// For floors/ceilings, use a simple approximation
		dist := if dy > 0 {
			// Floor
			Fixed(int(i64(viewz - sector.floorheight) * i64(half_w) / i64(dy)))
		} else {
			// Ceiling
			Fixed(int(i64(sector.ceilingheight - viewz) * i64(half_w) / i64(-dy)))
		}
		if dist <= 0 {
			continue
		}
		// Compute world X/Y at this point
		// Use viewangle to rotate
		xstep := fixed_mul(viewsin, dist)
		ystep := fixed_mul(viewcos, dist)
		// X offset from center of screen
		screen_dx := x - half_w
		wx := viewx + fixed_mul(viewcos, dist) + Fixed(int(i64(screen_dx) * i64(xstep) / i64(half_w)))
		wy := viewy + fixed_mul(viewsin, dist) - Fixed(int(i64(screen_dx) * i64(ystep) / i64(half_w)))

		// Sample flat
		tx := (int(wx >> frac_bits) & 63)
		ty := (int(wy >> frac_bits) & 63)
		fidx := ((ty & 63) * 64 + (tx & 63))
		if fidx >= 0 && fidx < flat.len {
			pix := shade_color(flat[fidx], light, dist)
			buf[y * screenwidth + x] = pix
		}
	}
}
