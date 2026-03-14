module core

pub const ff_fullbright = 0x8000
pub const ff_framemask = 0x7fff

pub const lowerspeed = frac_unit * 6
pub const raisespeed = frac_unit * 6
pub const weaponbottom = 128 * frac_unit
pub const weapontop = 32 * frac_unit

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

__global swingx = Fixed(0)
__global swingy = Fixed(0)

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

pub fn p_calc_swing(player &Player) {
	swing := player.bob
	
	mut angle := (fine_angles / 70 * leveltime) & fine_mask
	swingx = fixed_mul(swing, finesine[angle])
	
	angle = (fine_angles / 70 * leveltime + fine_angles / 2) & fine_mask
	swingy = -fixed_mul(swingx, finesine[angle])
}

pub fn p_move_psprites(player &Player) {
	for i in 0 .. player.psprites.len {
		mut psp := &player.psprites[i]
		if psp.state == voidptr(0) {
			continue
		}
		if psp.tics > 0 {
			psp.tics--
		}
		for psp.tics == 0 {
			st := unsafe { &State(psp.state) }
			if st == voidptr(0) || st.nextstate == StateNum.s_null {
				psp.state = voidptr(0)
				break
			}
			next_st := &states[int(st.nextstate)]
			psp.state = voidptr(next_st)
			psp.tics = next_st.tics
			if next_st.misc1 != 0 {
				psp.sx = Fixed(next_st.misc1 << frac_bits)
				psp.sy = Fixed(next_st.misc2 << frac_bits)
				psp.sx2 = psp.sx
				psp.sy2 = psp.sy
			}
			if next_st.action.acp1 != voidptr(0) {
				next_st.action.acp1(voidptr(player.mo))
			}
			if psp.state == voidptr(0) {
				break
			}
			if psp.tics > 0 {
				break
			}
		}
	}
}

pub fn p_drop_weapon(player &Player) {
	_ = player
}

pub fn p_set_psprite(player &Player, position PsprNum, st StateNum) {
	mut psp := &player.psprites[int(position)]
	
	mut statenum := st
	for int(statenum) != 0 {
		state := &states[int(statenum)]
		if state == voidptr(0) {
			psp.state = voidptr(0)
			break
		}
		psp.state = voidptr(state)
		psp.tics = state.tics
		
		if state.misc1 != 0 {
			psp.sx = Fixed(state.misc1 << frac_bits)
			psp.sy = Fixed(state.misc2 << frac_bits)
		psp.sx2 = psp.sx
		psp.sy2 = psp.sy
	}
	
	if state.action.acp2 != voidptr(0) {
		state.action.acp2(voidptr(player.mo), voidptr(psp))
		if psp.state == voidptr(0) {
			break
		}
	}
	
	statenum = state.nextstate
		if psp.tics > 0 {
			break
		}
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
