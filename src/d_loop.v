@[translated]
module main

fn C.D_StartGameLoop()
fn C.D_QuitNetGame()
fn C.TryRunTics()
fn C.NetUpdate()

fn d_start_game_loop() { C.D_StartGameLoop() }
fn d_quit_net_game() { C.D_QuitNetGame() }
fn try_run_tics() { C.TryRunTics() }
fn net_update() { C.NetUpdate() }
