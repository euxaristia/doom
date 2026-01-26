@[translated]
module main

fn C.W_ChecksumFile(&char) voidptr
fn C.W_ChecksumLump(&char, int) voidptr

fn w_checksum_file(filename &char) voidptr {
	return C.W_ChecksumFile(filename)
}

fn w_checksum_lump(name &char, lumpnum int) voidptr {
	return C.W_ChecksumLump(name, lumpnum)
}
