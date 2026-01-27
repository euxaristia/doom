@[has_globals]
module core

pub const deh_default_initial_health = 100
pub const deh_default_initial_bullets = 50
pub const deh_default_max_health = 200
pub const deh_default_max_armor = 200
pub const deh_default_green_armor_class = 1
pub const deh_default_blue_armor_class = 2
pub const deh_default_max_soulsphere = 200
pub const deh_default_soulsphere_health = 100
pub const deh_default_megasphere_health = 200
pub const deh_default_god_mode_health = 100
pub const deh_default_idfa_armor = 200
pub const deh_default_idfa_armor_class = 2
pub const deh_default_idkfa_armor = 200
pub const deh_default_idkfa_armor_class = 2
pub const deh_default_bfg_cells_per_shot = 40
pub const deh_default_species_infighting = 0

__global deh_initial_health = deh_default_initial_health
__global deh_initial_bullets = deh_default_initial_bullets
__global deh_max_health = deh_default_max_health
__global deh_max_armor = deh_default_max_armor
__global deh_green_armor_class = deh_default_green_armor_class
__global deh_blue_armor_class = deh_default_blue_armor_class
__global deh_max_soulsphere = deh_default_max_soulsphere
__global deh_soulsphere_health = deh_default_soulsphere_health
__global deh_megasphere_health = deh_default_megasphere_health
__global deh_god_mode_health = deh_default_god_mode_health
__global deh_idfa_armor = deh_default_idfa_armor
__global deh_idfa_armor_class = deh_default_idfa_armor_class
__global deh_idkfa_armor = deh_default_idkfa_armor
__global deh_idkfa_armor_class = deh_default_idkfa_armor_class
__global deh_bfg_cells_per_shot = deh_default_bfg_cells_per_shot
__global deh_species_infighting = deh_default_species_infighting

pub fn deh_reset_defaults() {
	deh_initial_health = deh_default_initial_health
	deh_initial_bullets = deh_default_initial_bullets
	deh_max_health = deh_default_max_health
	deh_max_armor = deh_default_max_armor
	deh_green_armor_class = deh_default_green_armor_class
	deh_blue_armor_class = deh_default_blue_armor_class
	deh_max_soulsphere = deh_default_max_soulsphere
	deh_soulsphere_health = deh_default_soulsphere_health
	deh_megasphere_health = deh_default_megasphere_health
	deh_god_mode_health = deh_default_god_mode_health
	deh_idfa_armor = deh_default_idfa_armor
	deh_idfa_armor_class = deh_default_idfa_armor_class
	deh_idkfa_armor = deh_default_idkfa_armor
	deh_idkfa_armor_class = deh_default_idkfa_armor_class
	deh_bfg_cells_per_shot = deh_default_bfg_cells_per_shot
	deh_species_infighting = deh_default_species_infighting
}

pub fn deh_init() {
	deh_reset_defaults()
	deh_ammo_init()
	deh_bexstr_init()
	deh_cheat_init()
	deh_doom_init()
	deh_frame_init()
	deh_ptr_init()
	deh_sound_init()
	deh_thing_init()
	deh_weapon_init()
}
