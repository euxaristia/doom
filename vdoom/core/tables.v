module core

// Placeholder tables module used by renderer headers.
pub const fine_angles = 8192
pub const fine_mask = fine_angles - 1
pub const fine_angles_half = fine_angles / 2

pub const finesine = []Fixed{}
pub const finecosine = []Fixed{}

// Angle constants
pub const angle_t_u32_max = u32(0xffffffff)
pub const angle_t_i32_max = i32(0x7fffffff)

pub const ang45 = u32(0x20000000)
pub const ang90 = u32(0x40000000)
pub const ang180 = u32(0x80000000)
pub const ang270 = u32(0xc0000000)
pub const ang_max = u32(0xffffffff)
pub const ang1 = u32(0x1200000) // ANG45 / 45
pub const ang60 = u32(0x55555555) // ANG180 / 3
pub const ang5 = u32(0x22222222) // ANG180 / 36

pub const angle_to_fineshift = 19
pub const angle_to_sky_shift = 22

pub const look_min = -90
pub const look_max = 90
pub const mlook_unit = 1
