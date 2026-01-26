@[translated]
module main

fn C.I_GetTimeMS() int
fn C.I_GetTime() int
fn C.I_Sleep(int)
fn C.I_WaitVBL()
fn C.I_InitTimer()

const game_tic_rate = 35

fn i_get_time_ms() int {
	return C.I_GetTimeMS()
}

fn i_get_time() int {
	return C.I_GetTime()
}

fn i_sleep(ms int) {
	C.I_Sleep(ms)
}

fn i_wait_vbl() {
	C.I_WaitVBL()
}

fn i_init_timer() {
	C.I_InitTimer()
}
