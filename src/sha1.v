@[translated]
module main

struct Sha1Context {
	state [5]u32
	count [2]u32
	buf [64]u8
	input [80]u32
}

fn C.SHA1_Init(&Sha1Context)
fn C.SHA1_Update(&Sha1Context, &u8, u32)
fn C.SHA1_Final(&u8, &Sha1Context)

fn sha1_init(context &Sha1Context) { C.SHA1_Init(context) }
fn sha1_update(context &Sha1Context, data &u8, len u32) { C.SHA1_Update(context, data, len) }
fn sha1_final(digest &u8, context &Sha1Context) { C.SHA1_Final(digest, context) }
