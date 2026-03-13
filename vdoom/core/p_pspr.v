module core

pub const ff_fullbright = 0x8000
pub const ff_framemask = 0x7fff

@[_allow_multiple_values]
pub enum PsprNum {
	weapon
	flash
	numpsprites
}

pub struct PspDef {
pub mut:
	state voidptr
	tics  int
	sx    Fixed
	sy    Fixed
	sx2   Fixed
	sy2   Fixed
}

pub fn p_pspr_init() {
	if consoleplayer < 0 || consoleplayer >= players.len {
		return
	}
	for i in 0 .. players[consoleplayer].psprites.len {
		players[consoleplayer].psprites[i].tics = 0
		players[consoleplayer].psprites[i].sx = 0
		players[consoleplayer].psprites[i].sy = 0
	}
}

pub fn p_pspr_ticker(player &Player) {
	for i in 0 .. player.psprites.len {
		if player.psprites[i].tics > 0 {
			unsafe {
				player.psprites[i].tics--
			}
		}
	}
}

pub fn p_setup_psprites(player &Player) {
	unsafe {
		for i in 0 .. player.psprites.len {
			player.psprites[i].state = voidptr(0)
			player.psprites[i].tics = 0
			player.psprites[i].sx2 = 0
			player.psprites[i].sy2 = 0
		}
	}
}

pub fn p_move_psprites(player &Player) {
	unsafe {
		for i in 0 .. player.psprites.len {
			psp := &player.psprites[i]
			if psp.state == voidptr(0) {
				continue
			}
			if psp.tics > 0 {
				psp.tics--
			}
			for psp.tics == 0 {
				// Get next state - placeholder
				psp.tics = 0
				break
			}
		}
	}
}

pub fn p_drop_weapon(player &Player) {
	_ = player
}

pub fn p_set_psprite(player &Player, position PsprNum, state voidptr) {
	unsafe {
		player.psprites[int(position)].state = state
		player.psprites[int(position)].tics = 0
	}
}

pub fn p_clear_psprites(player &Player) {
	unsafe {
		for i in 0 .. player.psprites.len {
			player.psprites[i].state = voidptr(0)
			player.psprites[i].tics = 0
		}
	}
}
