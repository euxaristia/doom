module core

// Core typedefs and platform constants ported from doomtype.h.

pub type Boolean = bool
pub type Byte = u8
pub type Pixel = u8
pub type DPixel = i16
pub type Fixed = i32

pub const frac_bits = 16
pub const frac_unit = 1 << frac_bits

pub const int_min = i32(-2147483648)
pub const int_max = i32(2147483647)

$if windows {
    pub const dir_separator = `\\`
    pub const dir_separator_s = "\\"
    pub const path_separator = `;`
} $else {
    pub const dir_separator = `/`
    pub const dir_separator_s = "/"
    pub const path_separator = `:`
}
