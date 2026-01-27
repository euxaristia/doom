module core

// Minimal V equivalents of packed patch structures.
pub struct Patch {
pub mut:
	width      i16
	height     i16
	leftoffset i16
	topoffset  i16
	columnofs  []int
}

pub struct Post {
pub mut:
	topdelta u8
	length   u8
}

pub type Column = Post
