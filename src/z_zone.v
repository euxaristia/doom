@[translated]
module main

// Zone memory allocation constants
const mem_align = sizeof(voidptr)
const zoneid = 0x1d4a11
const minfragment = 64

// Memory tags (PU - purge tags)
const pu_static = 1       // static entire execution time
const pu_sound = 2        // static while playing
const pu_music = 3        // static while playing
const pu_free = 4         // a free block
const pu_level = 5        // static until level exited
const pu_levspec = 6      // a special thinker in a level
const pu_purgelevel = 7   // Tags >= PU_PURGELEVEL are purgable whenever needed
const pu_cache = 8        // cache tag
const pu_num_tags = 9     // Total number of different tag types

struct memblock_t {
	size int         // including the header and possibly tiny fragments
	user &&void      // pointer to user's variable
	tag int          // PU_FREE if this is free
	id int           // should be ZONEID
	next &memblock_t
	prev &memblock_t
}

struct memzone_t {
	size int        // total bytes malloced, including header
	blocklist memblock_t  // start / end cap for linked list
	rover &memblock_t
}

// Global zone memory allocator state
mut mainzone &memzone_t
mut zero_on_free bool
mut scan_on_free bool

// Forward declarations
fn i_error(error_msg &char)
fn m_parm_exists(check &char) bool

// ScanForBlock - Scan the zone heap for pointers within the specified range
fn scan_for_block(start voidptr, end voidptr) {
	mut block := mainzone.blocklist.next

	for block.next != &mainzone.blocklist {
		tag := block.tag

		if tag == pu_static || tag == pu_level || tag == pu_levspec {
			// Scan for pointers on the assumption that pointers are aligned
			// on word boundaries (word size depending on pointer size)
			mut mem := unsafe { (&void)((&u8(block) + sizeof(memblock_t))) }
			len := (block.size - sizeof(memblock_t)) / sizeof(voidptr)

			for i := 0; i < len; i++ {
				ptr := unsafe { (&voidptr(mem))[i] }
				if ptr >= start && ptr <= end {
					C.fprintf(C.stderr, c'%p has dangling pointer into freed block %p (%p -> %p)\n',
						mem, start, unsafe { &(&voidptr(mem))[i] }, ptr)
				}
			}
		}

		block = block.next
	}
}

// Z_ClearZone - Initialize a zone memory block
fn z_clear_zone(zone &memzone_t) {
	// set the entire zone to one free block
	block := unsafe { (&memblock_t((&u8(zone) + sizeof(memzone_t)))) }
	zone.blocklist.next = block
	zone.blocklist.prev = block

	zone.blocklist.user = unsafe { &(&void(zone)) }
	zone.blocklist.tag = pu_static
	zone.rover = block

	block.prev = &zone.blocklist
	block.next = &zone.blocklist

	// a free block
	block.tag = pu_free
	block.size = zone.size - sizeof(memzone_t)
}

// Z_Init - Initialize the zone memory allocator
fn z_init() {
	mut size := 0
	mainzone = unsafe { (&memzone_t(i_zone_base(&size))) }
	mainzone.size = size

	// set the entire zone to one free block
	block := unsafe { (&memblock_t((&u8(mainzone) + sizeof(memzone_t)))) }
	mainzone.blocklist.next = block
	mainzone.blocklist.prev = block

	mainzone.blocklist.user = unsafe { &(&void(mainzone)) }
	mainzone.blocklist.tag = pu_static
	mainzone.rover = block

	block.prev = &mainzone.blocklist
	block.next = &mainzone.blocklist

	// free block
	block.tag = pu_free
	block.size = mainzone.size - sizeof(memzone_t)

	// Zone memory debugging flag: if set, memory is zeroed after it is freed
	zero_on_free = m_parm_exists(c'-zonezero')

	// Zone memory debugging flag: if set, each time memory is freed, the zone
	// heap is scanned to look for remaining pointers to the freed block
	scan_on_free = m_parm_exists(c'-zonescan')
}

