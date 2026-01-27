@[has_globals]
module core

__global gameaction = GameAction.nothing
__global advancedemo = false
__global storedemo = false
__global main_loop_started = false
__global show_endoom = 1
__global show_diskicon = 1
__global wadfile = ''
__global mapdir = ''
__global iwadfile_local = ''

pub fn d_process_events() {
	if storedemo {
		return
	}
	for {
		ev := d_pop_event() or { break }
		if m_responder(&ev) {
			continue
		}
		_ = g_responder(&ev)
	}
}

pub fn d_page_ticker() {
}

pub fn d_page_drawer() {
}

pub fn d_advance_demo() {
}

pub fn d_do_advance_demo() {
}

pub fn d_start_title() {
}

pub fn d_display() bool {
	// Rendering is not wired up yet; report "no wipe" by default.
	return false
}

pub fn d_connect_net_game() {
}

pub fn d_check_net_game() {
}

pub fn d_doom_loop() {
	main_loop_started = true
	for {
		i_start_frame()
		d_process_events()
		i_start_tic()
		g_ticker()
		d_display()
	}
}
