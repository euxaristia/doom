@[translated]
module main

const (
	max_iwad_dirs   = 128
	iwad_mask_doom  = (1 << int(GameMission_t.doom)) | (1 << int(GameMission_t.doom2))
		| (1 << int(GameMission_t.pack_tnt)) | (1 << int(GameMission_t.pack_plut))
		| (1 << int(GameMission_t.pack_chex)) | (1 << int(GameMission_t.pack_hacx))
	iwad_mask_heretic = 1 << int(GameMission_t.heretic)
	iwad_mask_hexen   = 1 << int(GameMission_t.hexen)
	iwad_mask_strife  = 1 << int(GameMission_t.strife)
)

$if windows {
	#include <windows.h>
}

$if windows {
const (
	uninstaller_string = c'\\uninstl.exe /S '
	steam_bfg_gus_patches = c'steamapps\\common\\DOOM 3 BFG Edition\\base\\classicmusic\\instruments'
)

struct Registry_value_t {
	root  C.HKEY
	path  &i8
	value &i8
}

const uninstall_values = [
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Ultimate Doom for Windows 95'
		value: c'UninstallString'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Doom II for Windows 95'
		value: c'UninstallString'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Final Doom for Windows 95'
		value: c'UninstallString'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Doom Shareware for Windows 95'
		value: c'UninstallString'
	},
]

const root_path_keys = [
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\Activision\\DOOM Collector\'s Edition\\v1.0'
		value: c'INSTALLPATH'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\GOG.com\\Games\\1435848814'
		value: c'PATH'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\GOG.com\\Games\\1135892318'
		value: c'PATH'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\GOG.com\\Games\\1435848742'
		value: c'PATH'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\GOG.com\\Games\\1435827232'
		value: c'PATH'
	},
	Registry_value_t{
		root: C.HKEY_LOCAL_MACHINE
		path: c'Software\\GOG.com\\Games\\1432899949'
		value: c'PATH'
	},
]

const root_path_subdirs = [
	c'.',
	c'Doom2',
	c'Final Doom',
	c'Ultimate Doom',
	c'Plutonia',
	c'TNT',
	c'base\\wads',
]

const steam_install_location = Registry_value_t{
	root: C.HKEY_LOCAL_MACHINE
	path: c'Software\\Valve\\Steam'
	value: c'InstallPath'
}

const steam_install_subdirs = [
	c'steamapps\\common\\doom 2\\base',
	c'steamapps\\common\\final doom\\base',
	c'steamapps\\common\\ultimate doom\\base',
	c'steamapps\\common\\heretic shadow of the serpent riders\\base',
	c'steamapps\\common\\hexen\\base',
	c'steamapps\\common\\hexen deathkings of the dark citadel\\base',
	c'steamapps\\common\\DOOM 3 BFG Edition\\base\\wads',
	c'steamapps\\common\\Strife',
]

fn get_registry_string(reg_val &Registry_value_t) &i8 {
	mut key := C.HKEY(0)
	mut len := u32(0)
	mut valtype := u32(0)
	mut result := &i8(0)

	if C.RegOpenKeyExA(reg_val.root, reg_val.path, 0, C.KEY_READ, &key) != C.ERROR_SUCCESS {
		return (unsafe { nil })
	}

	if C.RegQueryValueExA(key, reg_val.value, (unsafe { nil }), &valtype, (unsafe { nil }), &len) == C.ERROR_SUCCESS
		&& valtype == C.REG_SZ {
		result = &i8(C.malloc(len + 1))

		if C.RegQueryValueExA(key, reg_val.value, (unsafe { nil }), &valtype, &u8(result),
			&len) != C.ERROR_SUCCESS {
			C.free(result)
			result = (unsafe { nil })
		} else {
			result[len] = 0
		}
	}

	C.RegCloseKey(key)

	return result
}

fn check_uninstall_strings() {
	for i := 0; i < uninstall_values.len; i++ {
		val := get_registry_string(&uninstall_values[i])
		if val == (unsafe { nil }) {
			continue
		}

		unstr := C.strstr(val, uninstaller_string)
		if unstr == (unsafe { nil }) {
			C.free(val)
			continue
		}

		path := unstr + C.strlen(uninstaller_string)
		add_iwad_dir(path)
	}
}

fn check_install_root_paths() {
	for i := 0; i < root_path_keys.len; i++ {
		install_path := get_registry_string(&root_path_keys[i])
		if install_path == (unsafe { nil }) {
			continue
		}

		for j := 0; j < root_path_subdirs.len; j++ {
			subpath := m_string_join(install_path, dir_separator_s, root_path_subdirs[j],
				(unsafe { nil }))
			add_iwad_dir(subpath)
		}

		C.free(install_path)
	}
}

