@[has_globals]
module core

__global dedicated_mode = false

pub fn d_dedicated_init() {
	dedicated_mode = true
}

pub fn d_dedicated_shutdown() {
	dedicated_mode = false
}

