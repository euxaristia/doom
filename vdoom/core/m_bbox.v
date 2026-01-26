module core

// Bounding box helpers ported from m_bbox.c.

pub const box_top = 0
pub const box_bottom = 1
pub const box_left = 2
pub const box_right = 3

pub fn clear_box(mut box []Fixed) {
    box[box_top] = int_min
    box[box_right] = int_min
    box[box_bottom] = int_max
    box[box_left] = int_max
}

pub fn add_to_box(mut box []Fixed, x Fixed, y Fixed) {
    if x < box[box_left] {
        box[box_left] = x
    } else if x > box[box_right] {
        box[box_right] = x
    }
    if y < box[box_bottom] {
        box[box_bottom] = y
    } else if y > box[box_top] {
        box[box_top] = y
    }
}
