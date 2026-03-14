# DOOM.v Rewrite Roadmap

A phased approach to translating crispy-doom from C to V.

## Current Status

- **110+ V files** in `vdoom/core/`
- **72 C files** in `crispy-doom/src/doom/`
- ~70% complete for core game structures
- ~20% complete for actual game logic
- Phase 2.2 Map Objects: p_mobj.v spawning/state machine/thinker complete
- Phase 2.3 Map & Collision: p_map.v movement/collision implemented

## Phase 1: Foundation (COMPLETED)

### Goals
- [x] Core type definitions (Fixed, Boolean, etc.)
- [x] Core constants and enums
- [x] Basic WAD loading
- [x] Frame rendering stubs

### Deliverables
- [x] p_user.v - Player physics
- [x] p_mobj.v - Map object structures
- [x] p_enemy.v - Enemy AI stubs
- [x] p_inter.v - Game interactions
- [x] p_sight.v - Line of sight
- [x] sounds.v - Sound/music enums
- [x] info.v - Sprite/state/mobj type enums

---

## Phase 2: Core Game Logic

### Goals
Implement the main game loop and player mechanics.

### Tasks

#### 2.1 Player System
- [ ] p_user.v - Complete player movement physics
- [ ] p_pspr.v - Weapon sprite system
- [ ] p_tick.v - Game ticker integration

#### 2.2 Map Objects
- [x] p_mobj.v - Complete mobj spawning/despawning
- [x] p_mobj.v - Mobj state machine
- [x] p_mobj.v - Mobj thinker

#### 2.3 Map & Collision
- [x] p_map.v - Movement collision detection
- [x] p_map.v - Blockmap traversal
- [ ] p_maputl.v - Map utilities
- [ ] p_setup.v - Level loading

#### 2.4 Enemy AI
- [ ] p_enemy.v - Chase behavior
- [ ] p_enemy.v - Attack patterns
- [ ] p_enemy.v - Line of sight tracking
- [ ] p_sight.v - Complete visibility checks

#### 2.5 Interactions
- [ ] p_inter.v - Complete damage system
- [ ] p_inter.v - Item pickup
- [ ] p_inter.v - Powerup handling
- [ ] p_spec.v - Line/sector specials

**Estimated: 3-4 weeks**

---

## Phase 3: Rendering Engine

### Goals
Implement the software renderer.

### Tasks

#### 3.1 Rendering Core
- [ ] r_main.v - View rendering
- [ ] r_state.v - Rendering state
- [ ] r_defs.v - Rendering data structures

#### 3.2 3D Engine
- [ ] r_bsp.v - BSP traversal
- [ ] r_segs.v - Segment rendering
- [ ] r_plane.v - Floor/ceiling planes
- [ ] r_sky.v - Sky rendering

#### 3.3 Visuals
- [ ] r_things.v - Sprite rendering
- [ ] r_draw.v - Column/span drawing
- [ ] r_data.v - Texture/flat management

**Estimated: 4-5 weeks**

---

## Phase 4: Audio System

### Goals
Implement sound and music playback.

### Tasks

#### 4.1 Sound Engine
- [ ] s_sound.v - Sound manager
- [ ] s_musinfo.v - Music tracking
- [ ] i_sound.v - SDL audio bindings

#### 4.2 Audio Data
- [ ] Complete sounds.v with all SFX
- [ ] Music track definitions

**Estimated: 2 weeks**

---

## Phase 5: User Interface

### Goals
Implement menus, HUD, and input.

### Tasks

#### 5.1 Menus
- [ ] m_menu.v - Main menu
- [ ] m_menu.v - Options menu
- [ ] m_menu.v - Save/load menus

#### 5.2 HUD
- [ ] st_stuff.v - Status bar
- [ ] hu_stuff.v - Heads-up display

#### 5.3 Input
- [ ] Input event handling
- [ ] Keyboard/mouse/joystick

#### 5.4 Automap
- [ ] am_map.v - Auto-map

**Estimated: 3-4 weeks**

---

## Phase 6: Game Features

### Goals
Complete all gameplay systems.

### Tasks

#### 6.1 Levels
- [ ] p_setup.v - Complete level loading
- [ ] p_spec.v - Special sector handling
- [ ] p_plats.v - Moving platforms
- [ ] p_ceilng.v - Ceiling dynamics
- [ ] p_doors.v - Door mechanics
- [ ] p_floor.v - Floor dynamics
- [ ] p_lights.v - Light effects

#### 6.2 Networking
- [ ] d_net.v - Network code
- [ ] Net client/server

#### 6.3 Demos
- [ ] Demo playback
- [ ] Demo recording

**Estimated: 3-4 weeks**

---

## Phase 7: Polish & Integration

### Goals
Finalize and test the complete engine.

### Tasks

#### 7.1 Testing
- [ ] Gameplay testing
- [ ] Compatibility testing
- [ ] Performance optimization

#### 7.2 Features
- [ ] Save/load games
- [ ] Screenshots
- [ ] Game options

#### 7.3 Platform
- [ ] Cross-platform build
- [ ] Binary distribution

**Estimated: 2-3 weeks**

---

## Total Timeline

| Phase | Duration |
|-------|----------|
| Phase 1: Foundation | DONE |
| Phase 2: Core Game Logic | 3-4 weeks |
| Phase 3: Rendering Engine | 4-5 weeks |
| Phase 4: Audio System | 2 weeks |
| Phase 5: User Interface | 3-4 weeks |
| Phase 6: Game Features | 3-4 weeks |
| Phase 7: Polish & Integration | 2-3 weeks |
| **Total** | **~18-24 weeks** |

---

## File Inventory

### Core Files (doom/)

| Category | C Files | V Files | Progress |
|----------|---------|---------|----------|
| Game Logic (p_*.c) | 18 | 14 | 78% |
| Rendering (r_*.c) | 10 | 10 | 100% |
| Data (d_*.c) | 8 | 8 | 100% |
| System (i_*.c) | 12 | 30+ | 250%* |
| UI (m_*, st_*, hu_*, am_*) | 6 | 6 | 100% |
| Other | 18 | 15 | 83% |
| **Total** | **72** | **105** | **~60%** |

*Some V files have consolidated multiple C files

---

## Milestones

### Milestone 1: WAD Loading (DONE ✓)
- [x] Parse WAD files
- [x] Load level data
- [x] Render basic frames

### Milestone 2: Playable Demo (Phase 2)
- [ ] Player movement
- [ ] Basic rendering
- [ ] Can walk around level

### Milestone 3: Alpha (Phase 3-4)
- [ ] Full rendering
- [ ] Sound/music
- [ ] Basic gameplay

### Milestone 4: Beta (Phase 5-6)
- [ ] Complete UI
- [ ] All game features
- [ ] Save/load

### Milestone 5: 1.0 Release (Phase 7)
- [ ] Full compatibility
- [ ] Performance optimized
- [ ] Production ready
