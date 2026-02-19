@[translated]
module main

// Common networking hooks: minimal manual port.

@[weak]
__global (
	net_inited bool
)

@[export: 'NetUpdate']
pub fn net_update_export() {
	// No-op placeholder.
}

@[export: 'NET_Init']
pub fn net_init_export() {
	net_inited = true
}

@[export: 'NET_OpenLog']
pub fn net_open_log() {
	// Minimal port: keep hook present; file logging can be added later.
}

@[export: 'NET_BindVariables']
pub fn net_bind_variables_export() {
	// No-op placeholder.
}
