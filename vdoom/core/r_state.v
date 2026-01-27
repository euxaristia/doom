@[has_globals]
module core

// Texture/sprite lookup tables.
__global textureheight = []Fixed{}
__global spritewidth = []Fixed{}
__global spriteoffset = []Fixed{}
__global spritetopoffset = []Fixed{}
__global colormaps = []u8{}

// View sizes.
__global viewwidth = 0
__global scaledviewwidth = 0
__global viewheight = 0
__global firstflat = 0
__global flattranslation = []int{}
__global texturetranslation = []int{}

// Sprite lumps.
__global firstspritelump = 0
__global lastspritelump = 0
__global numspritelumps = 0

// Map data tables.
__global numsprites = 0
__global sprites = []SpriteDef{}
__global numvertexes = 0
__global vertexes = []Vertex{}
__global numsegs = 0
__global segs = []Seg{}
__global numsectors = 0
__global sectors = []Sector{}
__global numsubsectors = 0
__global subsectors = []Subsector{}
__global numnodes = 0
__global nodes = []Node{}
__global numlines = 0
__global lines = []Line{}
__global numsides = 0
__global sides = []Side{}

// POV data.
__global viewx = Fixed(0)
__global viewy = Fixed(0)
__global viewz = Fixed(0)
__global viewangle = 0
__global viewplayer = unsafe { nil }
__global clipangle = 0
__global viewangletox = []int{len: fine_angles / 2}
__global xtoviewangle = []int{len: screenwidth + 1}
__global rw_distance = Fixed(0)
__global rw_normalangle = 0
__global rw_angle1 = 0
__global sscount = 0
__global floorplane = unsafe { nil }
__global ceilingplane = unsafe { nil }

pub fn r_init_state() {}
