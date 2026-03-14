@[has_globals]
module core

import os

__global maplumpinfo = &LumpInfo(unsafe { nil })
__global level_setup_count = 0
__global last_setup_episode = 0
__global last_setup_map = 0
__global totallines = 0

pub fn p_setup_level(episode int, mapnum int, playermask int, skill int) {
	println('p_setup_level: episode=${episode}, mapnum=${mapnum}')
	level_setup_count++
	last_setup_episode = episode
	last_setup_map = mapnum
	gameskill = skill
	gameepisode = episode
	gamemap = mapnum
	_ = playermask
	leveltime = 0
	set_game_state(.level)
	render_was_patch = false
	p_init_thinkers()
	r_init_data()
	p_pspr_init()
	p_apply_time_limit()
	
	// Get the map lump name
	mut lumpname := ''
	if gamemode == .commercial {
		if mapnum < 10 {
			lumpname = 'map0${mapnum}'
		} else {
			lumpname = 'map${mapnum}'
		}
	} else {
		lumpname = 'E${episode}M${mapnum}'
	}
	
	println('p_setup_level: loading lump ${lumpname}')
	
	// Load map data from WAD
	wad := load_wad_with_options(iwad_path, true, false) or {
		println('p_setup_level: failed to load wad: ${err}')
		return
	}
	
	if !wad.has_lump(lumpname) {
		println('p_setup_level: lump ${lumpname} not found')
		return
	}
	
	map_base := wad.find_lump_index(lumpname)
	println('p_setup_level: map_base=${map_base}')
	
	// Load all map components
	p_load_blockmap(map_base + 10) // ML_BLOCKMAP
	p_load_vertexes(map_base + 4) // ML_VERTEXES
	p_load_sectors(map_base + 8)  // ML_SECTORS
	p_load_sidedefs(map_base + 3) // ML_SIDEDEFS
	p_load_linedefs(map_base + 2) // ML_LINEDEFS
	p_load_subsectors(map_base + 6) // ML_SSECTORS
	p_load_nodes(map_base + 7)    // ML_NODES
	p_load_segs(map_base + 5)     // ML_SEGS
	p_load_reject(map_base + 9)   // ML_REJECT
	p_load_things(map_base + 1)   // ML_THINGS
	p_group_lines()
	
	println('loaded map: ${lumpname}')
	println('  vertexes: ${numvertexes}')
	println('  sectors: ${numsectors}')
	println('  lines: ${numlines}')
	println('  nodes: ${numnodes}')
	println('  subsectors: ${numsubsectors}')
	println('  segs: ${numsegs}')
	
	v_clear_screen(0)
	_ = r_patch_num_for_name('TITLEPIC')
}

pub fn p_init() {
	level_setup_count = 0
}

pub fn p_load_things(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numthings := data.len / 10
	
	for i in 0 .. numthings {
		offset := i * 10
		mt := &MapThing{
			x: i16(data[offset]) | (i16(data[offset + 1]) << 8)
			y: i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
			angle: i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
			typ: i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
			options: i16(data[offset + 8]) | (i16(data[offset + 9]) << 8)
		}
		p_spawn_map_thing(mt)
	}
}

pub fn p_spawn_map_thing(mthing voidptr) {
	mt := unsafe { &MapThing(mthing) }
	
	if mt.typ == 1 {
		// Player 1 spawn
		mut player := &players[0]
		x := Fixed(int(mt.x) * 65536)
		y := Fixed(int(mt.y) * 65536)
		z := Fixed(0) // ONFLOORZ
		
		mobj := p_spawn_player(x, y, z, player)
		player.mo = mobj
		player.playerstate = .live
		player.viewz = Fixed(41 * 65536)
		player.viewheight = Fixed(41 * 65536)
		
		println('Spawned player 1 at (${mt.x}, ${mt.y})')
	}
}

pub fn p_load_vertexes(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numvertexes = data.len / 4
	println('p_load_vertexes: lump=${lump}, data.len=${data.len}, numvertexes=${numvertexes}')
	vertexes = []Vertex{len: numvertexes}
	
	for i in 0 .. numvertexes {
		offset := i * 4
		x := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		y := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		vertexes[i] = Vertex{
			x: Fixed(x)
			y: Fixed(y)
		}
	}
}