// Z_Free - Free a block of memory
fn z_free(ptr voidptr) {
	if ptr == unsafe { nil } {
		return
	}

	block := unsafe { (&memblock_t((&u8(ptr) - sizeof(memblock_t)))) }

	if block.id != zoneid {
		i_error(c'Z_Free: freed a pointer without ZONEID')
	}

	if block.tag != pu_free && block.user != unsafe { nil } {
		// clear the user's mark
		unsafe {
			*block.user = nil
		}
	}

	// mark as free
	block.tag = pu_free
	block.user = unsafe { nil }
	block.id = 0

	// If the -zonezero flag is provided, zero out the block on free
	if zero_on_free {
		C.memset(ptr, 0, block.size - sizeof(memblock_t))
	}

	if scan_on_free {
		scan_for_block(ptr, unsafe { (&u8(ptr) + block.size - sizeof(memblock_t)) })
	}

	// Try to merge with previous free block
	other := block.prev

	if other.tag == pu_free {
		// merge with previous free block
		other.size += block.size
		other.next = block.next
		other.next.prev = other

		if block == mainzone.rover {
			mainzone.rover = other
		}

		block = other
	}

	// Try to merge with next free block
	other = block.next
	if other.tag == pu_free {
		// merge the next free block onto the end
		block.size += other.size
		block.next = other.next
		block.next.prev = block

		if other == mainzone.rover {
			mainzone.rover = block
		}
	}
}

// Z_Malloc - Allocate a block of memory
// You can pass a NULL user if the tag is < PU_PURGELEVEL
fn z_malloc(size int, tag int, user &&void) voidptr {
	mut extra := 0
	mut start := mainzone.rover
	mut rover := mainzone.rover
	mut newblock := &memblock_t{}
	mut base := mainzone.rover

	// align size
	aligned_size := (size + mem_align - 1) & ~(mem_align - 1)

	// account for size of block header
	total_size := aligned_size + sizeof(memblock_t)

	// if there is a free block behind the rover, back up over them
	if base.prev.tag == pu_free {
		base = base.prev
	}

	rover = base
	start = base.prev

	for {
		if rover == start {
			// scanned all the way around the list
			i_error(c'Z_Malloc: failed on allocation of %i bytes', total_size)
		}

		if rover.tag != pu_free {
			if rover.tag < pu_purgelevel {
				// hit a block that can't be purged, so move base past it
				base = rover.next
				rover = base
			} else {
				// free the rover block (adding the size to base)
				base = base.prev
				z_free(unsafe { &u8(rover) + sizeof(memblock_t) })
				base = base.next
				rover = base.next
			}
		} else {
			rover = rover.next
		}

		if base.tag == pu_free && base.size >= total_size {
			break
		}
	}

	// found a block big enough
	extra = base.size - total_size

	if extra > minfragment {
		// there will be a free fragment after the allocated block
		newblock = unsafe { (&memblock_t((&u8(base) + total_size))) }
		newblock.size = extra

		newblock.tag = pu_free
		newblock.user = unsafe { nil }
		newblock.prev = base
		newblock.next = base.next
		newblock.next.prev = newblock

		base.next = newblock
		base.size = total_size
	}

	if user == unsafe { nil } && tag >= pu_purgelevel {
		i_error(c'Z_Malloc: an owner is required for purgable blocks')
	}

	base.user = user
	base.tag = tag

	result := unsafe { (&void((&u8(base) + sizeof(memblock_t)))) }

	if base.user != unsafe { nil } {
		unsafe {
			*base.user = result
		}
	}

	// next allocation will start looking here
	mainzone.rover = base.next

	base.id = zoneid

	return result
}

// Z_FreeTags - Free all blocks with tags in the given range
fn z_free_tags(lowtag int, hightag int) {
	mut block := mainzone.blocklist.next

	for block != &mainzone.blocklist {
		// get link before freeing
		next := block.next

		// free block?
		if block.tag != pu_free {
			if block.tag >= lowtag && block.tag <= hightag {
				z_free(unsafe { &u8(block) + sizeof(memblock_t) })
			}
		}

		block = next
	}
}

