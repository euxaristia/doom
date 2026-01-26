@[translated]
module main

const fineangles = 8192
const finemask = fineangles - 1
const angletofineshift = 19
const sloperange = 2048

fn slope_div(num u32, den u32) u32 {
	if den < 512 {
		return sloperange
	}
	ans := (num << 3) / (den >> 8)
	if ans <= sloperange {
		return ans
	}
	return sloperange
}
