@[translated]
module main

// Querying servers to find their current status.

const master_server_address = c'master.chocolate-doom.org:2342'
const query_timeout_secs = 2
const query_max_attempts = 3

@[weak]
__global (
	registered_with_master bool
	got_master_response    bool
	query_context          &Net_context_t
	query_targets          []Query_target_t
	num_targets            int
	query_loop_running     bool
	printed_header         bool
	last_query_time        int
	securedemo_start_msg   &i8
	net_sdl_module         Net_module_t
)

enum Query_target_type_t {
	query_target_server
	query_target_master
	query_target_broadcast
}

enum Query_target_state_t {
	query_target_queued
	query_target_queried
	query_target_responded
	query_target_no_response
}

struct Query_target_t {
mut:
	type_          Query_target_type_t
	state          Query_target_state_t
	addr           &Net_addr_t
	data           Net_querydata_t
	ping_time      u32
	query_time     u32
	query_attempts u32
	printed        bool
}

fn C.printf(&i8, ...int)
fn C.fprintf(voidptr, &i8, ...int)
fn C.free(voidptr)

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

fn find_target_index(addr &Net_addr_t) int {
	for i, t in query_targets {
		if t.addr == addr {
			return i
		}
	}
	return -1
}

fn get_target_index_for_addr(addr &Net_addr_t, create bool) int {
	idx := find_target_index(addr)
	if idx >= 0 || !create {
		return idx
	}
	mut t := Query_target_t{}
	t.type_ = .query_target_server
	t.state = .query_target_queued
	t.addr = addr
	t.query_attempts = 0
	t.printed = false
	if addr != unsafe { nil } {
		net_reference_address(addr)
	}
	query_targets << t
	num_targets = query_targets.len
	return query_targets.len - 1
}

fn free_targets() {
	for t in query_targets {
		if t.addr != unsafe { nil } {
			net_release_address(t.addr)
		}
	}
	query_targets = []Query_target_t{}
	num_targets = 0
}

@[export: 'NET_Query_Init']
pub fn net_query_init() {
	if query_context == unsafe { nil } {
		query_context = net_new_context()
		net_add_module(query_context, &net_sdl_module)
		net_sdl_module.initClient()
	}
	free_targets()
	printed_header = false
}

@[export: 'NET_StartLANQuery']
pub fn net_start_lan_query() int {
	net_query_init()
	idx := get_target_index_for_addr(unsafe { nil }, true)
	if idx < 0 {
		return 0
	}
	query_targets[idx].type_ = .query_target_broadcast
	return 1
}

@[export: 'NET_StartMasterQuery']
pub fn net_start_master_query() int {
	net_query_init()
	master := net_query_resolve_master(query_context)
	if master == unsafe { nil } {
		return 0
	}
	idx := get_target_index_for_addr(master, true)
	if idx >= 0 {
		query_targets[idx].type_ = .query_target_master
	}
	net_release_address(master)
	return if idx >= 0 { 1 } else { 0 }
}

fn net_query_send_master_query(addr &Net_addr_t) {
	mut packet := net_new_packet(4)
	net_write_int16(packet, u32(Net_master_packet_type_t.net_master_packet_type_query))
	net_send_packet(addr, packet)
	net_free_packet(packet)
	packet = net_new_packet(4)
	net_write_int16(packet, u32(Net_master_packet_type_t.net_master_packet_type_nat_hole_punch_all))
	net_send_packet(addr, packet)
	net_free_packet(packet)
}

fn net_query_send_query(addr &Net_addr_t) {
	request := net_new_packet(10)
	net_write_int16(request, u32(Net_packet_type_t.net_packet_type_query))
	if addr == unsafe { nil } {
		net_send_broadcast(query_context, request)
	} else {
		net_send_packet(addr, request)
	}
	net_free_packet(request)
}