pub fn p_load_sectors(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numsectors = data.len / 26
	sectors = []Sector{len: numsectors}
	
	for i in 0 .. numsectors {
		offset := i * 26
		floorheight := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		ceilingheight := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		floorpic := i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
		ceilingpic := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		lightlevel := i16(data[offset + 8]) | (i16(data[offset + 9]) << 8)
		special := i16(data[offset + 10]) | (i16(data[offset + 11]) << 8)
		tag := i16(data[offset + 12]) | (i16(data[offset + 13]) << 8)
		
		sectors[i] = Sector{
			floorheight: Fixed(floorheight)
			ceilingheight: Fixed(ceilingheight)
			floorpic: floorpic
			ceilingpic: ceilingpic
			lightlevel: lightlevel
			special: special
			tag: tag
		}
	}
}

pub fn p_load_sidedefs(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numsides = data.len / 30
	sides = []Side{len: numsides}
	
	for i in 0 .. numsides {
		offset := i * 30
		textureoffset := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		rowoffset := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		toptexture := i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
		bottomtexture := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		midtexture := i16(data[offset + 8]) | (i16(data[offset + 9]) << 8)
		sector_idx := i16(data[offset + 28]) | (i16(data[offset + 29]) << 8)
		
		sides[i] = Side{
			textureoffset: Fixed(textureoffset)
			rowoffset: Fixed(rowoffset)
			toptexture: toptexture
			bottomtexture: bottomtexture
			midtexture: midtexture
		}
		
		// Link to sector
		sec := int(sector_idx)
		if sec >= 0 && sec < numsectors {
			sides[i].sector = &sectors[sec]
		}
	}
}

pub fn p_load_linedefs(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numlines = data.len / 14
	println('p_load_linedefs: lump=${lump}, data.len=${data.len}, numlines=${numlines}, numvertexes=${numvertexes}')
	lines = []Line{len: numlines}
	
	for i in 0 .. numlines {
		offset := i * 14
		v1 := u16(data[offset]) | (u16(data[offset + 1]) << 8)
		v2 := u16(data[offset + 2]) | (u16(data[offset + 3]) << 8)
		flags := i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
		special := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		tag := i16(data[offset + 8]) | (i16(data[offset + 9]) << 8)
		
		if i < 5 {
			println('Line ${i}: v1=${v1}, v2=${v2}, numvertexes=${numvertexes}')
		}
		
		mut line := &lines[i]
		if int(v1) < numvertexes {
			line.v1 = &vertexes[v1]
		} else {
			println('ERROR: v1=${v1} >= numvertexes=${numvertexes}')
		}
		if int(v2) < numvertexes {
			line.v2 = &vertexes[v2]
		} else {
			println('ERROR: v2=${v2} >= numvertexes=${numvertexes}')
		}
		line.dx = line.v2.x - line.v1.x
		line.dy = line.v2.y - line.v1.y
		line.flags = flags
		line.special = special
		line.tag = tag
		line.sidenum[0] = i16(data[offset + 10]) | (i16(data[offset + 11]) << 8)
		line.sidenum[1] = i16(data[offset + 12]) | (i16(data[offset + 13]) << 8)
		
		if line.v1.x < line.v2.x {
			line.bbox[0] = line.v1.x
			line.bbox[1] = line.v2.x
		} else {
			line.bbox[0] = line.v2.x
			line.bbox[1] = line.v1.x
		}
		if line.v1.y < line.v2.y {
			line.bbox[2] = line.v1.y
			line.bbox[3] = line.v2.y
		} else {
			line.bbox[2] = line.v2.y
			line.bbox[3] = line.v1.y
		}
		
		if line.dx == 0 {
			line.slopetype = .vertical
		} else if line.dy == 0 {
			line.slopetype = .horizontal
		} else if line.dy > 0 {
			line.slopetype = .positive
		} else {
			line.slopetype = .negative
		}
		
		if line.sidenum[0] >= 0 && line.sidenum[0] < numsides {
			line.frontsector = sides[line.sidenum[0]].sector
		}
		if line.sidenum[1] >= 0 && line.sidenum[1] < numsides {
			line.backsector = sides[line.sidenum[1]].sector
		}
	}
}

