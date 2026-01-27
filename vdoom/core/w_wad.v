module core

import os

pub struct Wad {
pub:
	path       string
	kind       string
	num_lumps  int
	dir_offset int
	stream     bool
pub mut:
	lumps      []LumpInfo
	data       []u8
	has_hash   bool
	lumphash   []int
	cache      map[int][]u8
}

pub struct LumpInfo {
pub:
	name     string
	file_pos int
	size     int
pub mut:
	next int
}

pub fn load_wad(path string) !Wad {
	return load_wad_with_options(path, true, true)
}

pub fn load_wad_with_mode(path string, stream bool) !Wad {
	return load_wad_with_options(path, stream, true)
}

pub fn load_wad_with_options(path string, stream bool, build_hash bool) !Wad {
	mut file := if stream { open_file_stream(path)! } else { open_file(path)! }
	defer {
		close_file(mut file)
	}
	header := read_bytes(mut file, 0, 12)!
	kind := header[0..4].bytestr()
	if kind != 'IWAD' && kind != 'PWAD' {
		return error('invalid wad identification: $kind')
	}
	num_lumps := read_i32_le(header, 4)!
	dir_offset := read_i32_le(header, 8)!
	if num_lumps < 0 {
		return error('negative lump count')
	}
	if dir_offset < 0 {
		return error('negative directory offset')
	}
	dir_size := num_lumps * 16
	if dir_offset + dir_size > file.length {
		return error('wad directory exceeds file size')
	}
	dir := read_bytes(mut file, dir_offset, dir_size)!
	mut lumps := []LumpInfo{cap: num_lumps}
	for i in 0 .. num_lumps {
		entry_offset := i * 16
		file_pos := read_i32_le(dir, entry_offset)!
		size := read_i32_le(dir, entry_offset + 4)!
		name := read_name(dir, entry_offset + 8)!
		if file_pos < 0 || size < 0 {
			return error('invalid lump entry at index $i')
		}
		if file_pos + size > file.length {
			return error('lump $i exceeds file size')
		}
		lumps << LumpInfo{
			name: name
			file_pos: file_pos
			size: size
			next: -1
		}
	}
	mut wad := Wad{
		path: path
		kind: kind
		num_lumps: num_lumps
		dir_offset: dir_offset
		lumps: lumps
		stream: stream
		data: if stream { []u8{} } else { file.data }
		has_hash: false
		lumphash: []int{}
		cache: map[int][]u8{}
	}
	if build_hash {
		wad.build_hash_table()
	}
	return wad
}

pub fn wad_has_lump(path string, name string) bool {
	wad := load_wad_with_options(path, true, true) or { return false }
	return wad.has_lump(name)
}

pub fn wad_read_lump(path string, name string) ![]u8 {
	mut wad := load_wad_with_options(path, true, true)!
	return wad.read_lump(name)
}

pub fn (w Wad) find_lump_index(name string) int {
	if name.len == 0 || name.len > 8 {
		return -1
	}
	if w.has_hash && w.lumphash.len == w.num_lumps {
		hash := int(lump_name_hash(name) % u32(w.num_lumps))
		mut i := w.lumphash[hash]
		for i != -1 {
			if lump_name_eq(w.lumps[i].name, name) {
				return i
			}
			i = w.lumps[i].next
		}
		return -1
	}
	for i, l in w.lumps {
		if lump_name_eq(l.name, name) {
			return i
		}
	}
	return -1
}

pub fn (w Wad) has_lump(name string) bool {
	return w.find_lump_index(name) >= 0
}

pub fn (w Wad) read_lump(name string) ![]u8 {
	idx := w.find_lump_index(name)
	if idx < 0 {
		return error('lump not found: $name')
	}
	l := w.lumps[idx]
	if w.stream || w.data.len == 0 {
		mut file := open_file_stream(w.path)!
		defer {
			close_file(mut file)
		}
		return read_bytes(mut file, l.file_pos, l.size)!
	}
	if l.file_pos + l.size > w.data.len {
		return error('lump exceeds file size')
	}
	return w.data[l.file_pos..l.file_pos + l.size].clone()
}

pub fn (w Wad) lump_length(index int) !int {
	if index < 0 || index >= w.num_lumps {
		return error('lump index out of range')
	}
	return w.lumps[index].size
}