fn net_query_parse_response(addr &Net_addr_t, packet &Net_packet_t, callback Net_query_callback_t, user_data voidptr) {
	mut packet_type := u32(0)
	if !net_read_int16(packet, &packet_type)
		|| packet_type != u32(Net_packet_type_t.net_packet_type_query_response) {
		return
	}
	mut querydata := Net_querydata_t{}
	if !net_read_query_data(packet, &querydata) {
		return
	}
	mut idx := get_target_index_for_addr(addr, false)
	if idx < 0 {
		bcast_idx := get_target_index_for_addr(unsafe { nil }, false)
		if bcast_idx < 0 || query_targets[bcast_idx].state != .query_target_queried {
			return
		}
		idx = get_target_index_for_addr(addr, true)
		if idx < 0 {
			return
		}
		query_targets[idx].state = .query_target_queried
		query_targets[idx].query_time = query_targets[bcast_idx].query_time
	}
	if query_targets[idx].state != .query_target_responded {
		query_targets[idx].state = .query_target_responded
		query_targets[idx].data = querydata
		query_targets[idx].ping_time = u32(i_get_time_ms()) - query_targets[idx].query_time
		callback(addr, &query_targets[idx].data, query_targets[idx].ping_time, user_data)
	}
}

fn net_query_parse_master_response(master_addr &Net_addr_t, packet &Net_packet_t) {
	mut packet_type := u32(0)
	if !net_read_int16(packet, &packet_type)
		|| packet_type != u32(Net_master_packet_type_t.net_master_packet_type_query_response) {
		return
	}
	for {
		addr_str := net_read_string(packet)
		if addr_str == unsafe { nil } {
			break
		}
		addr := net_resolve_address(query_context, addr_str)
		if addr != unsafe { nil } {
			_ = get_target_index_for_addr(addr, true)
			net_release_address(addr)
		}
	}
	idx := get_target_index_for_addr(master_addr, true)
	if idx >= 0 {
		query_targets[idx].state = .query_target_responded
	}
}

fn net_query_parse_packet(addr &Net_addr_t, packet &Net_packet_t, callback Net_query_callback_t, user_data voidptr) {
	idx := get_target_index_for_addr(addr, false)
	if idx >= 0 && query_targets[idx].type_ == .query_target_master {
		net_query_parse_master_response(addr, packet)
	} else {
		net_query_parse_response(addr, packet, callback, user_data)
	}
}

fn net_query_get_response(callback Net_query_callback_t, user_data voidptr) {
	mut addr := &Net_addr_t(unsafe { nil })
	mut packet := &Net_packet_t(unsafe { nil })
	if net_recv_packet(query_context, &addr, &packet) {
		net_query_parse_packet(addr, packet, callback, user_data)
		net_release_address(addr)
		net_free_packet(packet)
	}
}

fn send_one_query() {
	now := u32(i_get_time_ms())
	if now - u32(last_query_time) < 50 {
		return
	}
	mut idx := -1
	for i, t in query_targets {
		if t.state == .query_target_queued || (t.state == .query_target_queried
			&& now - t.query_time > u32(query_timeout_secs * 1000)) {
			idx = i
			break
		}
	}
	if idx < 0 {
		return
	}
	match query_targets[idx].type_ {
		.query_target_server { net_query_send_query(query_targets[idx].addr) }
		.query_target_broadcast { net_query_send_query(unsafe { nil }) }
		.query_target_master { net_query_send_master_query(query_targets[idx].addr) }
	}
	query_targets[idx].state = .query_target_queried
	query_targets[idx].query_time = now
	query_targets[idx].query_attempts++
	last_query_time = int(now)
}

fn check_target_timeouts() {
	now := u32(i_get_time_ms())
	for i, t in query_targets {
		if t.state == .query_target_queried && t.query_attempts >= query_max_attempts
			&& now - t.query_time > u32(query_timeout_secs * 1000) {
			query_targets[i].state = .query_target_no_response
			if t.type_ == .query_target_master {
				C.fprintf(stderr, c'NET_MasterQuery: no response from master server.\n')
			}
		}
	}
}

fn all_targets_done() bool {
	for t in query_targets {
		if t.state != .query_target_responded && t.state != .query_target_no_response {
			return false
		}
	}
	return true
}

@[export: 'NET_Query_Poll']
pub fn net_query_poll(callback Net_query_callback_t, user_data voidptr) int {
	check_target_timeouts()
	send_one_query()
	net_query_get_response(callback, user_data)
	return if all_targets_done() { 0 } else { 1 }
}
