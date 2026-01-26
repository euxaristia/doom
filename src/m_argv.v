@[translated]
module main

fn C.M_CheckParm(&char) int
fn C.M_CheckParmWithArgs(&char, int) int
fn C.M_ParmExists(&char) bool
fn C.M_FindResponseFile()
fn C.M_AddLooseFiles()
fn C.M_GetExecutableName() &char

fn m_check_parm(check &char) int {
	return C.M_CheckParm(check)
}

fn m_check_parm_with_args(check &char, num_args int) int {
	return C.M_CheckParmWithArgs(check, num_args)
}

fn m_parm_exists(check &char) bool {
	return C.M_ParmExists(check)
}

fn m_find_response_file() {
	C.M_FindResponseFile()
}

fn m_add_loose_files() {
	C.M_AddLooseFiles()
}

fn m_get_executable_name() &char {
	return C.M_GetExecutableName()
}
