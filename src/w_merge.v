@[translated]
module main

fn C.W_MergeFile(&char)
fn C.W_NWTMergeFile(&char)

fn w_merge_file(filename &char) { C.W_MergeFile(filename) }
fn w_nwt_merge_file(filename &char) { C.W_NWTMergeFile(filename) }
