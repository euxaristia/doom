@[translated]
module main

// Reading and writing various structures into packets.

fn C.strlen(&i8) usize

@[c: 'M_StringCopy']
fn m_string_copy(dest &i8, src &i8, dest_size usize) bool

@[c: 'I_Error']
@[c2v_variadic]
fn i_error(error &i8, ...)

const net_maxplayers = 8
const maxplayername = 30
const net_ticdiff_forward = 1 << 0
const net_ticdiff_side = 1 << 1
const net_ticdiff_turn = 1 << 2
const net_ticdiff_buttons = 1 << 3
const net_ticdiff_consist = 1 << 4
const net_ticdiff_chat = 1 << 5
const net_ticdiff_raven = 1 << 6
const net_ticdiff_strife = 1 << 7

type Prng_seed_t = [16]u8

struct Protocol_name_t {
	protocol Net_protocol_t
	name     &i8
}

const protocol_names = [
	Protocol_name_t{
		protocol: .net_protocol_chocolate_doom_0
		name:     c'CHOCOLATE_DOOM_0'
	},
]

@[export: 'NET_WriteConnectData']
pub fn net_write_connect_data(packet &Net_packet_t, data &Net_connect_data_t) {
	net_write_int8(packet, u32(data.gamemode))
	net_write_int8(packet, u32(data.gamemission))
	net_write_int8(packet, u32(data.lowres_turn))
	net_write_int8(packet, u32(data.drone))
	net_write_int8(packet, u32(data.max_players))
	net_write_int8(packet, u32(data.is_freedoom))
	net_write_sha1_sum(packet, data.wad_sha1sum)
	net_write_sha1_sum(packet, data.deh_sha1sum)
	net_write_int8(packet, u32(data.player_class))
}

@[export: 'NET_ReadConnectData']
pub fn net_read_connect_data(packet &Net_packet_t, data &Net_connect_data_t) bool {
	mut v := u32(0)
	if !net_read_int8(packet, &v) {
		return false
	}
	data.gamemode = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	data.gamemission = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	data.lowres_turn = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	data.drone = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	data.max_players = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	data.is_freedoom = int(v)
	if !net_read_sha1_sum(packet, mut data.wad_sha1sum) {
		return false
	}
	if !net_read_sha1_sum(packet, mut data.deh_sha1sum) {
		return false
	}
	if !net_read_int8(packet, &v) {
		return false
	}
	data.player_class = int(v)
	return true
}

@[export: 'NET_WriteSettings']
pub fn net_write_settings(packet &Net_packet_t, settings &Net_gamesettings_t) {
	net_write_int8(packet, u32(settings.ticdup))
	net_write_int8(packet, u32(settings.extratics))
	net_write_int8(packet, u32(settings.deathmatch))
	net_write_int8(packet, u32(settings.nomonsters))
	net_write_int8(packet, u32(settings.fast_monsters))
	net_write_int8(packet, u32(settings.respawn_monsters))
	net_write_int8(packet, u32(settings.episode))
	net_write_int8(packet, u32(settings.map_))
	net_write_int8(packet, u32(settings.skill))
	net_write_int8(packet, u32(settings.gameversion))
	net_write_int8(packet, u32(settings.lowres_turn))
	net_write_int8(packet, u32(settings.new_sync))
	net_write_int32(packet, u32(settings.timelimit))
	net_write_int8(packet, u32(settings.loadgame))
	net_write_int8(packet, u32(settings.random))
	net_write_int8(packet, u32(settings.num_players))
	net_write_int8(packet, u32(settings.consoleplayer))
	for i := 0; i < settings.num_players && i < net_maxplayers; i++ {
		net_write_int8(packet, u32(settings.player_classes[i]))
	}
}

@[export: 'NET_ReadSettings']
pub fn net_read_settings(packet &Net_packet_t, settings &Net_gamesettings_t) bool {
	mut u := u32(0)
	mut s := int(0)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.ticdup = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.extratics = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.deathmatch = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.nomonsters = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.fast_monsters = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.respawn_monsters = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.episode = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.map_ = int(u)
	if !net_read_sint8(packet, &s) {
		return false
	}
	settings.skill = s
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.gameversion = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.lowres_turn = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.new_sync = int(u)
	if !net_read_int32(packet, &u) {
		return false
	}
	settings.timelimit = int(u)
	if !net_read_sint8(packet, &s) {
		return false
	}
	settings.loadgame = s
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.random = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	settings.num_players = int(u)
	if !net_read_sint8(packet, &s) {
		return false
	}
	settings.consoleplayer = s
	for i := 0; i < settings.num_players && i < net_maxplayers; i++ {
		if !net_read_int8(packet, &u) {
			return false
		}
		settings.player_classes[i] = int(u)
	}
	return true
}

