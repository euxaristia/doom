@[translated]
module main

// Common networking hooks: minimal manual port.

__global (
	mut net_inited bool
)

@[export: 'NetUpdate']
pub fn net_update_export() {
	// No-op placeholder.
}

@[export: 'NET_Init']
pub fn net_init_export() {
	net_inited = true
}

@[export: 'NET_BindVariables']
pub fn net_bind_variables_export() {
	// No-op placeholder.
}

@[export: 'NET_LANQuery']
pub fn net_lan_query_export() {
	println('NET_LANQuery: not implemented in this port')
}

@[export: 'NET_MasterQuery']
pub fn net_master_query_export() {
	println('NET_MasterQuery: not implemented in this port')
}

@[export: 'NET_QueryAddress']
pub fn net_query_address_export(addr &i8) {
	println('NET_QueryAddress: ${cstring(addr)}')
}