pub fn p_load_segs(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numsegs = data.len / 12
	segs = []Seg{len: numsegs}
	
	for i in 0 .. numsegs {
		offset := i * 12
		v1 := u16(data[offset]) | (u16(data[offset + 1]) << 8)
		v2 := u16(data[offset + 2]) | (u16(data[offset + 3]) << 8)
		angle := u16(data[offset + 4]) | (u16(data[offset + 5]) << 8)
		linedef := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		side := i16(data[offset + 8]) | (i16(data[offset + 9]) << 8)
		offset_ := i16(data[offset + 10]) | (i16(data[offset + 11]) << 8)
		
		mut seg := &segs[i]
		if int(v1) < numvertexes {
			seg.v1 = &vertexes[v1]
		}
		if int(v2) < numvertexes {
			seg.v2 = &vertexes[v2]
		}
		seg.angle = angle
		seg.offset = offset_
		
		if linedef >= 0 && linedef < numlines {
			seg.linedef = &lines[linedef]
			if side == 0 {
				seg.frontsector = seg.linedef.frontsector
			} else {
				seg.frontsector = seg.linedef.backsector
			}
		}
	}
}

pub fn p_load_subsectors(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numsubsectors = data.len / 4
	subsectors = []Subsector{len: numsubsectors}
	
	for i in 0 .. numsubsectors {
		offset := i * 4
		firstseg := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		numlines := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		
		subsectors[i] = Subsector{
			firstline: firstseg
			numlines: numlines
		}
	}
	
	// Link to sectors
	for i in 0 .. numsubsectors {
		mut ss := &subsectors[i]
		if ss.firstline >= 0 && int(ss.firstline) < numsegs {
			seg := &segs[ss.firstline]
			ss.sector = seg.frontsector
		}
	}
}

pub fn p_load_nodes(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	// Nodes are 28 bytes each
	if data.len >= 28 {
		numnodes = (data.len - 8) / 28 + 1
		if numnodes * 28 + 8 > data.len {
			numnodes = data.len / 28
		}
	} else {
		numnodes = 0
	}
	
		if numnodes > 0 {
		nodes = []Node{len: numnodes}
		
		for i in 0 .. numnodes {
			offset := 8 + i * 28
			if offset + 28 > data.len {
				break
			}
			
			x := i16(data[offset]) | (i16(data[offset + 1]) << 8)
			y := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
			dx := i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
			dy := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
			
			nodes[i] = Node{
				x: Fixed(x)
				y: Fixed(y)
				dx: Fixed(dx)
				dy: Fixed(dy)
			}
			
			// Read children indices (2 bytes each) - at bytes 24-27 in node
			for j in 0 .. 2 {
				child_offset := offset + 24 + j * 2
				if child_offset + 1 < data.len {
					child := u16(data[child_offset]) | (u16(data[child_offset + 1]) << 8)
					nodes[i].children[j] = child
				}
			}
			
			// Read bounding boxes (4 bytes each, 2 ints)
			for j in 0 .. 2 {
				box_offset := offset + 12 + j * 4
				if box_offset + 3 < data.len {
					min := i16(data[box_offset]) | (i16(data[box_offset + 1]) << 8)
					max := i16(data[box_offset + 2]) | (i16(data[box_offset + 3]) << 8)
					nodes[i].bbox[j][0] = Fixed(min)
					nodes[i].bbox[j][1] = Fixed(max)
				}
			}
		}
	}
}

pub fn p_load_blockmap(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data :=wad.read_lump_num(lump) or { return }
	
	if data.len < 8 {
		return
	}
	
	count := data.len / 2
	if count >= 0x10000 {
		return
	}
	
	blockmaplump = []i16{len: count}
	for i in 0 .. count {
		mut t := i16(data[i * 2]) | (i16(data[i * 2 + 1]) << 8)
		blockmaplump[i] = t
	}
	
	blockmap = blockmaplump[4..]
	
	bmaporgx = Fixed(int(blockmaplump[0]) << frac_bits)
	bmaporgy = Fixed(int(blockmaplump[1]) << frac_bits)
	bmapwidth = int(blockmaplump[2])
	bmapheight = int(blockmaplump[3])
	
	blocklinks = []voidptr{len: bmapwidth * bmapheight}
	println('p_load_blockmap: ${bmapwidth}x${bmapheight}')
}

