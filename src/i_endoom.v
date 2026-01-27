@[translated]
module main

// Exit text-mode ENDOOM screen.

const endoom_w = 80
const endoom_h = 25
const txt_screen_w = 80
const txt_screen_h = 25
const package_string = 'Chocolate Doom 3.0.0'

fn C.TXT_Init()
fn C.TXT_SetWindowTitle(&i8)
fn C.TXT_GetScreenData() &u8
fn C.TXT_UpdateScreen()
fn C.TXT_GetChar() int
fn C.TXT_Sleep(int)
fn C.TXT_Shutdown()
fn C.memcpy(voidptr, voidptr, usize) voidptr

@[export: 'I_Endoom']
pub fn i_endoom(endoom_data &u8) {
	// Set up text mode screen.
	C.TXT_Init()
	C.TXT_SetWindowTitle(package_string.str)

	screendata := C.TXT_GetScreenData()
	indent := (endoom_w - txt_screen_w) / 2

	// Copy the centered ENDOOM data into the textscreen buffer.
	for y := 0; y < txt_screen_h; y++ {
		dst_off := usize(y * txt_screen_w * 2)
		src_off := usize((y * endoom_w + indent) * 2)
		unsafe {
			C.memcpy(screendata + dst_off, endoom_data + src_off, usize(txt_screen_w * 2))
		}
	}

	// Wait for a keypress.
	for {
		C.TXT_UpdateScreen()
		if C.TXT_GetChar() > 0 {
			break
		}
		C.TXT_Sleep(0)
	}

	// Shut down text mode screen.
	C.TXT_Shutdown()
}
