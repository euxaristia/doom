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
//     Main loop code.
//

// Forward declarations for external types
type TiccmdT = C.ticcmd_t
type FixedT = i32
type WadFile = C.wad_file_t
type NetGamesettingsT = C.net_gamesettings_t
type NetConnectDataT = C.net_connect_data_t

// Type aliases
type NetgameStartupCallbackT = fn(int, int) bool

// External global for fixed.h
const fracunit = u32(65536)
const fracbits = u32(16)

// Callback function invoked while waiting for the netgame to start.
// The callback is invoked when new players are ready. The callback
// should return true, or return false to abort startup.

// Interface for loop callbacks
struct LoopInterface {
	// Read events from the event queue, and process them.
	process_events fn()

	// Given the current input state, fill in the fields of the specified
	// ticcmd_t structure with data for a new tic.
	build_ticcmd fn(&TiccmdT, int)

	// Advance the game forward one tic, using the specified player input.
	run_tic fn([]TiccmdT, []bool)

	// Run the menu (runs independently of the game).
	run_menu fn()
}

// Maximum time that we wait in TryRunTics() for netgame data to be
// received before we bail out and render a frame anyway.
// Vanilla Doom used 20 for this value, but we use a smaller value
// instead for better responsiveness of the menu when we're stuck.
const max_netgame_stall_tics = 5

// The complete set of data for a particular tic.
struct TiccmdSet {
	cmds []TiccmdT
	ingame []bool
}

// External constants from d_ticcmd.h
const backuptics = 128
const net_maxplayers = 4

// gametic is the tic about to (or currently being) run
// maketic is the tic that hasn't had control made for it yet
// recvtic is the latest tic received from the server.
//
// a gametic cannot be run until ticcmds are received for it
// from all players.

mut ticdata []TiccmdSet = []

// The index of the next tic to be made (with a call to BuildTiccmd).
mut maketic = 0

// The number of complete tics received from the server so far.
mut recvtic = 0

// The number of tics that have been run (using RunTic) so far.
pub mut gametic = 0

// When set to true, a single tic is run each time TryRunTics() is called.
// This is used for -timedemo mode.
pub mut singletics = false

// Index of the local player.
mut localplayer = 0

// Used for original sync code.
mut skiptics = 0

// Reduce the bandwidth needed by sampling game input less and transmitting
// less. If ticdup is 2, sample half normal, 3 = one third normal, etc.
pub mut ticdup = 1

// Amount to offset the timer for game sync.
mut offsetms FixedT = 0

// Use new client synchronisation code
mut new_sync = true

// Callback functions for loop code.
mut loop_interface &LoopInterface = nil

// Current players in the multiplayer game.
// This is distinct from playeringame[] used by the game code, which may
// modify playeringame[] when playing back multiplayer demos.
mut local_playeringame [net_maxplayers]bool

// Requested player class "sent" to the server on connect.
// If we are only doing a single player game then this needs to be remembered
// and saved in the game settings.
mut player_class = 0

// Last time value for network updates
mut lasttime = 0

// For original sync code
mut frameon = 0
mut frameskip = [4]int{}
mut oldnettics = 0

// External functions
@[extern]
fn extern_i_get_time_ms() int
@[extern]
fn extern_i_get_time() int
@[extern]
fn extern_i_start_tic()
@[extern]
fn extern_i_sleep(ms int)
@[extern]
fn extern_i_error(msg &char, args ...voidptr)
@[extern]
fn extern_i_at_exit(func fn(), run_on_error bool)
@[extern]
fn extern_m_parm_exists(parm &char) bool
@[extern]
fn extern_m_check_parm(parm &char) int
@[extern]
fn extern_m_check_parm_with_args(parm &char, nargs int) int
@[extern]
fn extern_m_argv(idx int) &char
@[extern]
fn extern_net_cl_run()
@[extern]
fn extern_net_sv_run()
@[extern]
fn extern_net_cl_send_ticcmd(cmd &TiccmdT, tic int)
@[extern]
fn extern_net_cl_connected() bool
@[extern]
fn extern_net_cl_get_settings(settings &NetGamesettingsT) bool
@[extern]
fn extern_net_cl_start_game(settings &NetGamesettingsT)
@[extern]
fn extern_net_cl_connect(addr &C.net_addr_t, connect_data &NetConnectDataT) bool
@[extern]
fn extern_net_cl_disconnect()
@[extern]
fn extern_net_sv_init()
@[extern]
fn extern_net_sv_shutdown()
@[extern]
fn extern_net_sv_add_module(module &C.net_module_t)
@[extern]
fn extern_net_sv_register_with_master()
@[extern]
fn extern_net_find_lan_server() &C.net_addr_t
@[extern]
fn extern_net_reference_address(addr &C.net_addr_t)
@[extern]
fn extern_net_release_address(addr &C.net_addr_t)
@[extern]
fn extern_net_addr_to_string(addr &C.net_addr_t) &char
@[extern]
fn extern_net_wait_for_launch()

