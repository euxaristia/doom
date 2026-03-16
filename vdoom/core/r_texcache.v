@[has_globals]
module core

// Flat textures are 64x64 raw pixel data.
const flat_size = 64
const flat_bytes = flat_size * flat_size

// Texture cache for flats and wall textures.
__global flat_cache = map[string][]u8{}
__global wall_tex_cache = map[int]WallTexture{}
__global tex_wad_loaded = false
__global tex_wad_path = ''

// Numeric index caches for names
__global flat_num_cache = map[string]int{}
__global texture_num_cache = map[string]int{}
__global iwad_obj_loaded = false
__global iwad_obj = Wad{}

fn get_iwad() ?Wad {
	if iwad_obj_loaded {
		return iwad_obj
	}
	if iwad_path.len == 0 {
		return none
	}
	w := load_wad_with_options(iwad_path, true, true) or { return none }
	iwad_obj = w
	iwad_obj_loaded = true
	return iwad_obj
}

// PNAMES and TEXTURE1/TEXTURE2 parsing
__global pnames_list = []string{}

__global tex_defs = []TexDef{}

struct TexPatch {
	originx i16
	originy i16
	patch   i16
}

struct TexDef {
	name    string
	width   int
	height  int
	patches []TexPatch
}

struct WallTexture {
	width  int
	height int
	// Column data: array of columns, each column is height bytes
	columns [][]u8
}

// load_tex_defs loads PNAMES and TEXTURE1/TEXTURE2 from the WAD.
pub fn load_tex_defs() {
	if tex_wad_loaded {
		return
	}
	tex_wad_loaded = true
	if iwad_path.len == 0 {
		return
	}
	tex_wad_path = iwad_path
	wad := load_wad_with_options(iwad_path, true, true) or { return }

	// Load PNAMES
	pdata := wad.read_lump('PNAMES') or { return }
	if pdata.len < 4 {
		return
	}
	num_patches := int(u32(pdata[0]) | (u32(pdata[1]) << 8) | (u32(pdata[2]) << 16) | (u32(pdata[3]) << 24))
	pnames_list = []string{len: num_patches}
	for i in 0 .. num_patches {
		off := 4 + i * 8
		if off + 8 > pdata.len {
			break
		}
		mut name := []u8{len: 8}
		for j in 0 .. 8 {
			name[j] = pdata[off + j]
		}
		pnames_list[i] = bytes_to_name(name).to_upper()
	}

	// Load TEXTURE1
	load_texture_lump(wad, 'TEXTURE1')
	// Load TEXTURE2 if present
	if wad.has_lump('TEXTURE2') {
		load_texture_lump(wad, 'TEXTURE2')
	}
}

pub fn bytes_to_name(data []u8) string {
	mut end := 0
	for end < data.len && data[end] != 0 {
		end++
	}
	return data[..end].bytestr()
}

// get_wall_texture_num_for_name returns the numeric index of a texture by name.
pub fn get_wall_texture_num_for_name(name string) int {
	if name == '-' {
		return -1
	}
	key := name.to_upper()
	if key in texture_num_cache {
		return texture_num_cache[key]
	}
	load_tex_defs()
	for i, td in tex_defs {
		if td.name == key {
			texture_num_cache[key] = i
			return i
		}
	}
	texture_num_cache[key] = -1
	return -1
}

// get_flat_num_for_name returns the numeric index of a flat by name.
pub fn get_flat_num_for_name(name string) int {
	if name == '-' {
		return -1
	}
	key := name.to_upper()
	if key in flat_num_cache {
		return flat_num_cache[key]
	}
	wad := get_iwad() or { return -1 }
	mut f_start := -1
	mut f_end := -1
	for i in 0 .. wad.num_lumps {
		n := wad.lumps[i].name.to_upper()
		if n == 'F_START' || n == 'FF_START' {
			f_start = i
		}
		if n == 'F_END' || n == 'FF_END' {
			f_end = i
			break
		}
	}
	if f_start < 0 || f_end < 0 {
		flat_num_cache[key] = -1
		return -1
	}
	mut flat_idx := 0
	for i in f_start + 1 .. f_end {
		if wad.lumps[i].size == 0 {
			continue
		}
		if wad.lumps[i].name.to_upper() == key {
			flat_num_cache[key] = flat_idx
			return flat_idx
		}
		flat_idx++
	}
	flat_num_cache[key] = -1
	return -1
}

fn load_texture_lump(wad Wad, lump_name string) {
	data := wad.read_lump(lump_name) or { return }
	if data.len < 4 {
		return
	}
	num_textures := int(u32(data[0]) | (u32(data[1]) << 8) | (u32(data[2]) << 16) | (u32(data[3]) << 24))
	for i in 0 .. num_textures {
		off_idx := 4 + i * 4
		if off_idx + 4 > data.len {
			break
		}
		off := int(u32(data[off_idx]) | (u32(data[off_idx + 1]) << 8) | (u32(data[off_idx + 2]) << 16) | (u32(data[off_idx + 3]) << 24))
		if off + 22 > data.len {
			continue
		}
		mut name_bytes := []u8{len: 8}
		for j in 0 .. 8 {
			name_bytes[j] = data[off + j]
		}
		name := bytes_to_name(name_bytes).to_upper()
		// skip 4 bytes (masked, unused)
		width := int(u16(data[off + 12]) | (u16(data[off + 13]) << 8))
		height := int(u16(data[off + 14]) | (u16(data[off + 15]) << 8))
		// skip 4 bytes (columndirectory, unused)
		patch_count := int(u16(data[off + 20]) | (u16(data[off + 21]) << 8))
		mut patches := []TexPatch{len: patch_count}
		for p in 0 .. patch_count {
			poff := off + 22 + p * 10
			if poff + 10 > data.len {
				break
			}
			patches[p] = TexPatch{
				originx: i16(u16(data[poff]) | (u16(data[poff + 1]) << 8))
				originy: i16(u16(data[poff + 2]) | (u16(data[poff + 3]) << 8))
				patch: i16(u16(data[poff + 4]) | (u16(data[poff + 5]) << 8))
			}
		}
		tex_defs << TexDef{
			name: name
			width: width
			height: height
			patches: patches
		}
	}
}

