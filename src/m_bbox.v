@[translated]
module main

const (
	bbox_int_min = int(-2147483648)
	bbox_int_max = int(2147483647)
)

// M_ClearBox - Clear a bounding box to empty state
@[c: 'M_ClearBox']
fn m_clear_box(box &int) {
	box[int(boxtop)] = bbox_int_min
	box[int(boxright)] = bbox_int_min
	box[int(boxbottom)] = bbox_int_max
	box[int(boxleft)] = bbox_int_max
}

// M_AddToBox - Add a point to a bounding box
@[c: 'M_AddToBox']
fn m_add_to_box(box &int, x int, y int) {
	if x < box[int(boxleft)] {
		box[int(boxleft)] = x
	} else if x > box[int(boxright)] {
		box[int(boxright)] = x
	}

	if y < box[int(boxbottom)] {
		box[int(boxbottom)] = y
	} else if y > box[int(boxtop)] {
		box[int(boxtop)] = y
	}
}
