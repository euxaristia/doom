module core

// Generate a stable checksum of the WAD directory.
pub fn w_checksum(w Wad) u64 {
	mut state := hash_init()
	for i, lump in w.lumps {
		state = hash_update_str(state, lump.name)
		state = hash_update_u32(state, u32(i))
		state = hash_update_u32(state, u32(lump.file_pos))
		state = hash_update_u32(state, u32(lump.size))
	}
	return hash_finish(state)
}