// get_flat loads a flat texture (64x64 raw pixels) by name.
pub fn get_flat(name string) []u8 {
	key := name.to_upper()
	if key in flat_cache {
		return flat_cache[key]
	}
	wad := get_iwad() or { return []u8{} }
	data := wad.read_lump(key) or { return []u8{} }
	if data.len >= flat_bytes {
		flat_cache[key] = data[..flat_bytes]
		return flat_cache[key]
	}
	return []u8{}
}

// get_flat_by_num loads a flat by its numeric index.
// We need to find the flat name from the WAD flat list.
pub fn get_flat_by_num(num int) []u8 {
	wad := get_iwad() or { return []u8{} }
	// Find F_START marker
	mut f_start := -1
	mut f_end := -1
	for i in 0 .. wad.num_lumps {
		n := wad.lumps[i].name.to_upper()
		if n == 'F_START' || n == 'FF_START' {
			f_start = i
		}
		if n == 'F_END' || n == 'FF_END' {
			f_end = i
			break
		}
	}
	if f_start < 0 || f_end < 0 {
		return []u8{}
	}
	// Count flats between markers
	mut flat_idx := 0
	for i in f_start + 1 .. f_end {
		if wad.lumps[i].size == 0 {
			continue
		}
		if flat_idx == num {
			name := wad.lumps[i].name.to_upper()
			return get_flat(name)
		}
		flat_idx++
	}
	return []u8{}
}

// build_wall_texture builds a composite wall texture from patches.
fn build_wall_texture(td &TexDef) WallTexture {
	if td.width <= 0 || td.height <= 0 {
		return WallTexture{}
	}
	mut columns := [][]u8{len: td.width}
	for i in 0 .. td.width {
		columns[i] = []u8{len: td.height}
	}
	if iwad_path.len == 0 {
		return WallTexture{width: td.width, height: td.height, columns: columns}
	}
	mut wad := load_wad_with_options(iwad_path, true, true) or {
		return WallTexture{width: td.width, height: td.height, columns: columns}
	}
	// Composite patches onto the texture
	for tp in td.patches {
		pidx := int(tp.patch)
		if pidx < 0 || pidx >= pnames_list.len {
			continue
		}
		pname := pnames_list[pidx]
		img := load_patch_image(mut wad, pname) or { continue }
		// Draw patch columns
		for col in 0 .. img.width {
			tx := int(tp.originx) + col
			if tx < 0 || tx >= td.width {
				continue
			}
			if col >= img.columnofs.len {
				continue
			}
			mut p := img.columnofs[col]
			if p <= 0 || p >= img.data.len {
				continue
			}
			for p < img.data.len {
				topdelta := img.data[p]
				if topdelta == 0xff {
					break
				}
				p++
				if p >= img.data.len {
					break
				}
				length := int(img.data[p])
				p++
				if p >= img.data.len {
					break
				}
				p++ // skip padding byte
				for j in 0 .. length {
					ty := int(tp.originy) + int(topdelta) + j
					if ty >= 0 && ty < td.height && p < img.data.len {
						columns[tx][ty] = img.data[p]
					}
					p++
				}
				p++ // skip padding byte
			}
		}
	}
	return WallTexture{width: td.width, height: td.height, columns: columns}
}

// get_wall_texture returns a wall texture by its texture index.
pub fn get_wall_texture(tex_num int) WallTexture {
	if tex_num in wall_tex_cache {
		return wall_tex_cache[tex_num]
	}
	load_tex_defs()
	if tex_num < 0 || tex_num >= tex_defs.len {
		return WallTexture{}
	}
	wt := build_wall_texture(&tex_defs[tex_num])
	wall_tex_cache[tex_num] = wt
	return wt
}

// get_wall_texture_by_name returns a wall texture by name.
pub fn get_wall_texture_by_name(name string) WallTexture {
	load_tex_defs()
	key := name.to_upper()
	for i, td in tex_defs {
		if td.name == key {
			return get_wall_texture(i)
		}
	}
	return WallTexture{}
}

// get_wall_column returns a single column of a wall texture.
pub fn get_wall_column(tex_num int, col int) []u8 {
	wt := get_wall_texture(tex_num)
	if wt.width <= 0 || wt.columns.len == 0 {
		return []u8{}
	}
	c := ((col % wt.width) + wt.width) % wt.width
	if c < wt.columns.len {
		return wt.columns[c]
	}
	return []u8{}
}
