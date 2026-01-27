@[has_globals]
module core

import time

pub const ticrate = 35

__global basetime_ns = u64(0)

pub fn i_get_time() int {
	now := time.sys_mono_now()
	if basetime_ns == 0 {
		basetime_ns = now
	}
	delta_ms := (now - basetime_ns) / 1_000_000
	return int((delta_ms * u64(ticrate)) / 1000)
}

pub fn i_get_time_ms() int {
	now := time.sys_mono_now()
	if basetime_ns == 0 {
		basetime_ns = now
	}
	delta_ms := (now - basetime_ns) / 1_000_000
	return int(delta_ms)
}

pub fn i_sleep(ms int) {
	if ms <= 0 {
		return
	}
	time.sleep(ms * time.millisecond)
}

pub fn i_wait_vbl(count int) {
	i_sleep((count * 1000) / 70)
}

pub fn i_init_timer() {
}
