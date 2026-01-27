@[has_globals]
module core

// Lightweight mapping registry mirroring deh_mapping.c intent.
__global deh_mappings = map[string]map[string]int{}

pub fn deh_mapping_clear() {
	deh_mappings = map[string]map[string]int{}
}

pub fn deh_mapping_set(section string, field string, value int) {
	mut entry := (deh_mappings[section] or { map[string]int{} }).clone()
	entry[field.to_lower()] = value
	deh_mappings[section] = entry.clone()
}

pub fn deh_mapping_get(section string, field string) ?int {
	entry := (deh_mappings[section] or { return none }).clone()
	key := field.to_lower()
	if key in entry {
		return entry[key]
	}
	return none
}
