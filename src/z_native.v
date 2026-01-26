// Copyright(C) 1993-1996 Id Software, Inc.
// Copyright(C) 2005-2014 Simon Howard
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// DESCRIPTION:
// Zone Memory Allocation. Neat.
// This is an implementation of the zone memory API which
// uses native calls to malloc() and free().

import os

const (
	zone_id = 0x1d4a11
)

// Memory block metadata
struct MemBlock {
	id    u32     // = zone_id
	tag   int
	size  int
	user  &&void
	prev  &MemBlock
	next  &MemBlock
}

// Zone allocator using native malloc/free
pub struct ZoneAllocator {
mut:
	allocated_blocks [9]&MemBlock
}

// Global zone allocator instance
__global z_allocator = ZoneAllocator{}

// Initialize zone memory allocator
pub fn zone_init() {
	for i := 0; i < 9; i++ {
		z_allocator.allocated_blocks[i] = unsafe { nil }
	}
	println('zone memory: Using native V allocator.')
}

// Allocate memory with tag and user pointer
pub fn zone_malloc(size int, tag int, user &&void) &void {
	if tag < 0 || tag >= 9 || tag == 4 {
		eprintln('Z_Malloc: attempted to allocate a block with an invalid tag: ${tag}')
		return unsafe { nil }
	}
	if user == unsafe { nil } && tag >= 7 {
		eprintln('Z_Malloc: an owner is required for purgable blocks')
		return unsafe { nil }
	}

	// Allocate block memory
	newblock := unsafe {
		malloc(sizeof(MemBlock) + size)
	}
	if newblock == unsafe { nil } {
		eprintln('Z_Malloc: failed on allocation of ${size} bytes')
		return unsafe { nil }
	}

	newblock.tag = tag
	newblock.id = zone_id
	newblock.user = user
	newblock.size = size

	z_allocator.insert_block(newblock)

	data := unsafe { newblock } + sizeof(MemBlock)
	if user != unsafe { nil } {
		user = data
	}

	return data
}

// Free allocated memory
pub fn zone_free(ptr &void) {
	if ptr == unsafe { nil } {
		return
	}

	block := unsafe { ptr } - sizeof(MemBlock)
	if unsafe { block }.id != zone_id {
		eprintln('Z_Free: freed a pointer without ZONEID')
		return
	}

	if unsafe { block }.tag != 4 && unsafe { block }.user != unsafe { nil } {
		unsafe { block }.user = unsafe { nil }
	}

	z_allocator.remove_block(block)
	unsafe { free(block) }
}

// Free all blocks in a tag range
pub fn zone_free_tags(lowtag int, hightag int) {
	for i := lowtag; i <= hightag; i++ {
		mut block := z_allocator.allocated_blocks[i]
		for block != unsafe { nil } {
			mut next := unsafe { block }.next
			if unsafe { block }.user != unsafe { nil } {
				unsafe { block }.user = unsafe { nil }
			}
			unsafe { free(block) }
			block = next
		}
		z_allocator.allocated_blocks[i] = unsafe { nil }
	}
}

// Get total zone size (placeholder - returns 0)
pub fn zone_get_size() u32 {
	return 0
}

// Check heap integrity
pub fn zone_check_heap() {
	for i := 0; i < 9; i++ {
		mut prev := &MemBlock(unsafe { nil })
		mut block := z_allocator.allocated_blocks[i]
		for block != unsafe { nil } {
			if unsafe { block }.id != zone_id {
				eprintln('Z_CheckHeap: Block without a ZONEID!')
			}
			if unsafe { block }.prev != prev {
				eprintln('Z_CheckHeap: Doubly-linked list corrupted!')
			}
			prev = block
			block = unsafe { block }.next
		}
	}
}

// Change tag of an allocated block
pub fn zone_change_tag(ptr &void, tag int) {
	block := unsafe { ptr } - sizeof(MemBlock)
	if unsafe { block }.id != zone_id {
		eprintln('Z_ChangeTag: block without a ZONEID!')
		return
	}
	if tag >= 7 && unsafe { block }.user == unsafe { nil } {
		eprintln('Z_ChangeTag: an owner is required for purgable blocks')
		return
	}

	z_allocator.remove_block(block)
	unsafe { block }.tag = tag
	z_allocator.insert_block(block)
}

// Change user pointer for allocated block
pub fn zone_change_user(ptr &void, user &&void) {
	block := unsafe { ptr } - sizeof(MemBlock)
	if unsafe { block }.id != zone_id {
		eprintln('Z_ChangeUser: Tried to change user for invalid block!')
		return
	}
	unsafe { block }.user = user
	if user != unsafe { nil } {
		user = ptr
	}
}

// Insert block at head of tag list
fn (mut z ZoneAllocator) insert_block(block &MemBlock) {
	unsafe {
		block.prev = nil
		block.next = z.allocated_blocks[block.tag]
		z.allocated_blocks[block.tag] = block
		if block.next != nil {
			block.next.prev = block
		}
	}
}

// Remove block from tag list
fn (mut z ZoneAllocator) remove_block(block &MemBlock) {
	unsafe {
		if block.prev == nil {
			z.allocated_blocks[block.tag] = block.next
		} else {
			block.prev.next = block.next
		}

		if block.next != nil {
			block.next.prev = block.prev
		}
	}
}
