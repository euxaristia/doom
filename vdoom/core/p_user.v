module core

pub fn p_move_player(player &Player) {
	// Translate input into a simple bobbing value even before full physics exists.
	forward := int(player.cmd.forwardmove)
	side := int(player.cmd.sidemove)
	unsafe {
		player.bob = Fixed((abs(Fixed(forward)) + abs(Fixed(side))) << frac_bits)
		if player.viewheight == 0 {
			player.viewheight = viewheight_fixed
		}
	}
}

pub fn p_calc_height(player &Player) {
	// Keep view height and view z coherent without a full mobj implementation.
	unsafe {
		if player.viewheight == 0 {
			player.viewheight = viewheight_fixed
		}
		player.deltaviewheight = 0
		player.viewz = player.viewheight + (player.bob >> 3)
	}
}
