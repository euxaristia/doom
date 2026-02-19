@[translated]
module main

// Network packet manipulation (net_packet_t).

fn C.memcpy(voidptr, voidptr, usize) voidptr
fn C.strlen(&i8) usize
fn C.isprint(int) int

@[c: 'M_StringCopy']
fn m_string_copy(dest &i8, src &i8, dest_size usize) bool

@[weak]
__global (
	total_packet_memory int
)

@[export: 'NET_NewPacket']
pub fn net_new_packet(initial_size int) &Net_packet_t {
	mut alloced := initial_size
	if alloced == 0 {
		alloced = 256
	}
	packet := &Net_packet_t(z_malloc(int(sizeof(Net_packet_t)), pu_static, unsafe { nil }))
	packet.alloced = usize(alloced)
	packet.data = &u8(z_malloc(alloced, pu_static, unsafe { nil }))
	packet.len = 0
	packet.pos = 0
	total_packet_memory += int(sizeof(Net_packet_t)) + alloced
	return packet
}

@[export: 'NET_PacketDup']
pub fn net_packet_dup(packet &Net_packet_t) &Net_packet_t {
	newpacket := net_new_packet(int(packet.len))
	C.memcpy(newpacket.data, packet.data, packet.len)
	newpacket.len = packet.len
	return newpacket
}

@[export: 'NET_FreePacket']
pub fn net_free_packet(packet &Net_packet_t) {
	if packet == unsafe { nil } {
		return
	}
	total_packet_memory -= int(sizeof(Net_packet_t)) + int(packet.alloced)
	z_free(packet.data)
	z_free(packet)
}

@[export: 'NET_ReadInt8']
pub fn net_read_int8(packet &Net_packet_t, data &u32) bool {
	if packet.pos + 1 > u32(packet.len) {
		return false
	}
	unsafe {
		*data = packet.data[packet.pos]
	}
	packet.pos += 1
	return true
}

@[export: 'NET_ReadInt16']
pub fn net_read_int16(packet &Net_packet_t, data &u32) bool {
	if packet.pos + 2 > u32(packet.len) {
		return false
	}
	p := unsafe { packet.data + packet.pos }
	unsafe {
		*data = (u32(p[0]) << 8) | u32(p[1])
	}
	packet.pos += 2
	return true
}

@[export: 'NET_ReadInt32']
pub fn net_read_int32(packet &Net_packet_t, data &u32) bool {
	if packet.pos + 4 > u32(packet.len) {
		return false
	}
	p := unsafe { packet.data + packet.pos }
	unsafe {
		*data = (u32(p[0]) << 24) | (u32(p[1]) << 16) | (u32(p[2]) << 8) | u32(p[3])
	}
	packet.pos += 4
	return true
}

@[export: 'NET_ReadSInt8']
pub fn net_read_sint8(packet &Net_packet_t, data &int) bool {
	mut u := u32(0)
	if !net_read_int8(packet, &u) {
		return false
	}
	mut s := int(u)
	if (s & (1 << 7)) != 0 {
		s &= ~(1 << 7)
		s -= (1 << 7)
	}
	unsafe {
		*data = s
	}
	return true
}

@[export: 'NET_ReadSInt16']
pub fn net_read_sint16(packet &Net_packet_t, data &int) bool {
	mut u := u32(0)
	if !net_read_int16(packet, &u) {
		return false
	}
	mut s := int(u)
	if (s & (1 << 15)) != 0 {
		s &= ~(1 << 15)
		s -= (1 << 15)
	}
	unsafe {
		*data = s
	}
	return true
}

@[export: 'NET_ReadSInt32']
pub fn net_read_sint32(packet &Net_packet_t, data &int) bool {
	mut u := u32(0)
	if !net_read_int32(packet, &u) {
		return false
	}
	mut s := int(u)
	if (u & (u32(1) << 31)) != 0 {
		s &= ~(1 << 31)
		s -= (1 << 31)
	}
	unsafe {
		*data = s
	}
	return true
}

@[export: 'NET_ReadString']
pub fn net_read_string(packet &Net_packet_t) &i8 {
	start := unsafe { &i8(packet.data + packet.pos) }
	for packet.pos < u32(packet.len) && unsafe { packet.data[packet.pos] } != 0 {
		packet.pos++
	}
	if packet.pos >= u32(packet.len) {
		return unsafe { nil }
	}
	packet.pos++
	return start
}

@[export: 'NET_ReadSafeString']
pub fn net_read_safe_string(packet &Net_packet_t) &i8 {
	result := net_read_string(packet)
	if result == unsafe { nil } {
		return unsafe { nil }
	}
	mut r := result
	mut w := result
	for unsafe { *r } != 0 {
		ch := unsafe { *r }
		if C.isprint(ch) != 0 || ch == `\n` {
			unsafe {
				*w = ch
			}
			w = unsafe { w + 1 }
		}
		r = unsafe { r + 1 }
	}
	unsafe {
		*w = 0
	}
	return result
}

fn net_increase_packet(packet &Net_packet_t) {
	total_packet_memory -= int(packet.alloced)
	packet.alloced *= 2
	newdata := &u8(z_malloc(int(packet.alloced), pu_static, unsafe { nil }))
	C.memcpy(newdata, packet.data, packet.len)
	z_free(packet.data)
	packet.data = newdata
	total_packet_memory += int(packet.alloced)
}

@[export: 'NET_WriteInt8']
pub fn net_write_int8(packet &Net_packet_t, i u32) {
	if packet.len + 1 > packet.alloced {
		net_increase_packet(packet)
	}
	unsafe {
		packet.data[packet.len] = u8(i)
	}
	packet.len += 1
}

@[export: 'NET_WriteInt16']
pub fn net_write_int16(packet &Net_packet_t, i u32) {
	if packet.len + 2 > packet.alloced {
		net_increase_packet(packet)
	}
	p := unsafe { packet.data + packet.len }
	unsafe {
		p[0] = u8((i >> 8) & 0xff)
		p[1] = u8(i & 0xff)
	}
	packet.len += 2
}

@[export: 'NET_WriteInt32']
pub fn net_write_int32(packet &Net_packet_t, i u32) {
	if packet.len + 4 > packet.alloced {
		net_increase_packet(packet)
	}
	p := unsafe { packet.data + packet.len }
	unsafe {
		p[0] = u8((i >> 24) & 0xff)
		p[1] = u8((i >> 16) & 0xff)
		p[2] = u8((i >> 8) & 0xff)
		p[3] = u8(i & 0xff)
	}
	packet.len += 4
}

@[export: 'NET_WriteString']
pub fn net_write_string(packet &Net_packet_t, string_ &i8) {
	string_size := C.strlen(string_) + 1
	for packet.len + string_size > packet.alloced {
		net_increase_packet(packet)
	}
	p := unsafe { &i8(packet.data + packet.len) }
	m_string_copy(p, string_, string_size)
	packet.len += string_size
}
