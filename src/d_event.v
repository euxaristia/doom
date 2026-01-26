@[translated]
module main

//
// Copyright(C) 1993-1996 Id Software, Inc.
// Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//     Event handling.
//

// Input event types.
enum EvType {
	// Key press/release events.
	// data1: Key code (from doomkeys.h) of the key that was pressed or released.
	// For ev_keydown only:
	// data2: ASCII representation of the key that was pressed
	// data3: ASCII input, fully modified according to keyboard layout and modifiers
	ev_keydown = 0
	ev_keyup = 1

	// Mouse movement event.
	// data1: Bitfield of buttons currently held down (bit 0 = left; bit 1 = right; bit 2 = middle).
	// data2: X axis mouse movement (turn).
	// data3: Y axis mouse movement (forward/backward).
	ev_mouse = 2

	// Joystick state.
	// data1: Bitfield of buttons currently pressed.
	// data2: X axis mouse movement (turn).
	// data3: Y axis mouse movement (forward/backward).
	// data4: Third axis mouse movement (strafe).
	// data5: Fourth axis mouse movement (look)
	ev_joystick = 3

	// Quit event. Triggered when the user clicks the "close" button to terminate the application.
	ev_quit = 4
}

// Event structure.
struct Event {
	typ EvType
	// Event-specific data; see the descriptions given above.
	data1 int
	data2 int
	data3 int
	data4 int
	data5 int
}

// Button/action code definitions.
enum ButtonCode {
	// Press "Fire".
	bt_attack = 1
	// Use button, to open doors, activate switches.
	bt_use = 2

	// Flag: game events, not really buttons.
	bt_special = 128
	bt_special_mask = 3

	// Flag, weapon change pending.
	bt_change = 4
	// The 3bit weapon mask and shift, convenience.
	bt_weapon_mask = 8 + 16 + 32
	bt_weapon_shift = 3

	// Pause the game.
	bts_pause = 1
	// Save the game at each console.
	bts_savegame = 2

	// Savegame slot numbers occupy the second byte of buttons.
	bts_save_mask = 4 + 8 + 16
	bts_save_shift = 2
}

// Strife specific buttons
enum ButtonCode2 {
	// Player view look up
	bt2_lookup = 1
	// Player view look down
	bt2_lookdown = 2
	// Center player's view
	bt2_centerview = 4
	// Use inventory item
	bt2_invuse = 8
	// Drop inventory item
	bt2_invdrop = 16
	// Jump up and down
	bt2_jump = 32
	// Use medkit
	bt2_health = 128
}

const maxevents = 64

// Event queue
mut events [maxevents]Event
mut eventhead int = 0
mut eventtail int = 0

// D_PostEvent
// Called by the I/O functions when input is detected
fn d_post_event(ev &Event) {
	events[eventhead] = *ev
	eventhead = (eventhead + 1) % maxevents
}

// D_PopEvent
// Read an event from the queue.
fn d_pop_event() &Event {
	mut result &Event

	// No more events waiting.
	if eventtail == eventhead {
		return unsafe { nil }
	}

	result = &events[eventtail]

	// Advance to the next event in the queue.
	eventtail = (eventtail + 1) % maxevents

	return result
}
