# Expanded Aurora Station Layout Design

## Overview
Transforming Aurora Station from a 6-room facility to a multi-level research complex with 20+ interconnected areas.

## Station Structure

### Deck A - Command & Research (Upper Level)
1. **Bridge/Command Center** - Station control, emergency systems
2. **Observatory** - Stellar research, large windows
3. **Main Research Lab** - Primary experiments
4. **Data Analysis Center** - Computer core, servers
5. **Conference Room** - Meetings, briefings
6. **Executive Quarters** - High-ranking personnel

### Deck B - Living & Medical (Main Level - Current)
7. **Medical Bay** (existing, expanded)
8. **Surgery Suite** - Connected to Medical
9. **Crew Quarters** (existing, expanded)
10. **Cafeteria** (existing, expanded)
11. **Recreation Room** - Morale facility
12. **Fitness Center** - Exercise equipment
13. **Public Restrooms**

### Deck C - Operations & Security (Lower Level)
14. **Security Office** (existing, expanded)
15. **Armory** - Restricted access
16. **Detention Center** - Holding cells
17. **Engineering** (existing, expanded)
18. **Power Generation** - Reactor room
19. **Life Support Systems** - O2, heating, gravity
20. **Cargo Bay** - Storage, deliveries
21. **Docking Bay** - Ship connections

### Maintenance & Emergency Areas (All Decks)
22. **Maintenance Shafts** - Horizontal crawlspaces
23. **Ventilation System** - Between decks
24. **Emergency Stairwells** - Two locations
25. **Elevator Shafts** - Two main lifts
26. **Escape Pod Bay** - Deck C

## Layout Features

### Vertical Connections
- **Main Elevators**: Connect all three decks at hallway intersections
- **Emergency Stairs**: At each end of the station
- **Maintenance Ladders**: Hidden vertical access
- **Ventilation Shafts**: Can crawl between levels

### Horizontal Layout (Per Deck)
- **Central Spine**: Main hallway runs full length
- **Cross Corridors**: Connect parallel sections
- **Ring Corridors**: Alternative routes around rooms
- **Dead Ends**: Create tension, trap scenarios

### Room Sizes
- **Small** (6x6): Quarters, offices, storage
- **Medium** (8x8): Labs, medical, security
- **Large** (12x10): Cargo, engineering, cafeteria
- **Huge** (16x12): Bridge, observatory, docking

## Horror Design Elements

### Isolation Zones
- Sections can be sealed off (quarantine/damage)
- Power failures isolate areas
- Damaged corridors force detours

### Ambush Points
- Blind corners
- Dark alcoves
- Ceiling access panels
- Floor grates

### Environmental Storytelling
- Blast damage in certain areas
- Blood trails between rooms
- Barricaded doors
- Makeshift survivor camps

### Lighting Zones
- **Bright**: Command areas (Phase 1 only)
- **Normal**: Living areas
- **Dim**: Maintenance areas
- **Emergency**: Red lighting during failures
- **Dark**: Damaged/unpowered sections

## Implementation Plan

### Phase 1: Core Expansion
1. Create room prefabs for each size
2. Build Deck B (expand current level)
3. Add elevators and stairs
4. Test NPC navigation

### Phase 2: Vertical Addition
1. Add Deck A above
2. Add Deck C below
3. Connect with elevators
4. Add maintenance shafts

### Phase 3: Details
1. Furniture and props
2. Environmental hazards
3. Hiding spots
4. Evidence spawn points

### Phase 4: Atmosphere
1. Lighting variations
2. Damage states
3. Audio zones
4. Particle effects

## Technical Considerations

### Performance
- Use occlusion culling
- LOD for distant sections
- Limit active NPCs per area
- Stream sections as needed

### Navigation
- Multi-level NavMesh
- Elevator navigation links
- Ladder/shaft connections
- Dynamic obstacle avoidance

### Multiplayer
- Section-based networking
- Player proximity loading
- Shared state optimization