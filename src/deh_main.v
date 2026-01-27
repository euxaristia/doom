@[translated]
module main

// Dehacked entrypoint and common code.

const deh_vanilla_numstates = 966
const deh_vanilla_numsfx = 107

__global (
	mut deh_initialized bool
	mut deh_file_loaded bool
)

fn C.strlen(&i8) usize

fn cstring(p &i8) string {
	if p == unsafe { nil } {
		return ''
	}
	unsafe {
		return string{
			str: p
			len: int(C.strlen(p))
		}
	}
}

fn make_cstring(s string) &i8 {
	buf := &u8(z_malloc(s.len + 1, pu_static, unsafe { nil }))
	unsafe {
		for i := 0; i < s.len; i++ {
			buf[i] = s[i]
		}
		buf[s.len] = 0
	}
	return &i8(buf)
}

@[export: 'DEH_Checksum']
pub fn deh_checksum(mut digest Sha1_digest_t) {
	// Placeholder checksum: zero the digest.
	for i := 0; i < digest.len; i++ {
		digest[i] = 0
	}
}

fn initialize_sections() {
	for i := 0; i < deh_section_types.len; i++ {
		section := deh_section_types[i]
		if section == unsafe { nil } {
			break
		}
		if section.init != unsafe { nil } {
			section.init()
		}
	}
}

fn deh_init() {
	if m_check_parm(c'-nocheats') > 0 {
		deh_apply_cheats = false
	}
	initialize_sections()
	deh_initialized = true
}

fn section_by_name(name &i8) &Deh_section_t {
	want := cstring(name).to_lower()
	if !deh_allow_extended_strings && want.starts_with('[strings]') {
		return unsafe { nil }
	}
	for i := 0; i < deh_section_types.len; i++ {
		section := deh_section_types[i]
		if section == unsafe { nil } {
			break
		}
		if cstring(section.name).to_lower() == want {
			return section
		}
	}
	return unsafe { nil }
}

fn parse_context(context &Deh_context_t, allow_long bool) {
	mut current_section := unsafe { nil } as &Deh_section_t
	mut tag := voidptr(0)
	deh_allow_long_strings = allow_long
	for {
		line_ptr := deh_read_line(context, deh_allow_extended_strings)
		if line_ptr == unsafe { nil } {
			break
		}
		line := cstring(line_ptr).trim_space()
		if line.len == 0 || line.starts_with('#') {
			continue
		}
		if line.starts_with('[') {
			// Section transition.
			if current_section != unsafe { nil } && current_section.end != unsafe { nil } {
				current_section.end(context, tag)
			}
			current_section = section_by_name(line.str)
			tag = voidptr(0)
			if current_section != unsafe { nil } && current_section.start != unsafe { nil } {
				tag = current_section.start(context, line.str)
			}
			continue
		}
		if current_section != unsafe { nil } && current_section.line_parser != unsafe { nil } {
			current_section.line_parser(context, line.str, tag)
		}
	}
	if current_section != unsafe { nil } && current_section.end != unsafe { nil } {
		current_section.end(context, tag)
	}
}

@[export: 'DEH_LoadFile']
pub fn deh_load_file(filename &i8) int {
	if !deh_initialized {
		deh_init()
	}
	ctx := deh_open_file(filename)
	if ctx == unsafe { nil } {
		unsafe {
			eprintln('DEH_LoadFile: Unable to open ${cstring(filename)}')
		}
		return 0
	}
	parse_context(ctx, deh_allow_long_strings)
	had_err := deh_had_error(ctx)
	deh_close_file(ctx)
	deh_file_loaded = true
	return if had_err { 0 } else { 1 }
}

@[export: 'DEH_AutoLoadPatches']
pub fn deh_auto_load_patches(path &i8) {
	_ = path
	// Placeholder: glob-based auto-loading can be added later.
}

@[export: 'DEH_LoadLump']
pub fn deh_load_lump(lumpnum int, allow_long bool, allow_error bool) int {
	_ = allow_error
	if !deh_initialized {
		deh_init()
	}
	ctx := deh_open_lump(lumpnum)
	if ctx == unsafe { nil } {
		eprintln('DEH_LoadLump: Unable to open lump ${lumpnum}')
		return 0
	}
	parse_context(ctx, allow_long)
	had_err := deh_had_error(ctx)
	deh_close_file(ctx)
	deh_file_loaded = true
	return if had_err { 0 } else { 1 }
}

@[export: 'DEH_LoadLumpByName']
pub fn deh_load_lump_by_name(name &i8, allow_long bool, allow_error bool) int {
	lumpnum := w_check_num_for_name(name)
	if lumpnum < 0 {
		if allow_error {
			unsafe { eprintln('DEH_LoadLumpByName: lump not found: ${cstring(name)}') }
		}
		return 0
	}
	return deh_load_lump(lumpnum, allow_long, allow_error)
}

fn argv_at(i int) &i8 {
	unsafe {
		return &i8(myargv[i])
	}
}

@[export: 'DEH_ParseCommandLine']
pub fn deh_parse_command_line() {
	// Enable extended strings in BEX mode.
	if m_check_parm(c'-bex') > 0 {
		deh_allow_extended_strings = true
		deh_allow_long_strings = true
	}

	// Load -deh/-bex files with one following argument.
	for _, flag in [c'-deh', c'-bex'] {
		p := m_check_parm_with_args(flag, 1)
		if p > 0 && p + 1 < myargc {
			deh_load_file(argv_at(p + 1))
		}
	}
}

@[export: 'DEH_ParseAssignment']
pub fn deh_parse_assignment(line &i8, variable_name &&u8, value &&u8) bool {
	text := cstring(line)
	eq := text.index('=') or { return false }
	var := text[..eq].trim_space()
	val := text[eq + 1..].trim_space()
	unsafe {
		*variable_name = make_cstring(var)
		*value = make_cstring(val)
	}
	return true
}
