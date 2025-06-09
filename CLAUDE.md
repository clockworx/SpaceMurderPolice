# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Murder at Aurora Station is an investigation survival horror game built in Godot 4.4. Players investigate murders while surviving escalating threats in a compromised space station, combining detective work with Outlast Trials-style co-op survival mechanics.

### Game Concept
- **Title**: Murder at Aurora Station
- **Genre**: Investigation Survival Horror / Co-operative Mystery
- **Core Pillars**: Investigation Under Pressure, Survival Horror Tension, Resource Management, Dynamic Threats, Cooperative Gameplay
- **Core Loop**: Investigate Murder → Gather Evidence While Avoiding Threats → Manage Resources → Survive Escalating Danger → Uncover Truth → Escape Station
- **Key Mechanics**: Evidence collection under threat, stealth/evasion, resource management, dynamic AI threats, environmental hazards, co-op mechanics
- **Setting**: Year 2387, Aurora Research Complex - a massive multi-level space station with 20+ areas
- **Player Role**: Investigators trapped on a hostile station with a killer and failing systems
- **Progression**: Unlock new areas, acquire tools/keycards, piece together the conspiracy while survival becomes harder

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
    │   ├── npc_base.gd              # Base NPC with AI and relationships
    │   ├── dialogue_system.gd       # Branching dialogue system
    │   ├── saboteur_patrol_ai.gd    # Saboteur hunting AI behavior
    │   └── saboteur_character_modes.gd # Dynamic character transformation
    ├── investigation/
    │   └── case_file_ui.gd     # Crosshair and interaction prompts
    ├── ship/
    │   ├── ship_interior.gd    # The Deduction ship management
    │   ├── ship_manager.gd     # Scene transitions between ship/missions
    │   └── [station scripts]   # Individual ship station scripts
    └── managers/
        ├── aurora_game_manager.gd   # Scene-specific game logic
        ├── evidence_manager.gd      # Tracks collected evidence/resources
        ├── evidence_spawn_manager.gd # Handles evidence/resource placement
        ├── game_state_manager.gd    # Tracks game mode and progression
        ├── phase_manager.gd         # Multi-phase horror progression
        └── sabotage_system_manager.gd # Environmental threats and sabotage
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
- **Phase System**: 
  - 5 phases: Arrival, Escalating Tension, Active Threat, Critical Discovery, Desperate Escape
  - Evidence and time-based progression
  - Each phase increases environmental threats and saboteur activity
- **Stealth Mechanics**: 
  - Hiding spots: lockers, vents, under desks
  - Crouching system with reduced movement speed
  - Line-of-sight detection system
- **Saboteur AI System**: 
  - State machine: PATROLLING, WAITING, INVESTIGATING, CHASING, SEARCHING, SABOTAGE
  - Room-aware navigation system
  - Dynamic character transformation (normal NPC → hostile saboteur)
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

