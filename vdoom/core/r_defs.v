module core

pub const sil_none = 0
pub const sil_bottom = 1
pub const sil_top = 2
pub const sil_both = 3
pub const maxdrawsegs = 256

pub struct Vertex {
pub mut:
	x Fixed
	y Fixed
}

pub struct DegenMobj {
pub mut:
	thinker Thinker
	x Fixed
	y Fixed
	z Fixed
}

pub struct Sector {
pub mut:
	floorheight Fixed
	ceilingheight Fixed
	floorpic i16
	ceilingpic i16
	lightlevel i16
	special i16
	tag i16
	soundtraversed int
	soundtarget &Mobj = unsafe { nil }
	blockbox [4]int
	soundorg DegenMobj
	validcount int
	thinglist &Mobj = unsafe { nil }
	specialdata voidptr
	linecount int
	lines []&Line
}

pub struct Side {
pub mut:
	textureoffset Fixed
	rowoffset Fixed
	toptexture i16
	bottomtexture i16
	midtexture i16
	sector &Sector = unsafe { nil }
}

pub enum SlopeType {
	horizontal
	vertical
	positive
	negative
}

pub struct Line {
pub mut:
	v1 &Vertex = unsafe { nil }
	v2 &Vertex = unsafe { nil }
	dx Fixed
	dy Fixed
	flags i16
	special i16
	tag i16
	sidenum [2]i16
	bbox [4]Fixed
	slopetype SlopeType
	frontsector &Sector = unsafe { nil }
	backsector &Sector = unsafe { nil }
	validcount int
	specialdata voidptr
}

pub struct Subsector {
pub mut:
	sector &Sector = unsafe { nil }
	numlines i16
	firstline i16
}

pub struct Seg {
pub mut:
	v1 &Vertex = unsafe { nil }
	v2 &Vertex = unsafe { nil }
	offset Fixed
	angle int
	sidedef &Side = unsafe { nil }
	linedef &Line = unsafe { nil }
	frontsector &Sector = unsafe { nil }
	backsector &Sector = unsafe { nil }
}

pub struct Node {
pub mut:
	x Fixed
	y Fixed
	dx Fixed
	dy Fixed
	bbox [2][4]Fixed
	children [2]u16
}

pub type LightTable = u8

pub struct DrawSeg {
pub mut:
	curline &Seg = unsafe { nil }
	x1 int
	x2 int
	scale1 Fixed
	scale2 Fixed
	scalestep Fixed
	silhouette int
	bsilheight Fixed
	tsilheight Fixed
	sprtopclip []i16
	sprbottomclip []i16
	maskedtexturecol []i16
}

pub struct VisSprite {
pub mut:
	prev &VisSprite = unsafe { nil }
	next &VisSprite = unsafe { nil }
	x1 int
	x2 int
	gx Fixed
	gy Fixed
	gz Fixed
	gzt Fixed
	startfrac Fixed
	scale Fixed
	xiscale Fixed
	texturemid Fixed
	patch int
	colormap &LightTable = unsafe { nil }
	mobjflags int
}

pub struct SpriteFrame {
pub mut:
	rotate bool
	lump [8]i16
	flip [8]u8
}

pub struct SpriteDef {
pub mut:
	numframes int
	spriteframes []SpriteFrame
}

pub struct Visplane {
pub mut:
	height Fixed
	picnum int
	lightlevel int
	minx int
	maxx int
	pad1 u8
	top []u8
	pad2 u8
	pad3 u8
	bottom []u8
	pad4 u8
}
