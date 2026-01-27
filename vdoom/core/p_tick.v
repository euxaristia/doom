@[has_globals]
module core

// Carries out all thinking of monsters and players.
pub fn p_ticker() {
	// Ensure the thinker list is initialized before first use.
	if voidptr(thinkercap.next) == unsafe { nil } {
		p_init_thinkers()
	}
	if paused {
		return
	}
	// Pause when menu is active in single-player after at least one tic.
	if !netgame && menuactive && !demoplayback && consoleplayer >= 0 && consoleplayer < players.len {
		if players[consoleplayer].viewz != Fixed(1) {
			return
		}
	}
	for i in 0 .. maxplayers {
		if i < playeringame.len && playeringame[i] {
			p_player_think(&players[i])
		}
	}
	p_run_thinkers()
	p_update_specials()
	p_respawn_specials()
	leveltime++
}
