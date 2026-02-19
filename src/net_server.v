@[translated]
module main

// Network server support (first-pass translated scaffold).

@[weak]
__global (
	server_context      &Net_context_t
	server_master       &Net_addr_t
	server_state        int
	last_master_refresh int
)

const master_refresh_period_secs = 30

@[export: 'NET_SV_Init']
pub fn net_sv_init() {
	if server_context == unsafe { nil } {
		server_context = net_new_context()
	}
}

@[export: 'NET_SV_AddModule']
pub fn net_sv_add_module(module_ &Net_module_t) {
	if server_context == unsafe { nil } {
		net_sv_init()
	}
	net_add_module(server_context, module_)
	module_.initServer()
}

@[export: 'NET_SV_RegisterWithMaster']
pub fn net_sv_register_with_master() {
	if server_context == unsafe { nil } {
		return
	}
	if server_master != unsafe { nil } {
		net_release_address(server_master)
		server_master = unsafe { nil }
	}
	server_master = net_query_resolve_master(server_context)
	if server_master != unsafe { nil } {
		net_query_add_to_master(server_master)
	}
}

@[export: 'NET_SV_SendQueryResponse']
pub fn net_sv_send_query_response(addr &Net_addr_t) {
	if server_context == unsafe { nil } {
		return
	}
	mut query := Net_querydata_t{}
	query.version = c'vdoom'
	query.server_state = server_state
	query.num_players = 0
	query.max_players = 8
	query.gamemode = int(GameMode_t.indetermined)
	query.gamemission = int(GameMission_t.none_)
	query.description = c'V DOOM server'
	query.protocol = .net_protocol_chocolate_doom_0
	packet := net_new_packet(96)
	net_write_int16(packet, u32(Net_packet_type_t.net_packet_type_query_response))
	net_write_query_data(packet, &query)
	net_send_packet(addr, packet)
	net_free_packet(packet)
}

@[export: 'NET_SV_Run']
pub fn net_sv_run() {
	if server_context == unsafe { nil } {
		return
	}
	// Keep master registration alive.
	now := i_get_time_ms()
	if server_master != unsafe { nil }
		&& (now - last_master_refresh) > (master_refresh_period_secs * 1000) {
		net_query_add_to_master(server_master)
		last_master_refresh = now
	}
	for {
		mut addr := &Net_addr_t(unsafe { nil })
		mut packet := &Net_packet_t(unsafe { nil })
		if !net_recv_packet(server_context, &addr, &packet) {
			break
		}
		if addr == server_master {
			net_query_add_response(packet)
		} else {
			mut packet_type := u32(0)
			if net_read_int16(packet, &packet_type)
				&& packet_type == u32(Net_packet_type_t.net_packet_type_query) {
				net_sv_send_query_response(addr)
			}
		}
		net_release_address(addr)
		net_free_packet(packet)
	}
}

@[export: 'NET_SV_Shutdown']
pub fn net_sv_shutdown() {
	if server_master != unsafe { nil } {
		net_release_address(server_master)
		server_master = unsafe { nil }
	}
	server_context = unsafe { nil }
	server_state = 0
}
