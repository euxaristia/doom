@[translated]
module main

// Dedicated server code.

@[c: 'I_Error']
@[c2v_variadic]
fn i_error(error &i8, ...)

@[c: 'NET_OpenLog']
fn net_open_log()

@[c: 'NET_SV_Init']
fn net_sv_init()

@[c: 'NET_SV_AddModule']
fn net_sv_add_module(module_ &Net_module_t)

@[c: 'NET_SV_RegisterWithMaster']
fn net_sv_register_with_master()

@[c: 'NET_SV_Run']
fn net_sv_run()

@[weak]
__global (
	net_sdl_module Net_module_t
)

const not_dedicated_options = [
	c'-deh',
	c'-iwad',
	c'-cdrom',
	c'-gameversion',
	c'-nomonsters',
	c'-respawn',
	c'-fast',
	c'-altdeath',
	c'-deathmatch',
	c'-turbo',
	c'-merge',
	c'-af',
	c'-as',
	c'-aa',
	c'-file',
	c'-wart',
	c'-skill',
	c'-episode',
	c'-timer',
	c'-avg',
	c'-warp',
	c'-loadgame',
	c'-longtics',
	c'-extratics',
	c'-dup',
	c'-shorttics',
]

fn check_for_client_options() {
	for opt in not_dedicated_options {
		if m_check_parm(opt) > 0 {
			i_error(c"The command line parameter '%s' was specified to a dedicated server.\nGame parameters should be specified to the first player to join a server, \nnot to the server itself. ",
				opt)
		}
	}
}

@[export: 'NET_DedicatedServer']
pub fn net_dedicated_server() {
	check_for_client_options()
	net_open_log()
	net_sv_init()
	net_sv_add_module(&net_sdl_module)
	net_sv_register_with_master()
	for {
		net_sv_run()
		// TODO: Block on socket instead of polling.
		i_sleep(1)
	}
}