pub fn (w Wad) read_lump_num(index int) ![]u8 {
	if index < 0 || index >= w.num_lumps {
		return error('lump index out of range')
	}
	l := w.lumps[index]
	if w.stream || w.data.len == 0 {
		mut file := open_file_stream(w.path)!
		defer {
			close_file(mut file)
		}
		return read_bytes(mut file, l.file_pos, l.size)!
	}
	if l.file_pos + l.size > w.data.len {
		return error('lump exceeds file size')
	}
	return w.data[l.file_pos..l.file_pos + l.size].clone()
}

pub fn (mut w Wad) cache_lump_num(index int) ![]u8 {
	if index < 0 || index >= w.num_lumps {
		return error('lump index out of range')
	}
	if cached := w.cache[index] {
		return cached
	}
	data := w.read_lump_num(index)!
	w.cache[index] = data
	return data
}

pub fn (mut w Wad) cache_lump_name(name string) ![]u8 {
	idx := w.find_lump_index(name)
	if idx < 0 {
		return error('lump not found: $name')
	}
	return w.cache_lump_num(idx)
}

pub fn (mut w Wad) release_lump_num(index int) {
	if index < 0 || index >= w.num_lumps {
		return
	}
	w.cache.delete(index)
}

pub fn (mut w Wad) release_lump_name(name string) {
	idx := w.find_lump_index(name)
	if idx < 0 {
		return
	}
	w.release_lump_num(idx)
}

pub fn (w Wad) wad_name_for_lump(index int) !string {
	if index < 0 || index >= w.num_lumps {
		return error('lump index out of range')
	}
	return os.base(w.path)
}

pub fn (w Wad) is_iwad_lump(index int) !bool {
	if index < 0 || index >= w.num_lumps {
		return error('lump index out of range')
	}
	return w.kind == 'IWAD'
}

pub fn (mut w Wad) build_hash_table() {
	if w.num_lumps == 0 {
		w.has_hash = false
		w.lumphash = []int{}
		return
	}
	w.lumphash = []int{len: w.num_lumps, init: -1}
	for i in 0 .. w.num_lumps {
		hash := int(lump_name_hash(w.lumps[i].name) % u32(w.num_lumps))
		w.lumps[i].next = w.lumphash[hash]
		w.lumphash[hash] = i
	}
	w.has_hash = true
}

pub struct HashStats {
pub:
	buckets    int
	used       int
	max_chain  int
	collisions int
	avg_chain  f32
}

pub fn (w Wad) hash_stats() !HashStats {
	if !w.has_hash || w.lumphash.len != w.num_lumps {
		return error('hash table not built')
	}
	mut used := 0
	mut max_chain := 0
	mut collisions := 0
	mut total_chain := 0
	for i in 0 .. w.lumphash.len {
		mut count := 0
		mut idx := w.lumphash[i]
		for idx != -1 {
			count++
			idx = w.lumps[idx].next
		}
		if count > 0 {
			used++
			total_chain += count
			if count > max_chain {
				max_chain = count
			}
			if count > 1 {
				collisions += count - 1
			}
		}
	}
	avg := if used > 0 { f32(total_chain) / f32(used) } else { f32(0) }
	return HashStats{
		buckets: w.lumphash.len
		used: used
		max_chain: max_chain
		collisions: collisions
		avg_chain: avg
	}
}

fn lump_name_hash(name string) u32 {
	mut result := u32(5381)
	mut i := 0
	for i < 8 && i < name.len {
		mut c := name[i]
		if c >= `a` && c <= `z` {
			c = c - 32
		}
		result = ((result << 5) ^ result) ^ u32(c)
		i++
	}
	return result
}

fn lump_name_eq(a string, b string) bool {
	if a.len == 0 || b.len == 0 {
		return false
	}
	if a.len > 8 || b.len > 8 {
		return false
	}
	if a.len != b.len {
		return false
	}
	mut i := 0
	for i < a.len {
		mut ca := a[i]
		mut cb := b[i]
		if ca >= `a` && ca <= `z` {
			ca = ca - 32
		}
		if cb >= `a` && cb <= `z` {
			cb = cb - 32
		}
		if ca != cb {
			return false
		}
		i++
	}
	return true
}

fn read_i32_le(data []u8, offset int) !int {
	if offset + 4 > data.len {
		return error('unexpected end of file')
	}
	return int(u32(data[offset]) | (u32(data[offset + 1]) << 8) | (u32(data[offset + 2]) << 16) | (u32(data[offset + 3]) << 24))
}

fn read_name(data []u8, offset int) !string {
	if offset + 8 > data.len {
		return error('unexpected end of file')
	}
	mut end := 0
	for end < 8 && data[offset + end] != 0 {
		end++
	}
	return data[offset..offset + end].bytestr()
}
