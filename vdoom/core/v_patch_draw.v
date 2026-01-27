@[has_globals]
module core

struct PatchImage {
	width      int
	height     int
	leftoffset int
	topoffset  int
	columnofs  []int
	data       []u8
}

__global patch_cache = map[string]PatchImage{}
__global patch_cache_wad = ''

fn patch_cache_key(wad_path string, name string) string {
	return '${wad_path}::${name.to_upper()}'
}

fn u16_le(data []u8, off int) ?int {
	if off + 2 > data.len {
		return none
	}
	return int(u16(data[off]) | (u16(data[off + 1]) << 8))
}

fn u32_le(data []u8, off int) ?int {
	if off + 4 > data.len {
		return none
	}
	return int(u32(data[off]) | (u32(data[off + 1]) << 8) | (u32(data[off + 2]) << 16) | (u32(data[off + 3]) << 24))
}

fn load_patch_image(mut wad Wad, name string) ?PatchImage {
	raw := wad.read_lump(name) or { return none }
	if raw.len < 8 {
		return none
	}
	width := u16_le(raw, 0) or { return none }
	height := u16_le(raw, 2) or { return none }
	leftoffset := u16_le(raw, 4) or { return none }
	topoffset := u16_le(raw, 6) or { return none }
	if width <= 0 || height <= 0 || width > 2048 || height > 2048 {
		return none
	}
	mut columnofs := []int{len: width}
	for i in 0 .. width {
		off := u32_le(raw, 8 + i * 4) or { return none }
		columnofs[i] = off
	}
	return PatchImage{
		width: width
		height: height
		leftoffset: leftoffset
		topoffset: topoffset
		columnofs: columnofs
		data: raw
	}
}

fn load_patch_image_cached(mut wad Wad, name string) ?PatchImage {
	if patch_cache_wad != wad.path {
		patch_cache = map[string]PatchImage{}
		patch_cache_wad = wad.path
	}
	key := patch_cache_key(wad.path, name)
	if key in patch_cache {
		return patch_cache[key]
	}
	img := load_patch_image(mut wad, name) or { return none }
	patch_cache[key] = img
	return img
}

fn draw_patch_image(x int, y int, img PatchImage) {
	if img.data.len == 0 {
		return
	}
	mut dest := v_buffer()
	for col in 0 .. img.width {
		draw_patch_column(mut dest, x, y, img, col, col)
	}
}

fn draw_patch_image_flipped(x int, y int, img PatchImage) {
	if img.data.len == 0 {
		return
	}
	mut dest := v_buffer()
	for col in 0 .. img.width {
		src_col := img.width - 1 - col
		draw_patch_column(mut dest, x, y, img, col, src_col)
	}
}

fn draw_patch_column(mut dest []u8, x int, y int, img PatchImage, col int, src_col int) {
	if src_col < 0 || src_col >= img.columnofs.len {
		return
	}
	mut p := img.columnofs[src_col]
	if p <= 0 || p >= img.data.len {
		return
	}
	dx := x + col - img.leftoffset
	if dx < 0 || dx >= screenwidth {
		return
	}
	for p < img.data.len {
		topdelta := img.data[p]
		if topdelta == 0xff {
			break
		}
		if p + 4 >= img.data.len {
			break
		}
		length := int(img.data[p + 1])
		// skip topdelta, length, unused byte
		p += 3
		for row in 0 .. length {
			if p + row >= img.data.len {
				break
			}
			dy := y + int(topdelta) + row - img.topoffset
			if dy < 0 || dy >= screenheight {
				continue
			}
			dest[dy * screenwidth + dx] = img.data[p + row]
		}
		// skip pixel data and trailing unused byte
		p += length + 1
	}
}

pub fn patch_cache_count() int {
	return patch_cache.len
}
