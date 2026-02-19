@[translated]
module main

// Loopback network module for server compiled into the client.

const max_queue_size = 16

struct Packet_queue_t {
mut:
	packets [max_queue_size]&Net_packet_t
	head    int
	tail    int
}

@[c: 'I_Error']
@[c2v_variadic]
fn i_error(error &i8, ...)

@[c: 'NET_PacketDup']
fn net_packet_dup(packet &Net_packet_t) &Net_packet_t

@[c: 'M_snprintf']
@[c2v_variadic]
fn m_snprintf(buf &i8, buf_len usize, s &i8, ...) int

@[weak]
__global (
	client_queue           = Packet_queue_t{}
	server_queue           = Packet_queue_t{}
	client_addr            Net_addr_t
	server_addr            Net_addr_t
	net_loop_client_module = Net_module_t{
		initClient:     net_cl_init_client
		initServer:     net_cl_init_server
		sendPacket:     net_cl_send_packet
		recvPacket:     net_cl_recv_packet
		addrToString:   net_cl_addr_to_string
		freeAddress:    net_cl_free_address
		resolveAddress: net_cl_resolve_address
	}
	net_loop_server_module = Net_module_t{
		initClient:     net_sv_init_client
		initServer:     net_sv_init_server
		sendPacket:     net_sv_send_packet
		recvPacket:     net_sv_recv_packet
		addrToString:   net_sv_addr_to_string
		freeAddress:    net_sv_free_address
		resolveAddress: net_sv_resolve_address
	}
)

fn queue_init(mut queue Packet_queue_t) {
	queue.head = 0
	queue.tail = 0
}

fn queue_push(mut queue Packet_queue_t, packet &Net_packet_t) {
	new_tail := (queue.tail + 1) % max_queue_size
	if new_tail == queue.head {
		// Queue is full.
		return
	}
	queue.packets[queue.tail] = packet
	queue.tail = new_tail
}

fn queue_pop(mut queue Packet_queue_t) &Net_packet_t {
	if queue.tail == queue.head {
		// Queue is empty.
		return unsafe { nil }
	}
	packet := queue.packets[queue.head]
	queue.head = (queue.head + 1) % max_queue_size
	return packet
}

fn net_cl_init_client() bool {
	queue_init(mut client_queue)
	return true
}

fn net_cl_init_server() bool {
	i_error(c'NET_CL_InitServer: attempted to initialize client pipe end as a server!')
	return false
}

fn net_cl_send_packet(_addr &Net_addr_t, packet &Net_packet_t) {
	_ = _addr
	queue_push(mut server_queue, net_packet_dup(packet))
}

fn net_cl_recv_packet(addr &&Net_addr_t, packet &&Net_packet_t) bool {
	popped := queue_pop(mut client_queue)
	if popped != unsafe { nil } {
		*packet = popped
		*addr = &client_addr
		client_addr.module_ = &net_loop_client_module
		return true
	}
	return false
}

fn net_cl_addr_to_string(_addr &Net_addr_t, buffer &i8, buffer_len int) {
	_ = _addr
	m_snprintf(buffer, usize(buffer_len), c'local server')
}

fn net_cl_free_address(_addr &Net_addr_t) {
	_ = _addr
}

fn net_cl_resolve_address(address &i8) &Net_addr_t {
	if address == unsafe { nil } {
		client_addr.module_ = &net_loop_client_module
		return &client_addr
	}
	return unsafe { nil }
}

fn net_sv_init_client() bool {
	i_error(c'NET_SV_InitClient: attempted to initialize server pipe end as a client!')
	return false
}

fn net_sv_init_server() bool {
	queue_init(mut server_queue)
	return true
}

fn net_sv_send_packet(_addr &Net_addr_t, packet &Net_packet_t) {
	_ = _addr
	queue_push(mut client_queue, net_packet_dup(packet))
}

fn net_sv_recv_packet(addr &&Net_addr_t, packet &&Net_packet_t) bool {
	popped := queue_pop(mut server_queue)
	if popped != unsafe { nil } {
		*packet = popped
		*addr = &server_addr
		server_addr.module_ = &net_loop_server_module
		return true
	}
	return false
}

fn net_sv_addr_to_string(_addr &Net_addr_t, buffer &i8, buffer_len int) {
	_ = _addr
	m_snprintf(buffer, usize(buffer_len), c'local client')
}

fn net_sv_free_address(_addr &Net_addr_t) {
	_ = _addr
}

fn net_sv_resolve_address(address &i8) &Net_addr_t {
	if address == unsafe { nil } {
		server_addr.module_ = &net_loop_server_module
		return &server_addr
	}
	return unsafe { nil }
}