@[extern]
fn extern_net_client_wait_data_ready_players() int
@[extern]
fn extern_net_client_wait_data_num_players() int

// External global: net_client_connected (wrapped function)
fn net_client_connected() bool {
	return extern_net_cl_connected()
}

// External global: drone (from d_main.c, wrapped)
@[extern]
fn extern_drone() bool

fn drone() bool {
	return extern_drone()
}

// 35 fps clock adjusted by offsetms milliseconds
fn get_adjusted_time() int {
	mut time_ms int

	time_ms = extern_i_get_time_ms()

	if new_sync {
		// Use the adjustments from net_client.c only if we are
		// using the new sync mode.

		time_ms += int(offsetms / FixedT(fracunit))
	}

	return (time_ms * 35) / 1000
}

// Build a new tic command
fn build_new_tic() bool {
	mut gameticdiv int
	mut cmd TiccmdT

	gameticdiv = gametic / ticdup

	extern_i_start_tic()
	loop_interface.process_events()

	// Always run the menu

	loop_interface.run_menu()

	if drone() {
		// In drone mode, do not generate any ticcmds.

		return false
	}

	if new_sync {
		// If playing single player, do not allow tics to buffer
		// up very far

		if !net_client_connected() && maketic - gameticdiv > 2 {
			return false
		}

		// Never go more than ~200ms ahead

		if maketic - gameticdiv > 8 {
			return false
		}
	} else {
		if maketic - gameticdiv >= 5 {
			return false
		}
	}

	// Clear the command
	C.memset(&cmd, 0, sizeof(TiccmdT))
	loop_interface.build_ticcmd(&cmd, maketic)

	if net_client_connected() {
		extern_net_cl_send_ticcmd(&cmd, maketic)
	}

	ticdata[maketic % backuptics].cmds[localplayer] = cmd
	ticdata[maketic % backuptics].ingame[localplayer] = true

	maketic++

	return true
}

// NetUpdate
// Builds ticcmds for console player,
// sends out a packet
pub fn net_update() {
	mut nowtime int
	mut newtics int
	mut i int

	// If we are running with singletics (timing a demo), this
	// is all done separately.

	if singletics {
		return
	}

	// Run network subsystems

	extern_net_cl_run()
	extern_net_sv_run()

	// check time
	nowtime = get_adjusted_time() / ticdup
	newtics = nowtime - lasttime

	lasttime = nowtime

	if skiptics <= newtics {
		newtics -= skiptics
		skiptics = 0
	} else {
		skiptics -= newtics
		newtics = 0
	}

	// build new ticcmds for console player

	for i = 0; i < newtics; i++ {
		if !build_new_tic() {
			break
		}
	}
}

// Called when disconnected from server
fn d_disconnected() {
	// In drone mode, the game cannot continue once disconnected.

	if drone() {
		extern_i_error("Disconnected from server in drone mode.")
	}

	// disconnected from server

	println("Disconnected from server.")
}

