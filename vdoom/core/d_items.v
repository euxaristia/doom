@[has_globals]
module core

pub struct WeaponInfo {
pub mut:
	ammo       int
	upstate    int
	downstate  int
	readystate int
	atkstate   int
	flashstate int
}

__global weaponinfo = []WeaponInfo{len: numweapons}
