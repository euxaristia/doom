@[translated]
module main

// High-resolution startup screen hooks (software fallback backend).

const (
	fade_time_ms     = 2000
	hr_screen_width  = 640
	hr_screen_height = 480
)

@[weak]
__global (
	mut hr_video_inited       bool
	mut hr_window_title       &i8 = c''
	mut hr_screen_buffer      &u8
	mut hr_current_palette    [16 * 3]u8
	mut hr_requested_palette  [16 * 3]u8
)

fn hr_buffer_len() int {
	return hr_screen_width * hr_screen_height
}

fn ensure_hr_buffer() {
	if hr_screen_buffer != unsafe { nil } {
		return
	}
	hr_screen_buffer = &u8(z_malloc(hr_buffer_len(), pu_static, unsafe { nil }))
}

@[export: 'I_SetVideoModeHR']
pub fn i_set_video_mode_hr() bool {
	ensure_hr_buffer()
	hr_video_inited = true
	return true
}

@[export: 'I_SetWindowTitleHR']
pub fn i_set_window_title_hr(title &i8) {
	hr_window_title = title
}

@[export: 'I_UnsetVideoModeHR']
pub fn i_unset_video_mode_hr() {
	hr_video_inited = false
}

@[export: 'I_ClearScreenHR']
pub fn i_clear_screen_hr() {
	if !hr_video_inited {
		return
	}
	ensure_hr_buffer()
	unsafe {
		mut p := hr_screen_buffer
		for i := 0; i < hr_buffer_len(); i++ {
			p[i] = 0
		}
	}
}

@[export: 'I_SlamBlockHR']
pub fn i_slam_block_hr(x int, y int, w int, h int, src &u8) {
	if !hr_video_inited || src == unsafe { nil } || w <= 0 || h <= 0 {
		return
	}
	if x < 0 || y < 0 || x + w > hr_screen_width || y + h > hr_screen_height {
		return
	}
	ensure_hr_buffer()

	plane_size := (w * h) / 8
	if plane_size <= 0 {
		return
	}

	unsafe {
		mut src_ptr := src
		plane0 := src_ptr
		plane1 := src_ptr + plane_size
		plane2 := src_ptr + (2 * plane_size)
		plane3 := src_ptr + (3 * plane_size)

		mut bit := 0
		for yy := y; yy < y + h; yy++ {
			row_off := yy * hr_screen_width
			for xx := x; xx < x + w; xx++ {
				byte_off := bit / 8
				shift := 7 - (bit % 8)

				b0 := (plane0[byte_off] >> shift) & 0x1
				b1 := (plane1[byte_off] >> shift) & 0x1
				b2 := (plane2[byte_off] >> shift) & 0x1
				b3 := (plane3[byte_off] >> shift) & 0x1

				hr_screen_buffer[row_off + xx] = b0 | (b1 << 1) | (b2 << 2) | (b3 << 3)
				bit++
			}
		}
	}
}

@[export: 'I_SlamHR']
pub fn i_slam_hr(buffer &u8) {
	i_slam_block_hr(0, 0, hr_screen_width, hr_screen_height, buffer)
}

@[export: 'I_InitPaletteHR']
pub fn i_init_palette_hr() {
	for i := 0; i < hr_current_palette.len; i++ {
		hr_current_palette[i] = 0
		hr_requested_palette[i] = 0
	}
}

@[export: 'I_SetPaletteHR']
pub fn i_set_palette_hr(palette &u8) {
	if palette == unsafe { nil } {
		return
	}
	unsafe {
		mut pal := palette
		for i := 0; i < hr_current_palette.len; i++ {
			hr_current_palette[i] = pal[i]
			hr_requested_palette[i] = pal[i]
		}
	}
}

@[export: 'I_FadeToPaletteHR']
pub fn i_fade_to_palette_hr(palette &u8) {
	if palette == unsafe { nil } {
		return
	}

	mut target := [16 * 3]u8{}
	unsafe {
		mut pal := palette
		for i := 0; i < target.len; i++ {
			target[i] = pal[i]
		}
	}

	start := i_get_time_ms()
	for {
		elapsed := i_get_time_ms() - start
		if elapsed >= fade_time_ms {
			break
		}
		for i := 0; i < hr_current_palette.len; i++ {
			hr_current_palette[i] = u8((int(target[i]) * elapsed) / fade_time_ms)
		}
		i_sleep(10)
	}

	for i := 0; i < hr_current_palette.len; i++ {
		hr_current_palette[i] = target[i]
		hr_requested_palette[i] = target[i]
	}
}

@[export: 'I_BlackPaletteHR']
pub fn i_black_palette_hr() {
	for i := 0; i < hr_current_palette.len; i++ {
		hr_current_palette[i] = 0
		hr_requested_palette[i] = 0
	}
}

@[export: 'I_CheckAbortHR']
pub fn i_check_abort_hr() bool {
	// No event pump in the software fallback backend.
	return false
}