// Invoked by the network engine when a complete set of ticcmds is
// available.
pub fn d_receive_tic(ticcmds []TiccmdT, players_mask []bool) {
	mut i int

	// Disconnected from server?

	if ticcmds.len == 0 && players_mask.len == 0 {
		d_disconnected()
		return
	}

	for i = 0; i < net_maxplayers; i++ {
		if !drone() && i == localplayer {
			// This is us. Don't overwrite it.
		} else {
			ticdata[recvtic % backuptics].cmds[i] = ticcmds[i]
			ticdata[recvtic % backuptics].ingame[i] = players_mask[i]
		}
	}

	recvtic++
}

// Start game loop
// Called after the screen is set but before the game starts running.
pub fn d_start_game_loop() {
	lasttime = get_adjusted_time() / ticdup
}

// Block until the game start message is received from the server.
fn block_until_start(settings &NetGamesettingsT, callback NetgameStartupCallbackT) {
	mut ready_players int
	mut num_players int

	for !extern_net_cl_get_settings(settings) {
		extern_net_cl_run()
		extern_net_sv_run()

		if !net_client_connected() {
			extern_i_error("Lost connection to server")
		}

		ready_players = extern_net_client_wait_data_ready_players()
		num_players = extern_net_client_wait_data_num_players()

		if callback != nil && !callback(ready_players, num_players) {
			extern_i_error("Netgame startup aborted.")
		}

		extern_i_sleep(100)
	}
}

// Start a network game
pub fn d_start_net_game(settings &NetGamesettingsT, callback NetgameStartupCallbackT) {
	mut i int

	offsetms = 0
	recvtic = 0

	settings.consoleplayer = 0
	settings.num_players = 1
	settings.player_classes[0] = player_class

	// Use original network client sync code rather than the improved
	// sync code.
	settings.new_sync = !extern_m_parm_exists("-oldsync")

	// Send n extra tics in every packet as insurance against dropped packets.
	i = extern_m_check_parm_with_args("-extratics", 1)

	if i > 0 {
		settings.extratics = C.atoi(extern_m_argv(i + 1))
	} else {
		settings.extratics = 1
	}

	// Reduce the resolution of the game by a factor of n, reducing
	// the amount of network bandwidth needed.
	i = extern_m_check_parm_with_args("-dup", 1)

	if i > 0 {
		settings.ticdup = C.atoi(extern_m_argv(i + 1))
	} else {
		settings.ticdup = 1
	}

	if net_client_connected() {
		// Send our game settings and block until game start is received
		// from the server.

		extern_net_cl_start_game(settings)
		block_until_start(settings, callback)

		// Read the game settings that were received.

		extern_net_cl_get_settings(settings)
	}

	if drone() {
		settings.consoleplayer = 0
	}

	// Set the local player and playeringame[] values.

	localplayer = settings.consoleplayer

	for i = 0; i < net_maxplayers; i++ {
		local_playeringame[i] = i < settings.num_players
	}

	// Copy settings to global variables.

	ticdup = settings.ticdup
	new_sync = settings.new_sync
}

// Initialize networking code and connect to server.
pub fn d_init_net_game(connect_data &NetConnectDataT) bool {
	mut result = false
	mut addr &C.net_addr_t = nil
	mut i int

	// Call D_QuitNetGame on exit:

	extern_i_at_exit(d_quit_net_game, true)

	player_class = connect_data.player_class

	// Start a multiplayer server, listening for connections.

	if extern_m_check_parm("-server") > 0 || extern_m_check_parm("-privateserver") > 0 {
		extern_net_sv_init()
		// extern_net_sv_add_module(&net_loop_server_module)
		// extern_net_sv_add_module(&net_sdl_module)
		extern_net_sv_register_with_master()

		// net_loop_client_module.InitClient()
		// addr = net_loop_client_module.ResolveAddress(nil)
		// extern_net_reference_address(addr)
	} else {
		// Automatically search the local LAN for a multiplayer
		// server and join it.

		i = extern_m_check_parm("-autojoin")

		if i > 0 {
			addr = extern_net_find_lan_server()

			if addr == nil {
				extern_i_error("No server found on local LAN")
			}
		}

		// Connect to a multiplayer server running on the given address.

		i = extern_m_check_parm_with_args("-connect", 1)

		if i > 0 {
			// net_sdl_module.InitClient()
			// addr = net_sdl_module.ResolveAddress(extern_m_argv(i+1))
			// extern_net_reference_address(addr)

			// if addr == nil {
			//     extern_i_error("Unable to resolve '%s'\\n", extern_m_argv(i+1))
			// }
		}
	}

	if addr != nil {
		if extern_m_check_parm("-drone") > 0 {
			connect_data.drone = true
		}

		if !extern_net_cl_connect(addr, connect_data) {
			extern_i_error("D_InitNetGame: Failed to connect to %s:\n%s\n",
				extern_net_addr_to_string(addr))
		}

		println("D_InitNetGame: Connected to %s" , extern_net_addr_to_string(addr))
		extern_net_release_address(addr)

		// Wait for launch message received from server.

		extern_net_wait_for_launch()

		result = true
	}

	return result
}