@[export: 'NET_ReadQueryData']
pub fn net_read_query_data(packet &Net_packet_t, query &Net_querydata_t) bool {
	query.version = net_read_safe_string(packet)
	if query.version == unsafe { nil } {
		return false
	}
	mut v := u32(0)
	if !net_read_int8(packet, &v) {
		return false
	}
	query.server_state = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	query.num_players = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	query.max_players = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	query.gamemode = int(v)
	if !net_read_int8(packet, &v) {
		return false
	}
	query.gamemission = int(v)
	query.description = net_read_safe_string(packet)
	query.protocol = net_read_protocol_list(packet)
	return query.description != unsafe { nil }
}

@[export: 'NET_WriteQueryData']
pub fn net_write_query_data(packet &Net_packet_t, query &Net_querydata_t) {
	net_write_string(packet, query.version)
	net_write_int8(packet, u32(query.server_state))
	net_write_int8(packet, u32(query.num_players))
	net_write_int8(packet, u32(query.max_players))
	net_write_int8(packet, u32(query.gamemode))
	net_write_int8(packet, u32(query.gamemission))
	net_write_string(packet, query.description)
	net_write_protocol_list(packet)
}

@[export: 'NET_WriteTiccmdDiff']
pub fn net_write_ticcmd_diff(packet &Net_packet_t, diff &Net_ticdiff_t, lowres_turn bool) {
	net_write_int8(packet, diff.diff)
	if (diff.diff & net_ticdiff_forward) != 0 {
		net_write_int8(packet, u32(diff.cmd.forwardmove))
	}
	if (diff.diff & net_ticdiff_side) != 0 {
		net_write_int8(packet, u32(diff.cmd.sidemove))
	}
	if (diff.diff & net_ticdiff_turn) != 0 {
		if lowres_turn {
			net_write_int8(packet, u32(int(diff.cmd.angleturn) / 256))
		} else {
			net_write_int16(packet, u32(diff.cmd.angleturn))
		}
	}
	if (diff.diff & net_ticdiff_buttons) != 0 {
		net_write_int8(packet, diff.cmd.buttons)
	}
	if (diff.diff & net_ticdiff_consist) != 0 {
		net_write_int8(packet, diff.cmd.consistancy)
	}
	if (diff.diff & net_ticdiff_chat) != 0 {
		net_write_int8(packet, diff.cmd.chatchar)
	}
	if (diff.diff & net_ticdiff_raven) != 0 {
		net_write_int8(packet, diff.cmd.lookfly)
		net_write_int8(packet, diff.cmd.arti)
	}
	if (diff.diff & net_ticdiff_strife) != 0 {
		net_write_int8(packet, diff.cmd.buttons2)
		net_write_int16(packet, u32(diff.cmd.inventory))
	}
}

@[export: 'NET_ReadTiccmdDiff']
pub fn net_read_ticcmd_diff(packet &Net_packet_t, diff &Net_ticdiff_t, lowres_turn bool) bool {
	mut u := u32(0)
	mut s := int(0)
	if !net_read_int8(packet, &u) {
		return false
	}
	diff.diff = u
	if (diff.diff & net_ticdiff_forward) != 0 {
		if !net_read_sint8(packet, &s) {
			return false
		}
		diff.cmd.forwardmove = i8(s)
	}
	if (diff.diff & net_ticdiff_side) != 0 {
		if !net_read_sint8(packet, &s) {
			return false
		}
		diff.cmd.sidemove = i8(s)
	}
	if (diff.diff & net_ticdiff_turn) != 0 {
		if lowres_turn {
			if !net_read_sint8(packet, &s) {
				return false
			}
			diff.cmd.angleturn = i16(s * 256)
		} else {
			if !net_read_sint16(packet, &s) {
				return false
			}
			diff.cmd.angleturn = i16(s)
		}
	}
	if (diff.diff & net_ticdiff_buttons) != 0 {
		if !net_read_int8(packet, &u) {
			return false
		}
		diff.cmd.buttons = u8(u)
	}
	if (diff.diff & net_ticdiff_consist) != 0 {
		if !net_read_int8(packet, &u) {
			return false
		}
		diff.cmd.consistancy = u8(u)
	}
	if (diff.diff & net_ticdiff_chat) != 0 {
		if !net_read_int8(packet, &u) {
			return false
		}
		diff.cmd.chatchar = u8(u)
	}
	if (diff.diff & net_ticdiff_raven) != 0 {
		if !net_read_int8(packet, &u) {
			return false
		}
		diff.cmd.lookfly = u8(u)
		if !net_read_int8(packet, &u) {
			return false
		}
		diff.cmd.arti = u8(u)
	}
	if (diff.diff & net_ticdiff_strife) != 0 {
		if !net_read_int8(packet, &u) {
			return false
		}
		diff.cmd.buttons2 = u8(u)
		if !net_read_int16(packet, &u) {
			return false
		}
		diff.cmd.inventory = int(u)
	}
	return true
}

