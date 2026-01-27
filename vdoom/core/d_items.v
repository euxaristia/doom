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

fn d_items_init() {
	// Mirror the classic weapon table layout with safe placeholder states.
	mut table := []WeaponInfo{len: numweapons}
	table[0].ammo = int(AmmoType.noammo)
	table[1].ammo = int(AmmoType.clip)
	table[2].ammo = int(AmmoType.shell)
	table[3].ammo = int(AmmoType.clip)
	table[4].ammo = int(AmmoType.misl)
	table[5].ammo = int(AmmoType.cell)
	table[6].ammo = int(AmmoType.cell)
	table[7].ammo = int(AmmoType.noammo)
	table[8].ammo = int(AmmoType.shell)
	weaponinfo = table.clone()
}
