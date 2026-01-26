@[translated]
module main

import math.sdl2 { SDL_qsort }

// Global command-line argument storage
mut myargc int = 0
mut myargv []&char = []&char{}

// M_CheckParmWithArgs
// Checks for the given parameter in the program's command line arguments.
// Returns the argument number (1 to argc-1) or 0 if not present.
fn m_check_parm_with_args(check &char, num_args int) int {
	for i := 1; i < myargc - num_args; i++ {
		if C.strcasecmp(check, myargv[i]) == 0 {
			return i
		}
	}
	return 0
}

// M_CheckParm
fn m_check_parm(check &char) int {
	return m_check_parm_with_args(check, 0)
}

// M_ParmExists
// Returns true if the given parameter exists in the program's command
// line arguments, false if not.
fn m_parm_exists(check &char) bool {
	return m_check_parm(check) != 0
}

const maxargvs = 100

// LoadResponseFile
fn load_response_file(argv_index int, filename &char) {
	// Read the response file into memory
	handle := C.fopen(filename, c'rb')

	if handle == unsafe { nil } {
		C.printf(c'\nNo such response file!')
		C.exit(1)
	}

	C.printf(c'Found response file %s!\n', filename)

	size := m_file_length(handle)

	// Read in the entire file
	// Allocate one byte extra - this is in case there is an argument
	// at the end of the response file, in which case a '\0' will be needed.
	file := unsafe { C.malloc(size + 1) }

	mut i := 0
	for i < size {
		k := C.fread(unsafe { file + i }, 1, size - i, handle)

		if k < 0 {
			i_error(c'Failed to read full contents of \'%s\'', filename)
		}

		i += int(k)
	}

	C.fclose(handle)

	// Create new arguments list array
	newargv := unsafe { C.malloc(sizeof(charptr) * maxargvs) }
	mut newargc := 0
	C.memset(newargv, 0, sizeof(charptr) * maxargvs)

	// Copy all the arguments in the list up to the response file
	for j := 0; j < argv_index; j++ {
		unsafe { (newargv as []&char)[j] = myargv[j] }
		newargc++
	}

	mut infile := file
	mut k := 0

	for k < size {
		// Skip past space characters to the next argument
		for k < size && C.isspace(int(unsafe { infile[k] })) != 0 {
			k++
		}

		if k >= size {
			break
		}

		// If the next argument is enclosed in quote marks, treat
		// the contents as a single argument. This allows long filenames
		// to be specified.
		if unsafe { infile[k] } == u8(`"`) {
			// Skip the first character (")
			k++

			unsafe { (newargv as []&char)[newargc] = infile + k }
			newargc++

			// Read all characters between quotes
			for k < size && unsafe { infile[k] } != u8(`"`) && unsafe { infile[k] } != u8(`\n`) {
				k++
			}

			if k >= size || unsafe { infile[k] } == u8(`\n`) {
				i_error(c'Quotes unclosed in response file \'%s\'', filename)
			}

			// Cut off the string at the closing quote
			unsafe { infile[k] = 0 }
			k++
		} else {
			// Read in the next argument until a space is reached
			unsafe { (newargv as []&char)[newargc] = infile + k }
			newargc++

			for k < size && C.isspace(int(unsafe { infile[k] })) == 0 {
				k++
			}

			// Cut off the end of the argument at the first space
			unsafe { infile[k] = 0 }
			k++
		}
	}

	// Add arguments following the response file argument
	for j := argv_index + 1; j < myargc; j++ {
		unsafe { (newargv as []&char)[newargc] = myargv[j] }
		newargc++
	}

	myargv = unsafe { (newargv as []&char) }
	myargc = newargc
}

// M_FindResponseFile
// Find and load response files (arguments prefixed with @)
fn m_find_response_file() {
	for i := 1; i < myargc; i++ {
		if myargv[i][0] == u8(`@`) {
			load_response_file(i, myargv[i] + 1)
		}
	}

	for {
		i := m_check_parm_with_args(c'-response', 1)
		if i <= 0 {
			break
		}
		// Replace the -response argument so that the next time through
		// the loop we'll ignore it.
		myargv[i] = c'-_'
		load_response_file(i + 1, myargv[i + 1])
	}
}

