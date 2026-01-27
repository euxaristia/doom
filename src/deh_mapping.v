@[translated]
module main

// Dehacked "mapping" code: map fields by name into struct instances.

const max_mapping_entries = 32

struct Deh_mapping_entry_t {
	name      &i8
	location  voidptr
	size      int
	is_string bool
}

struct Deh_mapping_t {
	base    voidptr
	entries [max_mapping_entries]Deh_mapping_entry_t
}

fn cstr(p &i8) string {
	return cstring(p)
}

fn name_eq(a &i8, b &i8) bool {
	return cstr(a).to_lower() == cstr(b).to_lower()
}

fn mapping_entry_offset(mapping &Deh_mapping_t, entry &Deh_mapping_entry_t) usize {
	base := usize(mapping.base)
	loc := usize(entry.location)
	if base == 0 || loc == 0 || loc < base {
		return usize(0)
	}
	return loc - base
}

fn set_int_at(ptr voidptr, size int, value int) {
	unsafe {
		match size {
			1 {
				(&u8(ptr))[0] = u8(value)
			}
			2 {
				(&u16(ptr))[0] = u16(value)
			}
			4 {
				(&u32(ptr))[0] = u32(value)
			}
			else {
				(&int(ptr))[0] = value
			}
		}
	}
}

fn copy_cstring_into(ptr voidptr, size int, value &i8) {
	if size <= 0 {
		return
	}
	// Copy up to size-1 bytes and NUL-terminate.
	mut i := 0
	unsafe {
		for i < size - 1 {
			ch := (&u8(value))[i]
			(&u8(ptr))[i] = ch
			i++
			if ch == 0 {
				return
			}
		}
		(&u8(ptr))[size - 1] = 0
	}
}

@[export: 'DEH_SetMapping']
pub fn deh_set_mapping(context &Deh_context_t, mapping &Deh_mapping_t, structptr voidptr, name &i8, value int) bool {
	_ = context
	for i := 0; i < max_mapping_entries; i++ {
		entry := &mapping.entries[i]
		if entry.name == unsafe { nil } {
			break
		}
		if entry.location == unsafe { nil } || entry.size < 0 {
			continue
		}
		if !name_eq(entry.name, name) {
			continue
		}
		off := mapping_entry_offset(mapping, entry)
		if off == 0 && usize(entry.location) != usize(mapping.base) {
			return false
		}
		target := voidptr(usize(structptr) + off)
		set_int_at(target, entry.size, value)
		return true
	}
	return false
}

@[export: 'DEH_SetStringMapping']
pub fn deh_set_string_mapping(context &Deh_context_t, mapping &Deh_mapping_t, structptr voidptr, name &i8, value &i8) bool {
	_ = context
	for i := 0; i < max_mapping_entries; i++ {
		entry := &mapping.entries[i]
		if entry.name == unsafe { nil } {
			break
		}
		if entry.location == unsafe { nil } || entry.size < 0 || !entry.is_string {
			continue
		}
		if !name_eq(entry.name, name) {
			continue
		}
		off := mapping_entry_offset(mapping, entry)
		if off == 0 && usize(entry.location) != usize(mapping.base) {
			return false
		}
		target := voidptr(usize(structptr) + off)
		copy_cstring_into(target, entry.size, value)
		return true
	}
	return false
}

@[export: 'DEH_StructSHA1Sum']
pub fn deh_struct_sha_1_sum(context &Sha1_context_t, mapping &Deh_mapping_t, structptr voidptr) {
	// Placeholder: checksum support can be fleshed out later.
	_ = context
	_ = mapping
	_ = structptr
}