@[export: 'NET_TiccmdDiff']
pub fn net_ticcmd_diff(tic1 &Ticcmd_t, tic2 &Ticcmd_t, diff &Net_ticdiff_t) {
	diff.diff = 0
	diff.cmd = *tic2
	if tic1.forwardmove != tic2.forwardmove {
		diff.diff |= net_ticdiff_forward
	}
	if tic1.sidemove != tic2.sidemove {
		diff.diff |= net_ticdiff_side
	}
	if tic1.angleturn != tic2.angleturn {
		diff.diff |= net_ticdiff_turn
	}
	if tic1.buttons != tic2.buttons {
		diff.diff |= net_ticdiff_buttons
	}
	if tic1.consistancy != tic2.consistancy {
		diff.diff |= net_ticdiff_consist
	}
	if tic2.chatchar != 0 {
		diff.diff |= net_ticdiff_chat
	}
	if tic1.lookfly != tic2.lookfly || tic2.arti != 0 {
		diff.diff |= net_ticdiff_raven
	}
	if tic1.buttons2 != tic2.buttons2 || tic2.inventory != 0 {
		diff.diff |= net_ticdiff_strife
	}
}

@[export: 'NET_TiccmdPatch']
pub fn net_ticcmd_patch(src &Ticcmd_t, diff &Net_ticdiff_t, dest &Ticcmd_t) {
	unsafe {
		*dest = *src
	}
	if (diff.diff & net_ticdiff_forward) != 0 {
		dest.forwardmove = diff.cmd.forwardmove
	}
	if (diff.diff & net_ticdiff_side) != 0 {
		dest.sidemove = diff.cmd.sidemove
	}
	if (diff.diff & net_ticdiff_turn) != 0 {
		dest.angleturn = diff.cmd.angleturn
	}
	if (diff.diff & net_ticdiff_buttons) != 0 {
		dest.buttons = diff.cmd.buttons
	}
	if (diff.diff & net_ticdiff_consist) != 0 {
		dest.consistancy = diff.cmd.consistancy
	}
	if (diff.diff & net_ticdiff_chat) != 0 {
		dest.chatchar = diff.cmd.chatchar
	} else {
		dest.chatchar = 0
	}
	if (diff.diff & net_ticdiff_raven) != 0 {
		dest.lookfly = diff.cmd.lookfly
		dest.arti = diff.cmd.arti
	} else {
		dest.arti = 0
	}
	if (diff.diff & net_ticdiff_strife) != 0 {
		dest.buttons2 = diff.cmd.buttons2
		dest.inventory = diff.cmd.inventory
	} else {
		dest.inventory = 0
	}
}

@[export: 'NET_ReadFullTiccmd']
pub fn net_read_full_ticcmd(packet &Net_packet_t, cmd &Net_full_ticcmd_t, lowres_turn bool) bool {
	mut s := int(0)
	if !net_read_sint16(packet, &s) {
		return false
	}
	cmd.latency = s
	mut bitfield := u32(0)
	if !net_read_int8(packet, &bitfield) {
		return false
	}
	for i := 0; i < net_maxplayers; i++ {
		cmd.playeringame[i] = (bitfield & (u32(1) << i)) != 0
	}
	for i := 0; i < net_maxplayers; i++ {
		if cmd.playeringame[i] {
			if !net_read_ticcmd_diff(packet, &cmd.cmds[i], lowres_turn) {
				return false
			}
		}
	}
	return true
}

@[export: 'NET_WriteFullTiccmd']
pub fn net_write_full_ticcmd(packet &Net_packet_t, cmd &Net_full_ticcmd_t, lowres_turn bool) {
	net_write_int16(packet, u32(cmd.latency))
	mut bitfield := u32(0)
	for i := 0; i < net_maxplayers; i++ {
		if cmd.playeringame[i] {
			bitfield |= (u32(1) << i)
		}
	}
	net_write_int8(packet, bitfield)
	for i := 0; i < net_maxplayers; i++ {
		if cmd.playeringame[i] {
			net_write_ticcmd_diff(packet, &cmd.cmds[i], lowres_turn)
		}
	}
}

@[export: 'NET_WriteWaitData']
pub fn net_write_wait_data(packet &Net_packet_t, data &Net_waitdata_t) {
	net_write_int8(packet, u32(data.num_players))
	net_write_int8(packet, u32(data.num_drones))
	net_write_int8(packet, u32(data.ready_players))
	net_write_int8(packet, u32(data.max_players))
	net_write_int8(packet, u32(data.is_controller))
	net_write_int8(packet, u32(data.consoleplayer))
	for i := 0; i < data.num_players && i < net_maxplayers; i++ {
		net_write_string(packet, &data.player_names[i][0])
		net_write_string(packet, &data.player_addrs[i][0])
	}
	net_write_sha1_sum(packet, data.wad_sha1sum)
	net_write_sha1_sum(packet, data.deh_sha1sum)
	net_write_int8(packet, u32(data.is_freedoom))
}

