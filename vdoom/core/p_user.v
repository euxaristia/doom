module core

pub const invsecolormap = 32

__global onground = false
__global playerbobfactor = 0

pub fn p_thrust(player &Player, angle u32, move Fixed) {
	mut angle_shift := angle >> angle_to_fineshift
	unsafe {
		player.mo.momx += fixed_mul(move, finesine[angle_shift])
		player.mo.momy += fixed_mul(move, finecosine[angle_shift])
	}
}

pub fn p_calc_height(player &Player) {
	unsafe {
		player.bob = fixed_mul(player.mo.momx, player.mo.momx) + fixed_mul(player.mo.momy, player.mo.momy)
		player.bob >>= 2
		if player.bob > maxbob {
			player.bob = maxbob
		}

		bobfactor := 3
		player.bob2 = (bobfactor * player.bob) >> 2

		if (player.cheats & int(Cheat.nomomentum)) != 0 || !onground {
			player.viewz = player.mo.z + viewheight_fixed
			if player.viewz > player.mo.ceilingz - 4 * frac_unit {
				player.viewz = player.mo.ceilingz - 4 * frac_unit
			}
			return
		}

		angle := (fine_angles / 20 * leveltime) & fine_mask
		bob := fixed_mul(player.bob2 / 2, finesine[angle])

		if player.playerstate == .live {
			player.viewheight += player.deltaviewheight
			if player.viewheight > viewheight_fixed {
				player.viewheight = viewheight_fixed
				player.deltaviewheight = 0
			}
			if player.viewheight < viewheight_fixed / 2 {
				player.viewheight = viewheight_fixed / 2
				if player.deltaviewheight <= 0 {
					player.deltaviewheight = 1
				}
			}
			if player.deltaviewheight != 0 {
				player.deltaviewheight += frac_unit / 4
				if player.deltaviewheight == 0 {
					player.deltaviewheight = 1
				}
			}
		}
		player.viewz = player.mo.z + player.viewheight + bob
		if player.viewz > player.mo.ceilingz - 4 * frac_unit {
			player.viewz = player.mo.ceilingz - 4 * frac_unit
		}
	}
}

pub fn p_move_player(player &Player) {
	cmd := &player.cmd
	unsafe {
		player.mo.angle += u32(cmd.angleturn) << frac_bits

		onground = (player.mo.z <= player.mo.floorz)
		onground = onground || ((player.mo.flags & mf_noclip) != 0)

		if cmd.forwardmove != 0 && onground {
			p_thrust(player, player.mo.angle, Fixed(cmd.forwardmove) * 2048)
		}
		if cmd.sidemove != 0 && onground {
			p_thrust(player, player.mo.angle - ang90, Fixed(cmd.sidemove) * 2048)
		}
	}
}

pub fn p_death_think(player &Player) {
	p_move_psprites(player)

	unsafe {
		if player.viewheight > 6 * frac_unit {
			player.viewheight -= frac_unit
		}
		if player.viewheight < 6 * frac_unit {
			player.viewheight = 6 * frac_unit
		}
		player.deltaviewheight = 0
		onground = (player.mo.z <= player.mo.floorz)
	}
	p_calc_height(player)
}

fn cmd_buttons(cmd TicCmd) int {
	return int(cmd.buttons)
}

pub fn p_player_think(player &Player) {
	unsafe {
		player.mo.interp = 1
		player.mo.oldx = player.mo.x
		player.mo.oldy = player.mo.y
		player.mo.oldz = player.mo.z
		player.mo.oldangle = player.mo.angle
		player.oldviewz = player.viewz
		player.oldlookdir = player.lookdir
		player.oldrecoilpitch = player.recoilpitch
	}

	if player.cheats & int(Cheat.noclip) != 0 {
		unsafe {
			player.mo.flags |= mf_noclip
		}
	} else {
		unsafe {
			player.mo.flags &= ~mf_noclip
		}
	}

	cmd := &player.cmd
	unsafe {
		if player.mo.flags & mf_justattacked != 0 {
			cmd.angleturn = 0
			cmd.forwardmove = 12
			cmd.sidemove = 0
			player.mo.flags &= ~mf_justattacked
		}
	}

	if player.playerstate == .dead {
		p_death_think(player)
		return
	}

	if player.mo.reactiontime > 0 {
		unsafe {
			player.mo.reactiontime--
		}
	} else {
		p_move_player(player)
	}

	p_calc_height(player)

	if cmd.buttons & int(ButtonCode.bt_special) != 0 {
		unsafe {
			cmd.buttons = 0
		}
	}

	p_move_psprites(player)

	unsafe {
		if player.powers[int(PowerType.strength)] != 0 {
			player.powers[int(PowerType.strength)]++
		}
		if player.powers[int(PowerType.invulnerability)] != 0 {
			player.powers[int(PowerType.invulnerability)]--
		}
		if player.powers[int(PowerType.invisibility)] != 0 {
			player.powers[int(PowerType.invisibility)]--
			if player.powers[int(PowerType.invisibility)] == 0 {
				player.mo.flags &= ~mf_shadow
			}
		}
		if player.powers[int(PowerType.infrared)] != 0 {
			player.powers[int(PowerType.infrared)]--
		}
		if player.powers[int(PowerType.ironfeet)] != 0 {
			player.powers[int(PowerType.ironfeet)]--
		}
		if player.damagecount > 0 {
			player.damagecount--
		}
		if player.bonuscount > 0 {
			player.bonuscount--
		}

		if player.powers[int(PowerType.invulnerability)] != 0 {
			if player.powers[int(PowerType.invulnerability)] > 4 * 32 || (player.powers[int(PowerType.invulnerability)] & 8) != 0 {
				player.fixedcolormap = invsecolormap
			} else {
				player.fixedcolormap = 0
			}
		} else if player.powers[int(PowerType.infrared)] != 0 {
			if player.powers[int(PowerType.infrared)] > 4 * 32 || (player.powers[int(PowerType.infrared)] & 8) != 0 {
				player.fixedcolormap = 1
			} else {
				player.fixedcolormap = 0
			}
		} else {
			player.fixedcolormap = 0
		}
	}
}

const mf_special = 1
const mf_solid = 2
const mf_shootable = 4
const mf_nosector = 8
const mf_noblockmap = 16
const mf_ambush = 32
const mf_justattacked = 128
const mf_spawnceiling = 256
const mf_nogravity = 512
const mf_dropoff = 0x400
const mf_pickup = 0x800
const mf_noclip = 0x1000
const mf_slide = 0x2000
const mf_float = 0x4000
const mf_teleport = 0x8000
const mf_missile = 0x10000
const mf_dropped = 0x20000
const mf_shadow = 0x40000
const mf_noblood = 0x80000
const mf_corpse = 0x100000
const mf_infloat = 0x200000
const mf_countkill = 0x400000
const mf_countitem = 0x800000
const mf_skullfly = 0x1000000
const mf_notdmatch = 0x2000000
const mf_translation = 0xc000000
