@[translated]
module main

import math.sdl2

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
//      System-specific timer interface
//

const ticrate = 35

// Base time for relative timing calculations
mut basetime u32 = 0

// I_GetTime
// Returns time in 1/35th second tics
fn i_get_time() int {
	mut ticks u32 = sdl2.get_ticks()

	if basetime == 0 {
		basetime = ticks
	}

	ticks -= basetime

	return int((ticks * u32(ticrate)) / 1000)
}

// I_GetTimeMS
// Same as I_GetTime, but returns time in milliseconds
fn i_get_time_ms() int {
	mut ticks u32 = sdl2.get_ticks()

	if basetime == 0 {
		basetime = ticks
	}

	return int(ticks - basetime)
}

// I_Sleep
// Sleep for a specified number of ms
fn i_sleep(ms int) {
	sdl2.delay(u32(ms))
}

// I_WaitVBL
// Wait for vertical retrace
fn i_wait_vbl(count int) {
	i_sleep((count * 1000) / 70)
}

// I_InitTimer
// Initialize timer
fn i_init_timer() {
	// initialize timer
	$if sdl_version_atleast(2, 0, 5) {
		sdl2.set_hint(c"SDL_WINDOWS_DISABLE_THREAD_NAMING", c"1")
	}
}
