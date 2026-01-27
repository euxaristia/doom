module core

pub fn p_give_power(player voidptr, power int) bool {
	if player == unsafe { nil } {
		return false
	}
	mut pl := unsafe { &Player(player) }
	if power < 0 || power >= pl.powers.len {
		return false
	}
	// Minimal DeHackEd-compatible behavior: track active powers.
	pl.powers[power] = 1
	pl.message = 'power ${power} on'
	return true
}
