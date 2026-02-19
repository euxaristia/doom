@[translated]
module main

// Network packet I/O. Base layer for sending/receiving packets
// through the network module system.

const max_modules = 16

type Net_context_t = Net_context_s

struct Net_context_s {
mut:
	modules     [max_modules]&Net_module_t
	num_modules int
}

@[c: 'I_Error']
@[c2v_variadic]
fn i_error(error &i8, ...)

@[weak]
__global (
	net_broadcast_addr  Net_addr_t
	net_addr_string_buf [128]i8
)

@[export: 'NET_NewContext']
pub fn net_new_context() &Net_context_t {
	return &Net_context_t{}
}

@[export: 'NET_AddModule']
pub fn net_add_module(context &Net_context_t, module_ &Net_module_t) {
	if context == unsafe { nil } {
		return
	}
	if context.num_modules >= max_modules {
		i_error(c'NET_AddModule: No more modules for context')
	}
	context.modules[context.num_modules] = module_
	context.num_modules++
}

@[export: 'NET_ResolveAddress']
pub fn net_resolve_address(context &Net_context_t, addr &i8) &Net_addr_t {
	if context == unsafe { nil } {
		return unsafe { nil }
	}
	for i := 0; i < context.num_modules; i++ {
		result := context.modules[i].resolveAddress(addr)
		if result != unsafe { nil } {
			net_reference_address(result)
			return result
		}
	}
	return unsafe { nil }
}

@[export: 'NET_SendPacket']
pub fn net_send_packet(addr &Net_addr_t, packet &Net_packet_t) {
	if addr == unsafe { nil } || packet == unsafe { nil } {
		return
	}
	addr.module_.sendPacket(addr, packet)
}

@[export: 'NET_SendBroadcast']
pub fn net_send_broadcast(context &Net_context_t, packet &Net_packet_t) {
	if context == unsafe { nil } || packet == unsafe { nil } {
		return
	}
	for i := 0; i < context.num_modules; i++ {
		context.modules[i].sendPacket(&net_broadcast_addr, packet)
	}
}

@[export: 'NET_RecvPacket']
pub fn net_recv_packet(context &Net_context_t, addr &&Net_addr_t, packet &&Net_packet_t) bool {
	if context == unsafe { nil } {
		return false
	}
	for i := 0; i < context.num_modules; i++ {
		if context.modules[i].recvPacket(addr, packet) {
			net_reference_address(*addr)
			return true
		}
	}
	return false
}

@[export: 'NET_AddrToString']
pub fn net_addr_to_string(addr &Net_addr_t) &i8 {
	if addr == unsafe { nil } {
		net_addr_string_buf[0] = 0
		return &net_addr_string_buf[0]
	}
	addr.module_.addrToString(addr, &net_addr_string_buf[0], net_addr_string_buf.len - 1)
	return &net_addr_string_buf[0]
}

@[export: 'NET_ReferenceAddress']
pub fn net_reference_address(addr &Net_addr_t) {
	if addr == unsafe { nil } {
		return
	}
	addr.refcount++
}

@[export: 'NET_ReleaseAddress']
pub fn net_release_address(addr &Net_addr_t) {
	if addr == unsafe { nil } {
		return
	}
	addr.refcount--
	if addr.refcount <= 0 {
		addr.module_.freeAddress(addr)
	}
}
