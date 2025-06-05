# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Murder at Aurora Station is an investigation mystery game built in Godot 4.4. Players are elite space investigators solving procedurally generated murders aboard research stations.

### Game Concept
- **Title**: Murder at Aurora Station
- **Genre**: Investigation Mystery / Co-operative Survival (non-violent)
- **Core Pillars**: Investigation First, Atmospheric Tension, Meaningful Cooperation, Replayable Variety, Non-violent Solutions
- **Core Loop**: Receive Case → Dock at Station → Gather Evidence → Analyze & Deduce → Solve Case → Return to Ship
- **Key Mechanics**: Evidence collection/analysis, deduction engine, witness interviews, theory building
- **Setting**: Year 2387, various space stations (research, mining, colonial, corporate, military)
- **Player Role**: Independent space investigators piloting "The Deduction" - a mobile forensics laboratory
- **Progression**: Persistent ship upgrades, reputation building, equipment improvements

## Development Environment

This is a Godot Engine 4.4 project using GDScript.

## Common Commands

Since this is a Godot project, most development will be done through the Godot Editor:

- Opening the project: Launch Godot and open the project.godot file
- Running the game: Press F5 in the Godot Editor or use the Play button
- Running specific scenes: Press F6 in the Godot Editor while the scene is open
- Exporting builds: Use Project > Export in the Godot Editor

## Project Structure

```
SpaceMurderPolice/
├── scenes/
│   ├── player/              # First-person player controller with UI
│   ├── ui/                  # UI components (HUD, interaction prompts)
│   ├── npcs/               # NPC scenes (6 characters)
│   ├── evidence/           # Evidence types (physical, digital, weapon, keycard, document)
│   ├── environment/        # Environmental objects (doors, lockers, vents, desks)
│   ├── levels/             # Game levels (aurora_station)
│   └── ship/               # The Deduction - investigator ship
└── scripts/
    ├── player/
    │   ├── player_controller.gd  # WASD movement, mouse look, stealth
    │   └── interaction_system.gd # Raycast-based interaction
    ├── evidence/
    │   ├── evidence_base.gd     # Base class for interactive evidence
    │   ├── physical_evidence.gd # Physical evidence with hiding mechanics
    │   └── digital_evidence.gd  # Digital evidence type
    ├── npcs/
    │   ├── npc_base.gd         # Base NPC with AI and relationships
    │   ├── dialogue_system.gd  # Branching dialogue system
    │   └── riley_patrol_ai.gd  # Night cycle AI behavior
    ├── investigation/
    │   └── case_file_ui.gd     # Crosshair and interaction prompts
    ├── ship/
    │   ├── ship_interior.gd    # The Deduction ship management
    │   ├── ship_manager.gd     # Scene transitions between ship/missions
    │   └── [station scripts]   # Individual ship station scripts
    └── managers/
        ├── aurora_game_manager.gd   # Scene-specific game logic
        ├── evidence_manager.gd      # Tracks collected evidence
        ├── evidence_spawn_manager.gd # Handles evidence placement
        ├── game_state_manager.gd    # Tracks game mode and progression
        └── day_night_manager.gd     # Day/night cycle with stealth mechanics
```

## Key Systems

### Implemented Systems

- **First-Person Controller**: Investigation-focused movement (3.5 units/sec walk speed)
- **Interaction System**: Raycast-based object interaction with UI prompts and crosshair feedback
- **Evidence System**: 
  - 5 evidence types: Physical, Digital, Weapon, Keycard, Document
  - Evidence manager tracking collected items
  - Story mode with fixed evidence placement
  - Evidence UI with tab key access
- **Dialogue System**: 
  - Branching conversations with 6 unique NPCs
  - Relationship tracking (-2 to +2 scale)
  - Dialogue locked by evidence/relationships
  - Important decision tracking