// D_QuitNetGame
// Called before quitting to leave a net game
// without hanging the other players
pub fn d_quit_net_game() {
	extern_net_sv_shutdown()
	extern_net_cl_disconnect()
}

// Get the lowest tic number available
fn get_low_tic() int {
	mut lowtic int

	lowtic = maketic

	if net_client_connected() {
		if drone() || recvtic < lowtic {
			lowtic = recvtic
		}
	}

	return lowtic
}

// Old network synchronization code
fn old_net_sync() {
	mut i u32
	mut keyplayer = -1

	frameon++

	// ideally maketic should be 1 - 3 tics above lowtic
	// if we are consistently slower, speed up time

	for i = 0; i < u32(net_maxplayers); i++ {
		if local_playeringame[i] {
			keyplayer = int(i)
			break
		}
	}

	if keyplayer < 0 {
		// If there are no players, we can never advance anyway

		return
	}

	if localplayer == keyplayer {
		// the key player does not adapt
	} else {
		if maketic <= recvtic {
			lasttime--
			// printf ("-");
		}

		frameskip[frameon & 3] = if oldnettics > recvtic { 1 } else { 0 }
		oldnettics = maketic

		if frameskip[0] != 0 && frameskip[1] != 0 && frameskip[2] != 0 && frameskip[3] != 0 {
			skiptics = 1
			// printf ("+");
		}
	}
}

// Returns true if there are players in the game:
fn players_in_game() bool {
	mut result = false
	mut i u32

	// If we are connected to a server, check if there are any players
	// in the game.

	if net_client_connected() {
		for i = 0; i < u32(net_maxplayers); i++ {
			result = result || local_playeringame[i]
		}
	}

	// Whether single or multi-player, unless we are running as a drone,
	// we are in the game.

	if !drone() {
		result = true
	}

	return result
}

// When using ticdup, certain values must be cleared out when running
// the duplicate ticcmds.
fn ticdup_squash(set &TiccmdSet) {
	mut cmd &TiccmdT
	mut i u32

	for i = 0; i < u32(net_maxplayers); i++ {
		cmd = &set.cmds[i]
		cmd.chatchar = 0
		if cmd.buttons & 0x80 != 0 {
			cmd.buttons = 0
		}
	}
}

// When running in single player mode, clear all the ingame[] array
// except the local player.
fn single_player_clear(set &TiccmdSet) {
	mut i u32

	for i = 0; i < u32(net_maxplayers); i++ {
		if int(i) != localplayer {
			set.ingame[i] = false
		}
	}
}

