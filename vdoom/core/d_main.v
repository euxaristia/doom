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

fn d_run_tic(cmds []TicCmd, ingame []bool) {
	_ = cmds
	_ = ingame
	g_ticker()
}

fn d_main_init() {
	mut iface := LoopInterface{}
	iface.process_events = d_process_events
	iface.run_tic = d_run_tic
	d_register_loop_callbacks(&iface)
}

pub fn boot() {
	doomstat_init()
	d_items_init()
	d_main_init()
	deh_init_system()
	m_init()
	st_init()
	d_net_init()
	aes_prng_seed(u64(i_get_time_ms()))
	d_start_game_loop()
}

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
		net_update()
		i_start_tic()
		try_run_tics()
		d_display()
	}
}
