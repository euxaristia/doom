module core

// Enemy AI is not ported yet; keep entrypoints present.
pub fn p_enemy_think(mobj &Mobj) {
	// Minimal behavior: enemies make noise so sight/sound code can hook in later.
	p_noise_alert(mobj, mobj)
}

pub fn p_spawn_brain_targets() {}
pub fn p_clear_brain_targets() {}