@[export: 'NET_ReadWaitData']
pub fn net_read_wait_data(packet &Net_packet_t, data &Net_waitdata_t) bool {
	mut u := u32(0)
	mut s := int(0)
	if !net_read_int8(packet, &u) {
		return false
	}
	data.num_players = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	data.num_drones = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	data.ready_players = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	data.max_players = int(u)
	if !net_read_int8(packet, &u) {
		return false
	}
	data.is_controller = int(u)
	if !net_read_sint8(packet, &s) {
		return false
	}
	data.consoleplayer = s
	for i := 0; i < data.num_players && i < net_maxplayers; i++ {
		name := net_read_string(packet)
		if name == unsafe { nil } || C.strlen(name) >= maxplayername {
			return false
		}
		m_string_copy(&data.player_names[i][0], name, maxplayername)
		addr := net_read_string(packet)
		if addr == unsafe { nil } || C.strlen(addr) >= maxplayername {
			return false
		}
		m_string_copy(&data.player_addrs[i][0], addr, maxplayername)
	}
	if !net_read_sha1_sum(packet, mut data.wad_sha1sum) {
		return false
	}
	if !net_read_sha1_sum(packet, mut data.deh_sha1sum) {
		return false
	}
	if !net_read_int8(packet, &u) {
		return false
	}
	data.is_freedoom = int(u)
	return true
}

fn net_read_blob(packet &Net_packet_t, mut buf []u8) bool {
	mut b := u32(0)
	for i := 0; i < buf.len; i++ {
		if !net_read_int8(packet, &b) {
			return false
		}
		buf[i] = u8(b)
	}
	return true
}

fn net_write_blob(packet &Net_packet_t, buf []u8) {
	for b in buf {
		net_write_int8(packet, b)
	}
}

@[export: 'NET_ReadSHA1Sum']
pub fn net_read_sha1_sum(packet &Net_packet_t, mut digest Sha1_digest_t) bool {
	return net_read_blob(packet, mut digest[..])
}

@[export: 'NET_WriteSHA1Sum']
pub fn net_write_sha1_sum(packet &Net_packet_t, digest Sha1_digest_t) {
	net_write_blob(packet, digest[..])
}

@[export: 'NET_ReadPRNGSeed']
pub fn net_read_prng_seed(packet &Net_packet_t, mut seed Prng_seed_t) bool {
	return net_read_blob(packet, mut seed[..])
}

@[export: 'NET_WritePRNGSeed']
pub fn net_write_prng_seed(packet &Net_packet_t, seed Prng_seed_t) {
	net_write_blob(packet, seed[..])
}

fn parse_protocol_name(name &i8) Net_protocol_t {
	for entry in protocol_names {
		if cstring(entry.name) == cstring(name) {
			return entry.protocol
		}
	}
	return .net_protocol_unknown
}

@[export: 'NET_ReadProtocol']
pub fn net_read_protocol(packet &Net_packet_t) Net_protocol_t {
	name := net_read_string(packet)
	if name == unsafe { nil } {
		return .net_protocol_unknown
	}
	return parse_protocol_name(name)
}

@[export: 'NET_WriteProtocol']
pub fn net_write_protocol(packet &Net_packet_t, protocol Net_protocol_t) {
	for entry in protocol_names {
		if entry.protocol == protocol {
			net_write_string(packet, entry.name)
			return
		}
	}
	i_error(c'NET_WriteProtocol: protocol %d missing from protocol_names list; please add it.',
		int(protocol))
}

@[export: 'NET_ReadProtocolList']
pub fn net_read_protocol_list(packet &Net_packet_t) Net_protocol_t {
	mut num_protocols := u32(0)
	if !net_read_int8(packet, &num_protocols) {
		return .net_protocol_unknown
	}
	mut result := Net_protocol_t.net_protocol_unknown
	for _ in 0 .. int(num_protocols) {
		name := net_read_string(packet)
		if name == unsafe { nil } {
			return .net_protocol_unknown
		}
		p := parse_protocol_name(name)
		if p != .net_protocol_unknown {
			result = p
		}
	}
	return result
}

@[export: 'NET_WriteProtocolList']
pub fn net_write_protocol_list(packet &Net_packet_t) {
	net_write_int8(packet, u32(Net_protocol_t.net_num_protocols))
	for i := 0; i < int(Net_protocol_t.net_num_protocols); i++ {
		net_write_protocol(packet, Net_protocol_t(i))
	}
}