- **NPC System**:
  - 6 characters: Riley Kim, Jake Torres, Dr. Sarah Chen, Dr. Marcus Webb, Dr. Zara Okafor, AI Specialist
  - Relationship levels: Hostile, Unfriendly, Neutral, Friendly, Trusted
  - NPCs remember player choices and affect available information
- **Day/Night Cycle**: 
  - Evidence-based progression (collect 6 items to trigger night)
  - Day phase: investigation and interviews
  - Night phase: stealth gameplay with Riley patrol AI
- **Stealth Mechanics**: 
  - Hiding spots: lockers, vents, under desks
  - Crouching system with reduced movement speed
  - Line-of-sight detection system
- **Riley's Patrol AI**: 
  - State machine: PATROLLING, WAITING, INVESTIGATING, CHASING, SEARCHING
  - Room-aware navigation system
  - Debug indicators (overhead light and text)
- **The Deduction Ship**: 
  - Mobile forensics laboratory scene
  - 4 investigation stations: Evidence Board, Forensics Lab, Computer Terminal, Case Files
  - Persistent evidence storage and ship upgrades
  - Scene transitions between ship and missions
- **Station Layout**: 
  - 6-room Aurora Station: Laboratory 3, Medical Bay, Security Office, Engineering, Crew Quarters, Cafeteria
  - Crime scene in Laboratory 3 with victim body
  - Hiding spots distributed throughout station

### Systems To Implement

- **Deduction Interface**: Connect evidence to solve the case
- **Computer Terminals**: Access logs and communications throughout station
- **Life Support Timer**: Create urgency without hard fail
- **Save/Load System**: Persistent progress and ship upgrades
- **Ship Station UIs**: Individual interfaces for each ship workstation

## Current NPCs (Aurora Incident)

1. **Dr. Sarah Chen** - Medical Officer (helpful, starts friendly)
2. **Dr. Marcus Webb** - Chief Scientist (jealous researcher, red herring)  
3. **Riley Kim** - Engineer/Tech specialist and the killer (nervous, deflecting, night patrol AI)
4. **Jake Torres** - Security Chief (gruff, starts unfriendly)
5. **Dr. Zara Okafor** - AI Specialist (helpful with station systems)
6. **[Security NPC]** - Additional security personnel

## Mission Flow

### Phase 1: Initial Investigation (Day Cycle)
- Dock The Deduction at Aurora Station
- Meet 6 NPCs and examine crime scene (Lab 3)
- Collect evidence throughout station (6 total items)
- Conduct initial interviews with relationship tracking

### Phase 2: Day Investigation Continues
- Access all 6 rooms: Lab 3, Medical, Security, Engineering, Crew Quarters, Cafeteria
- Build relationships with NPCs to unlock information
- Use Evidence UI (Tab key) to track collected items
- Investigation triggers night cycle when enough evidence collected

### Phase 3: Night Cycle (Stealth Phase)
- Station enters emergency lighting mode
- Riley begins AI patrol route with state machine behavior
- Player uses hiding spots (lockers, vents, desks) and crouching
- Access restricted areas while avoiding Riley's line-of-sight detection
- Find final evidence linking Riley to the murder

### Phase 4: Return to Ship & Analysis
- Enter The Deduction via ship entrance
- Use 4 investigation stations to analyze evidence:
  - Evidence Board: Connect clues and theories
  - Forensics Lab: Analyze physical evidence  
  - Computer Terminal: Research suspects
  - Case Files: Review investigation notes
- Build final deduction and solve case

## Notes

- The project uses Godot 4.4
- Main scene is main_menu.tscn -> aurora_station.tscn
- Collision layers: Layer 1 = Environment, Layer 2 = Interactables
- Input map: WASD movement, E for interaction, Tab for Evidence UI, M for debug day reset
- The Deduction ship: Persistent mobile laboratory with scene transitions
- Day/Night cycle: Evidence-based progression system with stealth mechanics
- All scenes include interaction UI with crosshair feedback and hover prompts