// TryRunTics
pub fn try_run_tics() {
	mut i int
	mut lowtic int
	mut entertic int
	mut oldentertics = 0
	mut realtics int
	mut availabletics int
	mut counts int
	mut set &TiccmdSet

	// get real tics
	entertic = extern_i_get_time() / ticdup
	realtics = entertic - oldentertics
	oldentertics = entertic

	// in singletics mode, run a single tic every time this function
	// is called.

	if singletics {
		build_new_tic()
	} else {
		net_update()
	}

	lowtic = get_low_tic()

	availabletics = lowtic - gametic / ticdup

	// decide how many tics to run

	if new_sync {
		counts = availabletics
	} else {
		// decide how many tics to run
		if realtics < availabletics - 1 {
			counts = realtics + 1
		} else if realtics < availabletics {
			counts = realtics
		} else {
			counts = availabletics
		}

		if counts < 1 {
			counts = 1
		}

		if net_client_connected() {
			old_net_sync()
		}
	}

	if counts < 1 {
		counts = 1
	}

	// wait for new tics if needed
	for !players_in_game() || lowtic < gametic / ticdup + counts {
		net_update()

		lowtic = get_low_tic()

		if lowtic < gametic / ticdup {
			extern_i_error("TryRunTics: lowtic < gametic")
		}

		// Still no tics to run? Sleep until some are available.
		if lowtic < gametic / ticdup + counts {
			// If we're in a netgame, we might spin forever waiting for
			// new network data to be received. So don't stay in here
			// forever - give the menu a chance to work.
			if extern_i_get_time() / ticdup - entertic >= max_netgame_stall_tics {
				return
			}

			extern_i_sleep(1)
		}
	}

	// run the count * ticdup tics
	for counts > 0 {
		if !players_in_game() {
			return
		}

		set = &ticdata[(gametic / ticdup) % backuptics]

		if !net_client_connected() {
			single_player_clear(set)
		}

		for i = 0; i < ticdup; i++ {
			if gametic / ticdup > lowtic {
				extern_i_error("gametic>lowtic")
			}

			C.memcpy(unsafe { &local_playeringame[0] }, unsafe { &set.ingame[0] },
				net_maxplayers * sizeof(bool))

			loop_interface.run_tic(set.cmds, set.ingame)
			gametic++

			// modify command for duplicated tics

			ticdup_squash(set)
		}

		net_update() // check for new console commands

		counts--
	}
}

// Register callback functions for the main loop code to use.
pub fn d_register_loop_callbacks(i &LoopInterface) {
	loop_interface = i
}

// TODO: Move nonvanilla demo functions into a dedicated file.

// Check if strict demos mode is enabled
fn strict_demos() bool {
	// When recording or playing back demos, disable any extensions
	// of the vanilla demo format - record demos as vanilla would do,
	// and play back demos as vanilla would do.
	return extern_m_parm_exists("-strictdemos")
}

// If the provided conditional value is true, we're trying to record
// a demo file that will include a non-vanilla extension. The function
// will return true if the conditional is true and it's allowed to use
// this extension (no extensions are allowed if -strictdemos is given
// on the command line). A warning is shown on the console using the
// provided string describing the non-vanilla expansion.
pub fn d_non_vanilla_record(conditional bool, feature &char) bool {
	if !conditional || strict_demos() {
		return false
	}

	println("Warning: Recording a demo file with a non-vanilla extension ($feature). Use -strictdemos to disable this extension.")

	return true
}

// Returns true if the given lump number corresponds to data from a .lmp
// file, as opposed to a WAD.
fn is_demo_file(lumpnum int) bool {
	// TODO: Implement with proper lumpinfo access
	// For now, return false
	return false
}

// If the provided conditional value is true, we're trying to play back
// a demo that includes a non-vanilla extension. We return true if the
// conditional is true and it's allowed to use this extension, checking
// that:
//  - The -strictdemos command line argument is not provided.
//  - The given lumpnum identifying the demo to play back identifies a
//    demo that comes from a .lmp file, not a .wad file.
//  - Before proceeding, a warning is shown to the user on the console.
pub fn d_non_vanilla_playback(conditional bool, lumpnum int, feature &char) bool {
	if !conditional || strict_demos() {
		return false
	}

	if !is_demo_file(lumpnum) {
		println("Warning: WAD contains demo with a non-vanilla extension ($feature)")
		return false
	}

	println("Warning: Playing back a demo file with a non-vanilla extension ($feature). Use -strictdemos to disable this extension.")

	return true
}

// Initialize ticdata array on startup
fn init_ticdata() {
	mut i int

	ticdata = []TiccmdSet{len: backuptics}

	for i = 0; i < backuptics; i++ {
		ticdata[i].cmds = []TiccmdT{len: net_maxplayers}
		ticdata[i].ingame = []bool{len: net_maxplayers}
	}
}

// Module initialization
pub fn init() {
	init_ticdata()
}
