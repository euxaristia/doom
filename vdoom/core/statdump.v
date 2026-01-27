@[has_globals]
module core

__global last_stats = WbStartStruct{}

pub fn stat_copy(stats &WbStartStruct) {
	last_stats = *stats
}

pub fn stat_dump() {
	// Minimal visibility for debugging without full statdump output.
	println('statdump: eps=${last_stats.epsd} last=${last_stats.last}')
}