fn check_steam_edition() {
	install_path := get_registry_string(&steam_install_location)
	if install_path == (unsafe { nil }) {
		return
	}

	for i := 0; i < steam_install_subdirs.len; i++ {
		subpath := m_string_join(install_path, dir_separator_s, steam_install_subdirs[i],
			(unsafe { nil }))
		add_iwad_dir(subpath)
	}

	C.free(install_path)
}

fn check_steam_gus_patches() {
	current_path := m_get_string_variable(c'gus_patch_path')
	if current_path != (unsafe { nil }) && C.strlen(current_path) > 0 {
		return
	}

	install_path := get_registry_string(&steam_install_location)
	if install_path == (unsafe { nil }) {
		return
	}

	patch_path := m_string_join(install_path, c'\\', steam_bfg_gus_patches, (unsafe { nil }))
	test_patch_path := m_string_join(patch_path, c'\\ACBASS.PAT', (unsafe { nil }))

	if m_file_exists(test_patch_path) {
		m_set_variable(c'gus_patch_path', patch_path)
	}

	C.free(test_patch_path)
	C.free(patch_path)
	C.free(install_path)
}

fn check_dos_defaults() {
	add_iwad_dir(c'\\doom2')
	add_iwad_dir(c'\\plutonia')
	add_iwad_dir(c'\\tnt')
	add_iwad_dir(c'\\doom_se')
	add_iwad_dir(c'\\doom')
	add_iwad_dir(c'\\dooms')
	add_iwad_dir(c'\\doomsw')
	add_iwad_dir(c'\\heretic')
	add_iwad_dir(c'\\hrtic_se')
	add_iwad_dir(c'\\hexen')
	add_iwad_dir(c'\\hexendk')
	add_iwad_dir(c'\\strife')
}
}

$if !windows {
const (
	steam_bfg_gus_patches = c'steamapps/common/DOOM 3 BFG Edition/base/classicmusic/instruments'
)
}

$if windows {
const (
	dir_separator   = `\\`
	dir_separator_s = c'\\'
	path_separator  = `;`
)
} $else {
const (
	dir_separator   = `/`
	dir_separator_s = c'/'
	path_separator  = `:`
)
}

const iwads = [
	Iwad_t{name: c'doom2.wad', mission: GameMission_t.doom2, mode: GameMode_t.commercial, description: c'Doom II'},
	Iwad_t{name: c'plutonia.wad', mission: GameMission_t.pack_plut, mode: GameMode_t.commercial, description: c'Final Doom: Plutonia Experiment'},
	Iwad_t{name: c'tnt.wad', mission: GameMission_t.pack_tnt, mode: GameMode_t.commercial, description: c'Final Doom: TNT: Evilution'},
	Iwad_t{name: c'doom.wad', mission: GameMission_t.doom, mode: GameMode_t.retail, description: c'Doom'},
	Iwad_t{name: c'doom1.wad', mission: GameMission_t.doom, mode: GameMode_t.shareware, description: c'Doom Shareware'},
	Iwad_t{name: c'chex.wad', mission: GameMission_t.pack_chex, mode: GameMode_t.retail, description: c'Chex Quest'},
	Iwad_t{name: c'hacx.wad', mission: GameMission_t.pack_hacx, mode: GameMode_t.commercial, description: c'Hacx'},
	Iwad_t{name: c'freedoom2.wad', mission: GameMission_t.doom2, mode: GameMode_t.commercial, description: c'Freedoom: Phase 2'},
	Iwad_t{name: c'freedoom1.wad', mission: GameMission_t.doom, mode: GameMode_t.retail, description: c'Freedoom: Phase 1'},
	Iwad_t{name: c'freedm.wad', mission: GameMission_t.doom2, mode: GameMode_t.commercial, description: c'FreeDM'},
	Iwad_t{name: c'heretic.wad', mission: GameMission_t.heretic, mode: GameMode_t.retail, description: c'Heretic'},
	Iwad_t{name: c'heretic1.wad', mission: GameMission_t.heretic, mode: GameMode_t.shareware, description: c'Heretic Shareware'},
	Iwad_t{name: c'hexen.wad', mission: GameMission_t.hexen, mode: GameMode_t.commercial, description: c'Hexen'},
	Iwad_t{name: c'strife1.wad', mission: GameMission_t.strife, mode: GameMode_t.commercial, description: c'Strife'},
]

@[weak] __global ( iwad_dirs_built bool )
@[weak] __global ( iwad_dirs [max_iwad_dirs]&i8 )
@[weak] __global ( num_iwad_dirs int )

fn deh_string(s &i8) &i8
fn m_string_join(s ...&i8) &i8

