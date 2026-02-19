@[translated]
module main

// Network server support (first-pass translated scaffold).

@[weak]
__global (
	server_context &Net_context_t
	server_master  &Net_addr_t
)

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

@[export: 'NET_SV_Run']
pub fn net_sv_run() {
	// Keep master registration probe state flowing.
	if server_master != unsafe { nil } {
		mut addr := &Net_addr_t(unsafe { nil })
		mut packet := &Net_packet_t(unsafe { nil })
		if net_recv_packet(server_context, &addr, &packet) {
			if addr == server_master {
				net_query_add_response(packet)
			}
			net_release_address(addr)
			net_free_packet(packet)
		}
	}
}
