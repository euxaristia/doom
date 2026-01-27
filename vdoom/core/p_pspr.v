module core

pub const ff_fullbright = 0x8000
pub const ff_framemask = 0x7fff

@[_allow_multiple_values]
pub enum PsprNum {
	weapon
	flash
	numpsprites
}

pub const numpsprites = 2

pub struct PspDef {
pub mut:
	state voidptr
	tics  int
	sx    Fixed
	sy    Fixed
}

pub fn p_pspr_init() {
	if consoleplayer < 0 || consoleplayer >= players.len {
		return
	}
	// Reset weapon sprites for the console player.
	for i in 0 .. players[consoleplayer].psprites.len {
		players[consoleplayer].psprites[i].tics = 0
		players[consoleplayer].psprites[i].sx = 0
		players[consoleplayer].psprites[i].sy = 0
	}
}

pub fn p_pspr_ticker(player &Player) {
	// Basic animation countdown to keep state moving.
	for i in 0 .. player.psprites.len {
		if player.psprites[i].tics > 0 {
			unsafe {
				player.psprites[i].tics--
			}
		}
	}
}
