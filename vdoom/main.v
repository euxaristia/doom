module main

import os
import core

fn main() {
	args := os.args[1..]
	mut wad_path := ''
	mut list_all := false
	mut max_list := 10
	mut use_stream := true
	mut extract_name := ''
	mut extract_out := ''
	mut find_name := ''
	mut build_hash := true
	mut hash_stats := false
	mut list_hash := false
	mut zone_mb := 0

	for i := 0; i < args.len; i++ {
		arg := args[i]
		match arg {
			'-h', '--help' {
				print_usage()
				return
			}
			'-list', '--list' {
				list_all = true
				max_list = 0
			}
			'--stream' {
				use_stream = true
			}
			'--no-stream' {
				use_stream = false
			}
			'--hash' {
				build_hash = true
			}
			'--no-hash' {
				build_hash = false
			}
			'--hash-stats' {
				hash_stats = true
			}
			'--list-hash' {
				list_hash = true
			}
			'--zone-mb' {
				if i + 1 >= args.len {
					eprintln('error: missing value for $arg')
					print_usage()
					return
				}
				zone_mb = args[i + 1].int()
				i++
			}
			'--extract' {
				if i + 1 >= args.len {
					eprintln('error: missing value for $arg')
					print_usage()
					return
				}
				extract_name = args[i + 1]
				i++
			}
			'--out' {
				if i + 1 >= args.len {
					eprintln('error: missing value for $arg')
					print_usage()
					return
				}
				extract_out = args[i + 1]
				i++
			}
			'--find' {
				if i + 1 >= args.len {
					eprintln('error: missing value for $arg')
					print_usage()
					return
				}
				find_name = args[i + 1]
				i++
			}
			'-n', '--max' {
				if i + 1 >= args.len {
					eprintln('error: missing value for $arg')
					print_usage()
					return
				}
				max_list = args[i + 1].int()
				i++
			}
			'-wad', '--wad' {
				if i + 1 >= args.len {
					eprintln('error: missing value for $arg')
					print_usage()
					return
				}
				wad_path = args[i + 1]
				i++
			}
			else {
				if arg.starts_with('-') {
					eprintln('error: unknown option: $arg')
					print_usage()
					return
				}
				wad_path = arg
			}
		}
	}

	if wad_path.len == 0 {
		wad_path = pick_default_wad()
	}

	if wad_path.len == 0 {
		eprintln('error: no wad specified and no default wad found')
		print_usage()
		return
	}

	if !os.is_file(wad_path) {
		eprintln('error: wad not found: $wad_path')
		return
	}

	if zone_mb > 0 {
		os.setenv('VDoomZoneMB', zone_mb.str(), true)
	}
	core.i_print_startup_banner('vdoom (V port)')
	core.boot()
	core.d_iwad_init(wad_path)
	core.i_set_window_title(core.d_iwad_title())
	zone := core.i_zone_base()
	println('zone size: ${zone.size} bytes')

	println('vdoom: WAD diagnostics')
	println('path: $wad_path')
	println('size: ${os.file_size(wad_path)} bytes')

	mut wad := core.load_wad_with_options(wad_path, use_stream, build_hash) or {
		eprintln('error: $err')
		return
	}

	println('kind: ${wad.kind}')
	println('lumps: ${wad.num_lumps}')
	println('dir offset: ${wad.dir_offset}')
	println('stream: ${wad.stream}')
	println('hash: ${wad.has_hash}')
	println('mission: ${core.d_game_mission_string(core.game_mission())}')
	println('mode: ${core.d_game_mode_string(core.game_mode())}')
	println('desc: ${core.game_description()}')
	detected, name := core.d_detected_iwad()
	if detected {
		println('iwad: ${name}')
	}
	p := core.d_iwad_path()
	if p.len > 0 {
		println('iwad path: ${p}')
	}
	core.render_demo_frame(mut wad)
	core.render_more_frames(2)

	if hash_stats {
		stats := wad.hash_stats() or {
			eprintln('error: $err')
			return
		}
		println('hash buckets: ${stats.buckets}')
		println('hash used: ${stats.used}')
		println('hash collisions: ${stats.collisions}')
		println('hash max chain: ${stats.max_chain}')
		println('hash avg chain: ${stats.avg_chain:.2f}')
	}

	if list_hash {
		if !wad.has_hash {
			eprintln('error: hash table not built (use --hash)')
			return
		}
		for i in 0 .. wad.lumphash.len {
			mut idx := wad.lumphash[i]
			if idx == -1 {
				continue
			}
			mut line := '${i}: '
			mut first := true
			for idx != -1 {
				if !first {
					line += ' -> '
				}
				l := wad.lumps[idx]
				line += '${idx}:${l.name}'
				first = false
				idx = l.next
			}
			println(line)
		}
	}

	if find_name.len > 0 {
		idx := wad.find_lump_index(find_name)
		if idx < 0 {
			println('lump ${find_name} not found')
			return
		}
		l := wad.lumps[idx]
		println('lump ${find_name} found at index ${idx} pos=${l.file_pos} size=${l.size}')
		return
	}

	if extract_name.len > 0 {
		out_path := if extract_out.len > 0 { extract_out } else { '${extract_name}.lump' }
		data := wad.read_lump(extract_name) or {
			eprintln('error: $err')
			return
		}
		os.write_file_array(out_path, data) or {
			eprintln('error: failed to write $out_path: $err')
			return
		}
		println('extracted ${extract_name} -> $out_path (${data.len} bytes)')
		return
	}

	if wad.lumps.len == 0 {
		return
	}

	mut limit := wad.lumps.len
	if list_all {
		limit = wad.lumps.len
	} else if max_list > 0 && max_list < wad.lumps.len {
		limit = max_list
	}

	println('listing ${limit} lump(s)')
	for i in 0 .. limit {
		l := wad.lumps[i]
		println('$i ${l.name} pos=${l.file_pos} size=${l.size}')
	}
}

fn pick_default_wad() string {
	env_path := os.getenv('DOOM_WAD')
	if env_path.len > 0 && os.is_file(env_path) {
		return env_path
	}
	found := core.d_find_iwad()
	if found.len > 0 {
		return found
	}
	candidates := [
		os.join_path(os.getwd(), 'wads', 'doom1.wad'),
		os.join_path(os.getwd(), 'wads', 'freedoom1.wad'),
		os.join_path(os.getwd(), 'wads', 'freedoom2.wad'),
	]
	for path in candidates {
		if os.is_file(path) {
			return path
		}
	}
	return ''
}

fn print_usage() {
	println('usage: v run vdoom/main.v [options] [wad]')
	println('options:')
	println('  -wad, --wad <path>   wad file path')
	println('  -list, --list        list all lumps')
	println('  -n, --max <count>    list first N lumps (default 10)')
	println('  --stream             use streaming reads (default)')
	println('  --no-stream          load whole wad into memory')
	println('  --find <name>        check lump by name and print details')
	println('  --extract <name>     extract lump by name (max 8 chars)')
	println('  --out <path>         output path for extraction')
	println('  --hash               build hash table (default)')
	println('  --no-hash            skip hash table build')
	println('  --hash-stats         print hash table stats')
	println('  --list-hash          list hash buckets and chains')
	println('  --zone-mb <mb>       override zone memory size')
	println('  -h, --help           show this help')
	println('')
	println('defaults:')
	println('  DOOM_WAD env var, or wads/doom1.wad, wads/freedoom1.wad, wads/freedoom2.wad')
}