// Windows-specific code for handling loose file arguments
$if windows {
	enum FileType {
		filetype_unknown = 0x0
		filetype_iwad = 0x2
		filetype_pwad = 0x4
		filetype_deh = 0x8
	}

	struct ArgumentT {
		str &char
		file_type int
		stable int
	}

	fn guess_file_type(name &char) int {
		mut ret := filetype_unknown

		base := m_base_name(name)
		lower := m_string_duplicate(base)
		m_force_lowercase(lower)

		// Static flag to only add one IWAD
		static mut iwad_found := false

		// Check if it's an IWAD
		if !iwad_found && d_is_iwad_name(lower) {
			ret = filetype_iwad
			iwad_found = true
		} else if m_string_ends_with(lower, c'.wad') || m_string_ends_with(lower, c'.lmp') {
			ret = filetype_pwad
		} else if m_string_ends_with(lower, c'.deh') ||
		          m_string_ends_with(lower, c'.hhe') ||
		          m_string_ends_with(lower, c'.seh') {
			ret = filetype_deh
		}

		C.free(lower)
		return ret
	}

	fn compare_by_file_type(a voidptr, b voidptr) int {
		arg_a := unsafe { (a as &ArgumentT) }
		arg_b := unsafe { (b as &ArgumentT) }

		ret := arg_a.file_type - arg_b.file_type
		if ret != 0 {
			return ret
		}
		return arg_a.stable - arg_b.stable
	}

	fn m_add_loose_files() {
		if myargc < 2 {
			return
		}

		// Allocate space for arguments
		arguments := unsafe { C.malloc((myargc + 3) * sizeof(ArgumentT)) }
		C.memset(arguments, 0, (myargc + 3) * sizeof(ArgumentT))

		mut types := 0

		// Check the command line and make sure it does not already
		// contain any regular parameters or response files
		for i := 1; i < myargc; i++ {
			arg := myargv[i]

			arg_len := int(C.strlen(arg))
			if arg_len < 3 ||
				arg[0] == u8(`-`) ||
				arg[0] == u8(`@`) ||
				((!C.isalpha(int(arg[0])) || arg[1] != u8(`:`) || arg[2] != u8(`\\`)) &&
				(arg[0] != u8(`\\`) || arg[1] != u8(`\\`))) {
				C.free(arguments)
				return
			}

			file_type := guess_file_type(arg)
			args_array := unsafe { (arguments as []ArgumentT) }
			args_array[i].str = arg
			args_array[i].file_type = file_type
			args_array[i].stable = i
			types |= file_type
		}

		// Add space for additional parameters and sort them
		if types & filetype_iwad != 0 {
			args_array := unsafe { (arguments as []ArgumentT) }
			args_array[myargc].str = m_string_duplicate(c'-iwad')
			args_array[myargc].file_type = filetype_iwad - 1
			myargc++
		}
		if types & filetype_pwad != 0 {
			args_array := unsafe { (arguments as []ArgumentT) }
			args_array[myargc].str = m_string_duplicate(c'-merge')
			args_array[myargc].file_type = filetype_pwad - 1
			myargc++
		}
		if types & filetype_deh != 0 {
			args_array := unsafe { (arguments as []ArgumentT) }
			args_array[myargc].str = m_string_duplicate(c'-deh')
			args_array[myargc].file_type = filetype_deh - 1
			myargc++
		}

		newargv := unsafe { C.malloc(myargc * sizeof(charptr)) }

		// Sort the argument list by file type
		args_array := unsafe { (arguments as []ArgumentT) }
		SDL_qsort(unsafe { arguments + sizeof(ArgumentT) }, myargc - 1, sizeof(ArgumentT), compare_by_file_type)

		newargv_array := unsafe { (newargv as []&char) }
		newargv_array[0] = myargv[0]

		for i := 1; i < myargc; i++ {
			newargv_array[i] = args_array[i].str
		}

		C.free(arguments)
		myargv = newargv_array
	}
}

// M_GetExecutableName
// Return the name of the executable used to start the program
fn m_get_executable_name() &char {
	return m_base_name(myargv[0])
}

// Forward declarations for C functions we depend on
fn m_file_length(handle voidptr) int
fn i_error(fmt &char, ...)
fn m_base_name(path &char) &char
fn m_string_duplicate(orig &char) &char
fn m_force_lowercase(text &char)
fn m_string_ends_with(str &char, suffix &char) bool
fn d_is_iwad_name(name &char) bool