// Z_DumpHeap - Display heap contents for debugging
fn z_dump_heap(lowtag int, hightag int) {
	C.printf(c'zone size: %i  location: %p\n', mainzone.size, mainzone)
	C.printf(c'tag range: %i to %i\n', lowtag, hightag)

	mut block := mainzone.blocklist.next

	for {
		if block.tag >= lowtag && block.tag <= hightag {
			C.printf(c'block:%p    size:%7i    user:%p    tag:%3i\n',
				block, block.size, block.user, block.tag)
		}

		if block.next == &mainzone.blocklist {
			// all blocks have been hit
			break
		}

		if unsafe { (&u8(block) + block.size) } != unsafe { (&u8(block.next)) } {
			C.printf(c'ERROR: block size does not touch the next block\n')
		}

		if block.next.prev != block {
			C.printf(c'ERROR: next block doesn\'t have proper back link\n')
		}

		if block.tag == pu_free && block.next.tag == pu_free {
			C.printf(c'ERROR: two consecutive free blocks\n')
		}

		block = block.next
	}
}

// Z_FileDumpHeap - Dump heap to file
fn z_file_dump_heap(f &C.FILE) {
	C.fprintf(f, c'zone size: %i  location: %p\n', mainzone.size, mainzone)

	mut block := mainzone.blocklist.next

	for {
		C.fprintf(f, c'block:%p    size:%7i    user:%p    tag:%3i\n',
			block, block.size, block.user, block.tag)

		if block.next == &mainzone.blocklist {
			// all blocks have been hit
			break
		}

		if unsafe { (&u8(block) + block.size) } != unsafe { (&u8(block.next)) } {
			C.fprintf(f, c'ERROR: block size does not touch the next block\n')
		}

		if block.next.prev != block {
			C.fprintf(f, c'ERROR: next block doesn\'t have proper back link\n')
		}

		if block.tag == pu_free && block.next.tag == pu_free {
			C.fprintf(f, c'ERROR: two consecutive free blocks\n')
		}

		block = block.next
	}
}

// Z_CheckHeap - Check heap integrity
fn z_check_heap() {
	mut block := mainzone.blocklist.next

	for {
		if block.next == &mainzone.blocklist {
			// all blocks have been hit
			break
		}

		if unsafe { (&u8(block) + block.size) } != unsafe { (&u8(block.next)) } {
			i_error(c'Z_CheckHeap: block size does not touch the next block\n')
		}

		if block.next.prev != block {
			i_error(c'Z_CheckHeap: next block doesn\'t have proper back link\n')
		}

		if block.tag == pu_free && block.next.tag == pu_free {
			i_error(c'Z_CheckHeap: two consecutive free blocks\n')
		}

		block = block.next
	}
}

// Z_ChangeTag2 - Change the tag of an allocated block
fn z_change_tag2(ptr voidptr, tag int, file &char, line int) {
	block := unsafe { (&memblock_t((&u8(ptr) - sizeof(memblock_t)))) }

	if block.id != zoneid {
		i_error(c'%s:%i: Z_ChangeTag: block without a ZONEID!', file, line)
	}

	if tag >= pu_purgelevel && block.user == unsafe { nil } {
		i_error(c'%s:%i: Z_ChangeTag: an owner is required for purgable blocks', file, line)
	}

	block.tag = tag
}

// Z_ChangeUser - Change the user pointer of an allocated block
fn z_change_user(ptr voidptr, user &&void) {
	block := unsafe { (&memblock_t((&u8(ptr) - sizeof(memblock_t)))) }

	if block.id != zoneid {
		i_error(c'Z_ChangeUser: Tried to change user for invalid block!')
	}

	block.user = user
	unsafe {
		*user = ptr
	}
}

// Z_FreeMemory - Get the amount of free memory in the zone
fn z_free_memory() int {
	mut free := 0

	mut block := mainzone.blocklist.next
	for block != &mainzone.blocklist {
		if block.tag == pu_free || block.tag >= pu_purgelevel {
			free += block.size
		}
		block = block.next
	}

	return free
}

// Z_ZoneSize - Get the total zone size
fn z_zone_size() u32 {
	return u32(mainzone.size)
}
