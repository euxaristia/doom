@[translated]
module main

// Querying servers to find their current status.

const master_server_address = c'master.chocolate-doom.org:2342'

@[weak]
__global (
	registered_with_master bool
	got_master_response    bool
	query_context          &Net_context_t
	net_sdl_module         Net_module_t
)

enum Query_target_type_t {
	query_target_server
	query_target_master
	query_target_broadcast
}

fn C.printf(&i8, ...int)
fn C.fprintf(voidptr, &i8, ...int)

@[c: 'stderr']
__global stderr voidptr

@[export: 'NET_Query_ResolveMaster']
pub fn net_query_resolve_master(context &Net_context_t) &Net_addr_t {
	addr := net_resolve_address(context, master_server_address)
	if addr == unsafe { nil } {
		C.fprintf(stderr, c'Warning: Failed to resolve address for master server: %s\n',
			master_server_address)
	}
	return addr
}

@[export: 'NET_Query_AddToMaster']
pub fn net_query_add_to_master(master_addr &Net_addr_t) {
	packet := net_new_packet(10)
	net_write_int16(packet, u32(Net_master_packet_type_t.net_master_packet_type_add))
	net_send_packet(master_addr, packet)
	net_free_packet(packet)
}

@[export: 'NET_Query_AddResponse']
pub fn net_query_add_response(packet &Net_packet_t) {
	mut result := u32(0)
	if !net_read_int16(packet, &result) {
		return
	}
	if result != 0 {
		if !registered_with_master {
			C.printf(c'Registered with master server at %s\n', master_server_address)
			registered_with_master = true
		}
	} else {
		C.printf(c'Failed to register with master server at %s\n', master_server_address)
	}
	got_master_response = true
}

@[export: 'NET_Query_CheckAddedToMaster']
pub fn net_query_check_added_to_master(result &bool) bool {
	if !got_master_response {
		return false
	}
	unsafe {
		*result = registered_with_master
	}
	return true
}

@[export: 'NET_RequestHolePunch']
pub fn net_request_hole_punch(context &Net_context_t, addr &Net_addr_t) {
	master_addr := net_query_resolve_master(context)
	if master_addr == unsafe { nil } {
		return
	}
	packet := net_new_packet(32)
	net_write_int16(packet, u32(Net_master_packet_type_t.net_master_packet_type_nat_hole_punch))
	net_write_string(packet, net_addr_to_string(addr))
	net_send_packet(master_addr, packet)
	net_free_packet(packet)
	net_release_address(master_addr)
}
