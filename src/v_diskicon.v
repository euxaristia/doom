@[translated]
module main

// Disk load indicator (minimal software-rendered implementation).

const diskicon_threshold = usize(20 * 1024)
const loading_disk_w = 16
const loading_disk_h = 16

@[weak]
__global (
	disk_data          &Pixel_t
	saved_background   &Pixel_t
	loading_disk_xoffs int
	loading_disk_yoffs int
	recent_bytes_read  usize
	disk_drawn         bool
)

fn copy_region(dest &Pixel_t, dest_pitch int, src &Pixel_t, src_pitch int, w int, h int) {
	if dest == unsafe { nil } || src == unsafe { nil } {
		return
	}
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			unsafe {
				dest[y * dest_pitch + x] = src[y * src_pitch + x]
			}
		}
	}
}

fn ensure_disk_buffers() {
	if disk_data == unsafe { nil } {
		disk_data = &Pixel_t(z_malloc(loading_disk_w * loading_disk_h, pu_static, unsafe { nil }))
		// Simple checker icon.
		for y := 0; y < loading_disk_h; y++ {
			for x := 0; x < loading_disk_w; x++ {
				unsafe {
					disk_data[y * loading_disk_w + x] = if ((x / 4 + y / 4) % 2) == 0 {
						255
					} else {
						0
					}
				}
			}
		}
	}
	if saved_background == unsafe { nil } {
		saved_background = &Pixel_t(z_malloc(loading_disk_w * loading_disk_h, pu_static,
			unsafe { nil }))
	}
}

fn disk_region_pointer() &Pixel_t {
	return I_VideoBuffer + loading_disk_yoffs * 320 + loading_disk_xoffs
}

@[export: 'V_EnableLoadingDisk']
pub fn v_enable_loading_disk(_lump_name &i8, xoffs int, yoffs int) {
	_ = _lump_name
	loading_disk_xoffs = xoffs
	loading_disk_yoffs = yoffs
	ensure_disk_buffers()
}

@[export: 'V_BeginRead']
pub fn v_begin_read(nbytes usize) {
	recent_bytes_read += nbytes
}

@[export: 'V_DrawDiskIcon']
pub fn v_draw_disk_icon() {
	if I_VideoBuffer == unsafe { nil } {
		return
	}
	ensure_disk_buffers()
	if recent_bytes_read > diskicon_threshold {
		copy_region(saved_background, loading_disk_w, disk_region_pointer(), 320, loading_disk_w,
			loading_disk_h)
		copy_region(disk_region_pointer(), 320, disk_data, loading_disk_w, loading_disk_w,
			loading_disk_h)
		disk_drawn = true
	}
	recent_bytes_read = 0
}

@[export: 'V_RestoreDiskBackground']
pub fn v_restore_disk_background() {
	if !disk_drawn || I_VideoBuffer == unsafe { nil } {
		return
	}
	copy_region(disk_region_pointer(), 320, saved_background, loading_disk_w, loading_disk_w,
		loading_disk_h)
	disk_drawn = false
}