fn C.M_FileCaseExists(&i8) &i8
fn C.M_GetStringVariable(&i8) &i8
fn C.M_SetVariable(&i8, &i8)

fn m_file_case_exists(path &i8) &i8 {
	return C.M_FileCaseExists(path)
}

fn m_get_string_variable(name &i8) &i8 {
	return C.M_GetStringVariable(name)
}

fn m_set_variable(name &i8, value &i8) {
	C.M_SetVariable(name, value)
}

@[c: 'D_IsIWADName']
fn d_is_iwad_name(name &i8) bool {
	for i := 0; i < iwads.len; i++ {
		if !C.strcasecmp(name, iwads[i].name) {
			return true
		}
	}

	return false
}

fn add_iwad_dir(dir &i8) {
	if num_iwad_dirs < max_iwad_dirs {
		iwad_dirs[num_iwad_dirs] = dir
		num_iwad_dirs++
	}
}

fn dir_is_file(path &i8, filename &i8) bool {
	return C.strchr(path, dir_separator) != (unsafe { nil })
		&& !C.strcasecmp(m_base_name(path), filename)
}

fn check_directory_has_iwad(dir &i8, iwadname &i8) &i8 {
	mut filename := &i8(0)
	mut probe := &i8(0)

	probe = m_file_case_exists(dir)
	if dir_is_file(dir, iwadname) && probe != (unsafe { nil }) {
		return probe
	}

	if !C.strcmp(dir, c'.') {
		filename = m_string_duplicate(iwadname)
	} else {
		filename = m_string_join(dir, dir_separator_s, iwadname, (unsafe { nil }))
	}

	C.free(probe)
	probe = m_file_case_exists(filename)
	C.free(filename)
	if probe != (unsafe { nil }) {
		return probe
	}

	return (unsafe { nil })
}

fn search_directory_for_iwad(dir &i8, mask int, mission &GameMission_t) &i8 {
	for i := 0; i < iwads.len; i++ {
		if ((1 << int(iwads[i].mission)) & mask) == 0 {
			continue
		}

		filename := check_directory_has_iwad(dir, deh_string(iwads[i].name))
		if filename != (unsafe { nil }) {
			*mission = iwads[i].mission
			return filename
		}
	}

	return (unsafe { nil })
}

fn identify_iwad_by_name(name &i8, mask int) GameMission_t {
	mut mission := GameMission_t.none_
	mut base := m_base_name(name)

	for i := 0; i < iwads.len; i++ {
		if ((1 << int(iwads[i].mission)) & mask) == 0 {
			continue
		}

		if !C.strcasecmp(base, iwads[i].name) {
			mission = iwads[i].mission
			break
		}
	}

	return mission
}

fn add_iwad_path(path &i8, suffix &i8) {
	mut dup_path := m_string_duplicate(path)
	mut left := dup_path

	for {
		p := C.strchr(left, path_separator)
		if p != (unsafe { nil }) {
			*p = `\0`
			add_iwad_dir(m_string_join(left, suffix, (unsafe { nil })))
			left = p + 1
		} else {
			break
		}
	}

	add_iwad_dir(m_string_join(left, suffix, (unsafe { nil })))
	C.free(dup_path)
}

$if !windows {
fn add_xdg_dirs() {
	mut env := C.getenv(c'XDG_DATA_HOME')
	mut tmp_env := &i8(0)

	if env == (unsafe { nil }) {
		mut homedir := C.getenv(c'HOME')
		if homedir == (unsafe { nil }) {
			homedir = c'/'
		}
		tmp_env = m_string_join(homedir, c'/.local/share', (unsafe { nil }))
		env = tmp_env
	}

	add_iwad_dir(m_string_join(env, c'/games/doom', (unsafe { nil })))
	C.free(tmp_env)

	env = C.getenv(c'XDG_DATA_DIRS')
	if env == (unsafe { nil }) {
		env = c'/usr/local/share:/usr/share'
	}

	add_iwad_path(env, c'/games/doom')
	add_iwad_path(env, c'/games/doom3bfg/base/wads')
}

$if !macos {
fn add_steam_dirs() {
	mut homedir := C.getenv(c'HOME')
	if homedir == (unsafe { nil }) {
		homedir = c'/'
	}

	steampath := m_string_join(homedir, c'/.steam/root/steamapps/common', (unsafe { nil }))
	add_iwad_path(steampath, c'/Doom 2/base')
	add_iwad_path(steampath, c'/Master Levels of Doom/doom2')
	add_iwad_path(steampath, c'/Ultimate Doom/base')
	add_iwad_path(steampath, c'/Final Doom/base')
	add_iwad_path(steampath, c'/DOOM 3 BFG Edition/base/wads')
	add_iwad_path(steampath, c'/Heretic Shadow of the Serpent Riders/base')
	add_iwad_path(steampath, c'/Hexen/base')
	add_iwad_path(steampath, c'/Hexen Deathkings of the Dark Citadel/base')
	add_iwad_path(steampath, c'/Strife')
	C.free(steampath)
}
}
}

