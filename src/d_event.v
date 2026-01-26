@[translated]
module main

enum EvType {
	ev_keydown = 0
	ev_keyup = 1
	ev_mouse = 2
	ev_joystick = 3
	ev_quit = 4
}

struct Event {
	ev_type EvType
	data1 int
	data2 int
	data3 int
	data4 int
	data5 int
}

fn C.D_PostEvent(&Event) bool
fn C.D_GetEvent(&Event) bool
fn C.D_EventInit()

fn d_post_event(ev &Event) bool { return C.D_PostEvent(ev) }
fn d_get_event(ev &Event) bool { return C.D_GetEvent(ev) }
fn d_event_init() { C.D_EventInit() }