pub fn p_load_reject(lump int) {
	wad := load_wad_with_options(iwad_path, true, false) or { return }
	data :=wad.read_lump_num(lump) or { return }
	
	rejectmatrix = data.clone()
	println('p_load_reject: ${data.len} bytes')
}

pub fn p_group_lines() {
	// Look up sector number for each subsector
	for i in 0 .. numsubsectors {
		mut ss := &subsectors[i]
		if int(ss.firstline) < numsegs {
			seg := &segs[ss.firstline]
			if seg.linedef != unsafe { nil } && seg.linedef.sidenum[0] >= 0
				&& seg.linedef.sidenum[0] < numsides {
				ss.sector = sides[seg.linedef.sidenum[0]].sector
			}
		}
	}
	
	// Reset linecount for all sectors
	for i in 0 .. numsectors {
		sectors[i].linecount = 0
	}
	
	// Count lines in each sector
	mut totallines := 0
	for i in 0 .. numlines {
		mut li := &lines[i]
		if li.frontsector != unsafe { nil } {
			li.frontsector.linecount++
			totallines++
		}
		if li.backsector != unsafe { nil } && li.backsector != li.frontsector {
			li.backsector.linecount++
			totallines++
		}
	}
	
	// Allocate line buffer for each sector
	for i in 0 .. numsectors {
		if sectors[i].linecount > 0 {
			sectors[i].lines = []&Line{len: sectors[i].linecount}
		}
		sectors[i].linecount = 0
	}
	
	// Assign lines to sectors
	for i in 0 .. numlines {
		li := &lines[i]
		
		if li.frontsector != unsafe { nil } {
			mut sector := li.frontsector
			sector.lines[sector.linecount] = li
			sector.linecount++
		}
		
		if li.backsector != unsafe { nil } && li.frontsector != li.backsector {
			mut sector := li.backsector
			sector.lines[sector.linecount] = li
			sector.linecount++
		}
	}
	
	// Generate bounding boxes for sectors
	for i in 0 .. numsectors {
		mut sec := &sectors[i]
		if sec.lines.len > 0 {
			mut minx := Fixed(0x7fffffff)
			mut maxx := Fixed(-0x80000000)
			mut miny := Fixed(0x7fffffff)
			mut maxy := Fixed(-0x80000000)
			
			for j in 0 .. sec.lines.len {
				li := sec.lines[j]
				if li.v1.x < minx { minx = li.v1.x }
				if li.v1.x > maxx { maxx = li.v1.x }
				if li.v2.x < minx { minx = li.v2.x }
				if li.v2.x > maxx { maxx = li.v2.x }
				if li.v1.y < miny { miny = li.v1.y }
				if li.v1.y > maxy { maxy = li.v1.y }
				if li.v2.y < miny { miny = li.v2.y }
				if li.v2.y > maxy { maxy = li.v2.y }
			}
			sec.blockbox[0] = maxx
			sec.blockbox[1] = minx
			sec.blockbox[2] = maxy
			sec.blockbox[3] = miny
		}
	}
	
	// Generate blockmap bounding boxes for sectors
	for i in 0 .. numsectors {
		mut sec := &sectors[i]
		if sec.linecount > 0 {
			mut blockx := (sec.blockbox[1] - bmaporgx) >> mapblockshift
			mut blocky := (sec.blockbox[3] - bmaporgy) >> mapblockshift
			blockx = if blockx < 0 { 0 } else { blockx }
			blocky = if blocky < 0 { 0 } else { blocky }
			blockx = if blockx >= bmapwidth { bmapwidth - 1 } else { blockx }
			blocky = if blocky >= bmapheight { bmapheight - 1 } else { blocky }
			sec.blockbox[0] = blockx
			sec.blockbox[2] = blocky
		}
	}
	
	println('p_group_lines: ${numlines} lines, ${numsectors} sectors')
}


pub fn p_get_num_for_map(episode int, mapnum int) int {
	_ = episode
	_ = mapnum
	return 0
}

pub fn p_remove_slime_trails() {}

pub fn p_check_lump_for_emerald() {
	// Check if level has emerald
}