fn build_iwad_dir_list() {
	mut env := &i8(0)

	if iwad_dirs_built {
		return
	}

	add_iwad_dir(c'.')
	add_iwad_dir(m_dir_name(myargv[0]))

	env = C.getenv(c'DOOMWADDIR')
	if env != (unsafe { nil }) {
		add_iwad_dir(env)
	}

	env = C.getenv(c'DOOMWADPATH')
	if env != (unsafe { nil }) {
		add_iwad_path(env, c'')
	}

	$if windows {
		check_uninstall_strings()
		check_install_root_paths()
		check_steam_edition()
		check_dos_defaults()
		check_steam_gus_patches()
	} $else {
		add_xdg_dirs()
		$if !macos {
			add_steam_dirs()
		}
	}

	iwad_dirs_built = true
}

@[c: 'D_FindWADByName']
fn d_find_wadb_y_name(name &i8) &i8 {
	mut path := &i8(0)
	mut probe := &i8(0)

	probe = m_file_case_exists(name)
	if probe != (unsafe { nil }) {
		return probe
	}

	build_iwad_dir_list()

	for i := 0; i < num_iwad_dirs; i++ {
		probe = m_file_case_exists(iwad_dirs[i])
		if dir_is_file(iwad_dirs[i], name) && probe != (unsafe { nil }) {
			return probe
		}

		path = m_string_join(iwad_dirs[i], dir_separator_s, name, (unsafe { nil }))
		probe = m_file_case_exists(path)
		if probe != (unsafe { nil }) {
			return probe
		}

		C.free(path)
	}

	return (unsafe { nil })
}

@[c: 'D_TryFindWADByName']
fn d_try_find_wad_by_name(filename &i8) &i8 {
	result := d_find_wadb_y_name(filename)
	if result != (unsafe { nil }) {
		return result
	}

	return m_string_duplicate(filename)
}

@[c: 'D_FindIWAD']
fn d_find_iwad(mask int, mission &GameMission_t) &i8 {
	mut result := &i8(0)
	mut iwadfile := &i8(0)
	mut iwadparm := 0

	iwadparm = m_check_parm_with_args(c'-iwad', 1)
	if iwadparm != 0 {
		iwadfile = myargv[iwadparm + 1]
		result = d_find_wadb_y_name(iwadfile)
		if result == (unsafe { nil }) {
			i_error(c"IWAD file '%s' not found!", iwadfile)
		}
		*mission = identify_iwad_by_name(result, mask)
	} else {
		result = (unsafe { nil })
		build_iwad_dir_list()
		for i := 0; result == (unsafe { nil }) && i < num_iwad_dirs; i++ {
			result = search_directory_for_iwad(iwad_dirs[i], mask, mission)
		}
	}

	return result
}

@[c: 'D_FindAllIWADs']
fn d_find_all_iwads(mask int) &&Iwad_t {
	mut result := &&Iwad_t(C.malloc(sizeof(&Iwad_t) * (iwads.len + 1)))
	mut result_len := 0

	for i := 0; i < iwads.len; i++ {
		if ((1 << int(iwads[i].mission)) & mask) == 0 {
			continue
		}

		filename := d_find_wadb_y_name(iwads[i].name)
		if filename != (unsafe { nil }) {
			result[result_len] = &iwads[i]
			result_len++
		}
	}

	result[result_len] = (unsafe { nil })
	return result
}

@[c: 'D_SaveGameIWADName']
fn d_save_game_iwadn_ame(gamemission GameMission_t) &i8 {
	for i := 0; i < iwads.len; i++ {
		if gamemission == iwads[i].mission {
			return iwads[i].name
		}
	}

	return c'unknown.wad'
}

@[c: 'D_SuggestIWADName']
fn d_suggest_iwad_name(mission GameMission_t, mode GameMode_t) &i8 {
	for i := 0; i < iwads.len; i++ {
		if iwads[i].mission == mission && iwads[i].mode == mode {
			return iwads[i].name
		}
	}

	return c'unknown.wad'
}

@[c: 'D_SuggestGameName']
fn d_suggest_game_name(mission GameMission_t, mode GameMode_t) &i8 {
	for i := 0; i < iwads.len; i++ {
		if iwads[i].mission == mission
			&& (mode == GameMode_t.indetermined || iwads[i].mode == mode) {
			return iwads[i].description
		}
	}

	return c'Unknown game?'
}
