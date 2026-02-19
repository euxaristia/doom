@[translated]
module main

// Dedicated server entry points.

const package_name = 'Chocolate Doom'

pub fn net_cl_run_dedicated_noop() {
	// No client present in a standalone dedicated server.
}

@[export: 'D_DoomMain']
pub fn d_doom_main() {
	println('${package_name} standalone dedicated server')
	z_init()
	net_dedicated_server()
}
