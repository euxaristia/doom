@[has_globals]
module core

import os

__global maplumpinfo = &LumpInfo(unsafe { nil })
__global level_setup_count = 0
__global last_setup_episode = 0
__global last_setup_map = 0

pub fn p_setup_level(episode int, mapnum int, playermask int, skill int) {
	level_setup_count++
	last_setup_episode = episode
	last_setup_map = mapnum
	gameskill = skill
	gameepisode = episode
	gamemap = mapnum
	_ = playermask
	leveltime = 0
	set_game_state(.level)
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
	
	// Load map data from WAD
	wad := load_wad_with_options(wadfile, true, false) or { return }
	
	if !wad.has_lump(lumpname) {
		println('map not found: ${lumpname}')
		return
	}
	
	map_base := wad.find_lump_index(lumpname)
	
	// Load all map components
	p_load_blockmap(map_base + 5) // ML_BLOCKMAP
	p_load_vertexes(map_base + 1) // ML_VERTEXES
	p_load_sectors(map_base + 2)  // ML_SECTORS
	p_load_sidedefs(map_base + 3) // ML_SIDEDEFS
	p_load_linedefs(map_base + 4) // ML_LINEDEFS
	p_load_subsectors(map_base + 6) // ML_SSECTORS
	p_load_nodes(map_base + 7)    // ML_NODES
	p_load_segs(map_base + 8)    // ML_SEGS
	p_load_reject(map_base + 9)   // ML_REJECT
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

pub fn p_load_vertexes(lump int) {
	wad := load_wad_with_options(wadfile, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numvertexes = data.len / 4
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
	wad := load_wad_with_options(wadfile, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numsectors = data.len / 26
	sectors = []Sector{len: numsectors}
	
	for i in 0 .. numsectors {
		offset := i * 26
		floorheight := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		ceilingheight := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		floorpic := i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
		ceilingpic := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		lightlevel := i16(data[offset + 8]) | (i16(data[offset + 9]) << 10)
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
	wad := load_wad_with_options(wadfile, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numsides = data.len / 30
	sides = []Side{len: numsides}
	
	for i in 0 .. numsides {
		offset := i * 30
		textureoffset := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		rowoffset := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		toptexture := i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
		bottomtexture := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		midtexture := i16(data[offset + 8]) | (i16(data[offset + 9]) << 10)
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
	wad := load_wad_with_options(wadfile, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numlines = data.len / 14
	lines = []Line{len: numlines}
	
	for i in 0 .. numlines {
		offset := i * 14
		v1 := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		v2 := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		flags := i16(data[offset + 4]) | (i16(data[offset + 5]) << 8)
		special := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		tag := i16(data[offset + 8]) | (i16(data[offset + 9]) << 10)
		
		mut line := &lines[i]
		if v1 >= 0 && v1 < numvertexes {
			line.v1 = &vertexes[v1]
		}
		if v2 >= 0 && v2 < numvertexes {
			line.v2 = &vertexes[v2]
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
	wad := load_wad_with_options(wadfile, true, false) or { return }
	data := wad.read_lump_num(lump) or { return }
	
	numsegs = data.len / 12
	segs = []Seg{len: numsegs}
	
	for i in 0 .. numsegs {
		offset := i * 12
		v1 := i16(data[offset]) | (i16(data[offset + 1]) << 8)
		v2 := i16(data[offset + 2]) | (i16(data[offset + 3]) << 8)
		angle := u16(data[offset + 4]) | (u16(data[offset + 5]) << 8)
		linedef := i16(data[offset + 6]) | (i16(data[offset + 7]) << 8)
		side := i16(data[offset + 8]) | (i16(data[offset + 9]) << 8)
		offset_ := i16(data[offset + 10]) | (i16(data[offset + 11]) << 8)
		
		mut seg := &segs[i]
		if v1 >= 0 && v1 < numvertexes {
			seg.v1 = &vertexes[v1]
		}
		if v2 >= 0 && v2 < numvertexes {
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
	wad := load_wad_with_options(wadfile, true, false) or { return }
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
	wad := load_wad_with_options(wadfile, true, false) or { return }
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
			
			// Read children indices (2 bytes each)
			for j in 0 .. 2 {
				child_offset := offset + 8 + j * 2
				if child_offset + 1 < data.len {
					child := i16(data[child_offset]) | (i16(data[child_offset + 1]) << 8)
					nodes[i].children[j] = u16(child)
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
	// Blockmap not needed for basic rendering
	_ = lump
}

pub fn p_load_reject(lump int) {
	// Reject matrix not needed for basic rendering
	_ = lump
}

pub fn p_group_lines() {}

pub fn p_spawn_map_thing(mthing voidptr) {
	_ = mthing
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
