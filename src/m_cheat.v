// Copyright(C) 1993-1996 Id Software, Inc.
// Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// DESCRIPTION:
// Cheat sequence checking.

const (
	max_cheat_len    = 25
	max_cheat_params = 5
)

// Cheat sequence structure
pub struct CheatSeq {
pub mut:
	// Cheat definition
	sequence           string
	sequence_len       int
	parameter_chars    int

	// State during gameplay
	chars_read         int
	param_chars_read   int
	parameter_buf      [max_cheat_params]u8
}

// Initialize a cheat sequence
pub fn cheat_new(sequence string, parameter_chars int) CheatSeq {
	return CheatSeq{
		sequence: sequence
		sequence_len: sequence.len
		parameter_chars: parameter_chars
		chars_read: 0
		param_chars_read: 0
	}
}

// Check if a key matches the cheat sequence
// Returns true if cheat was completed, false otherwise
pub fn (mut cht CheatSeq) check_cheat(key u8) bool {
	// If we make a short sequence on a cheat with parameters, this
	// will not work in vanilla doom. Behave the same.
	if cht.parameter_chars > 0 && cht.sequence_len < cht.sequence_len {
		return false
	}

	if cht.chars_read < cht.sequence_len {
		// Still reading characters from the cheat code
		// and verifying. Reset to the beginning if a key is wrong
		if key == cht.sequence[cht.chars_read] {
			cht.chars_read++
		} else {
			cht.chars_read = 0
		}

		cht.param_chars_read = 0
	} else if cht.param_chars_read < cht.parameter_chars {
		// We have passed the end of the cheat sequence and are
		// entering parameters now
		cht.parameter_buf[cht.param_chars_read] = key
		cht.param_chars_read++
	}

	// Check if cheat is complete (sequence + parameters matched)
	if cht.chars_read >= cht.sequence_len && cht.param_chars_read >= cht.parameter_chars {
		cht.chars_read = 0
		cht.param_chars_read = 0
		return true
	}

	return false
}

// Get parameters buffer
pub fn (cht CheatSeq) get_params() []u8 {
	return cht.parameter_buf[..cht.param_chars_read]
}

// Reset cheat state
pub fn (mut cht CheatSeq) reset() {
	cht.chars_read = 0
	cht.param_chars_read = 0
}
