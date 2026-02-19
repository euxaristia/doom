@[translated]
module main

// SDL networking module (minimal translated scaffold).

fn net_sdl_init_client() bool {
	return true
}

fn net_sdl_init_server() bool {
	return true
}

fn net_sdl_send_packet(_addr &Net_addr_t, _packet &Net_packet_t) {
	_ = _addr
	_ = _packet
}

fn net_sdl_recv_packet(_addr &&Net_addr_t, _packet &&Net_packet_t) bool {
	_ = _addr
	_ = _packet
	return false
}

fn net_sdl_addr_to_string(_addr &Net_addr_t, buffer &i8, buffer_len int) {
	_ = _addr
	m_snprintf(buffer, usize(buffer_len), c'sdl-unavailable')
}

fn net_sdl_free_address(_addr &Net_addr_t) {
	_ = _addr
}

fn net_sdl_resolve_address(_address &i8) &Net_addr_t {
	_ = _address
	return unsafe { nil }
}

@[weak]
__global (
	net_sdl_module = Net_module_t{
		initClient:     net_sdl_init_client
		initServer:     net_sdl_init_server
		sendPacket:     net_sdl_send_packet
		recvPacket:     net_sdl_recv_packet
		addrToString:   net_sdl_addr_to_string
		freeAddress:    net_sdl_free_address
		resolveAddress: net_sdl_resolve_address
	}
)
