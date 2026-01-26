@[translated]
module main

fn C.M_FileExists(&char) bool
fn C.M_ReadFile(&char) voidptr
fn C.M_WriteFile(&char, voidptr, int) bool
fn C.M_MakeDirectory(&char) bool
fn C.M_StringDuplicate(&char) &char
fn C.M_StringCopy(&char, &char, int) bool
fn C.M_StringConcat(&char, &char, int) bool
fn C.M_BaseName(&char) &char
fn C.M_DirName(&char) &char
fn C.M_ForceUppercase(&char)
fn C.M_ForceLowercase(&char)
fn C.M_StringEndsWith(&char, &char) bool

fn m_file_exists(filename &char) bool {
	return C.M_FileExists(filename)
}

fn m_read_file(filename &char) voidptr {
	return C.M_ReadFile(filename)
}

fn m_write_file(filename &char, buffer voidptr, length int) bool {
	return C.M_WriteFile(filename, buffer, length)
}

fn m_make_directory(dir &char) bool {
	return C.M_MakeDirectory(dir)
}

fn m_string_duplicate(str &char) &char {
	return C.M_StringDuplicate(str)
}

fn m_string_copy(dst &char, src &char, size int) bool {
	return C.M_StringCopy(dst, src, size)
}

fn m_string_concat(dst &char, src &char, size int) bool {
	return C.M_StringConcat(dst, src, size)
}

fn m_base_name(path &char) &char {
	return C.M_BaseName(path)
}

fn m_dir_name(path &char) &char {
	return C.M_DirName(path)
}

fn m_force_uppercase(str &char) {
	C.M_ForceUppercase(str)
}

fn m_force_lowercase(str &char) {
	C.M_ForceLowercase(str)
}

fn m_string_ends_with(str &char, suffix &char) bool {
	return C.M_StringEndsWith(str, suffix)
}