1. **Dr. Sarah Chen** - Medical Officer (helpful initially, becomes paranoid as systems fail)
2. **Dr. Marcus Webb** - Chief Scientist (jealous researcher, red herring, may help or hinder)  
3. **Alex Chen** - Station Engineer (can become the saboteur - nervous initially, transforms into hostile hunter)
4. **Jake Torres** - Security Chief (gruff, tries to maintain order, can become ally or obstacle)
5. **Dr. Zara Okafor** - AI Specialist (helpful with station systems, knows about system vulnerabilities)
6. **Security Officer** - Additional security personnel (follows Jake's orders)

Note: Any NPC marked with `can_be_saboteur = true` can transform into the antagonist role

## New Design Vision (Investigation Survival Horror)

### Scale Expansion
- **From**: 6-room station
- **To**: Multi-level research complex with 20+ interconnected areas
- **Verticality**: Multiple decks connected by elevators, maintenance shafts, emergency ladders

### Core Gameplay Loop
1. **Investigation Phase**: Gather evidence, interview NPCs, access terminals
2. **Threat Escalation**: Riley becomes aware of investigation, begins hunting
3. **Survival Phase**: Avoid Riley, manage resources, use environmental systems
4. **Discovery Phase**: Uncover deeper conspiracy, systems begin failing
5. **Escape Phase**: Race to escape as station becomes increasingly hostile

### Threat Types
- **Riley (Primary)**: Evolves from nervous NPC to active hunter with AI states
- **Environmental**: Power failures, oxygen leaks, gravity malfunctions
- **Psychological**: Hallucinations, paranoia effects, trust erosion
- **Secondary NPCs**: Other survivors may become threats under stress

### Resource Management
- **Flashlight Battery**: Essential for dark areas
- **Oxygen Tanks**: For depressurized sections
- **Medical Supplies**: Heal injuries from environmental hazards
- **Access Cards**: Progress through secured areas
- **Evidence Storage**: Limited inventory forces tough choices

### Co-op Mechanics
- **Split Investigation**: Players can investigate different areas simultaneously
- **Shared Resources**: Must coordinate resource distribution
- **Distraction Tactics**: One player distracts threats while other progresses
- **Information Sharing**: Evidence discovered by one benefits all
- **Revival System**: Downed players can be rescued

## Mission Flow (Updated for Survival Horror)

### Phase 1: Arrival & Initial Investigation
- Dock at Aurora Station (last time you'll see The Deduction)
- Power fluctuations hint at system instability
- Meet NPCs in relatively safe environment
- Discover Dr. Elena's body and initial evidence
- Learn about station layout and recent incidents

### Phase 2: Escalating Tension
- Riley becomes suspicious of investigation
- First system failures (lights flicker, doors malfunction)
- NPCs show stress (paranoia, accusations, hiding)
- Find keycards to access restricted areas
- Resource scarcity begins (limited batteries, medical supplies)

### Phase 3: Active Threat
- Riley transitions to hunter mode with dynamic AI
- Major system failures (life support, gravity, power grid)
- Environmental hazards increase (fires, hull breaches, toxic leaks)
- NPCs may help, hinder, or become secondary threats
- Must balance investigation with survival

### Phase 4: Critical Discovery
- Uncover conspiracy involving station experiments
- Riley becomes increasingly aggressive and unpredictable
- Station AI may turn hostile or helpful based on player actions
- Other NPCs' true motivations revealed
- Final evidence pieces require extreme risk

### Phase 5: Desperate Escape
- Station enters critical failure cascade
- Multiple escape routes (escape pods, maintenance shuttle, cargo bay)
- Riley makes final desperate attempts to stop players
- Time pressure from imminent station destruction
- Co-op players must coordinate escape or sacrifice

## Technical Implementation Notes

### Current State (Prototype)
- The project uses Godot 4.4
- Main scene is main_menu.tscn -> aurora_station.tscn
- Current scale: 6-room station (to be expanded to 20+ areas)
- Collision layers: Layer 1 = Environment, Layer 2 = Interactables, Layer 3 = Threats
- Input map: WASD movement, E for interaction, Tab for Inventory, Shift for Sprint, Ctrl for Crouch
- Basic stealth mechanics implemented (hiding spots, line-of-sight detection)

### Planned Systems
- **Dynamic Threat AI**: State machines for Riley and environmental threats
- **Resource Inventory**: Limited slots for batteries, keycards, medical supplies
- **Sanity/Stress System**: Affects perception and NPC interactions
- **Environmental Hazards**: Fire spread, oxygen depletion, gravity failures
- **Co-op Networking**: 2-4 player support with shared progression
- **Procedural Elements**: Evidence placement, threat patterns, system failures

### Art Direction
- **Visual Style**: Dark, atmospheric with dramatic lighting
- **Color Palette**: Deep blues/purples (normal), red alerts (danger), green (safety)
- **Environmental Storytelling**: Damage, blood trails, broken systems tell story
- **UI Design**: Minimal HUD, diegetic interfaces where possible