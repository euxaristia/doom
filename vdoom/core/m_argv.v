@[has_globals]
module core

import os

__global myargc = int(0)
__global myargv = []string{}

fn ensure_args() {
	if myargc > 0 || myargv.len > 0 {
		return
	}
	myargv = os.args.clone()
	myargc = myargv.len
}

pub fn m_check_parm(check string) int {
	return m_check_parm_with_args(check, 0)
}

pub fn m_check_parm_with_args(check string, num_args int) int {
	ensure_args()
	for i := 1; i < myargc - num_args; i++ {
		if myargv[i].to_lower() == check.to_lower() {
			return i
		}
	}
	return 0
}

pub fn m_parm_exists(check string) bool {
	return m_check_parm(check) != 0
}

pub fn m_find_response_file() {
}

pub fn m_add_loose_files() {
}

pub fn m_get_executable_name() string {
	ensure_args()
	if myargc == 0 {
		return ''
	}
	return os.base(myargv[0])
}

pub fn m_arg(idx int) string {
	ensure_args()
	if idx < 0 || idx >= myargv.len {
		return ''
	}
	return myargv[idx]
}

pub fn m_check_parm_value(flag string) ?string {
	idx := m_check_parm_with_args(flag, 1)
	if idx <= 0 {
		return none
	}
	return m_arg(idx + 1)
}
