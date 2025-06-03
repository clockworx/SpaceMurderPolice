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
│   ├── player/          # First-person player controller
│   ├── ui/              # UI components (HUD, interaction prompts)
│   └── test_level/      # Test environments
└── scripts/
    ├── player/
    │   ├── player_controller.gd  # WASD movement, mouse look
    │   ├── interaction_system.gd # Raycast-based interaction
    │   └── inventory.gd         # (To be implemented)
    ├── evidence/
    │   ├── evidence_base.gd     # Base class for interactive evidence
    │   ├── physical_evidence.gd # (To be implemented)
    │   └── digital_evidence.gd  # (To be implemented)
    ├── npcs/
    │   ├── npc_base.gd         # (To be implemented)
    │   ├── dialogue_system.gd  # (To be implemented)
    │   └── npc_ai.gd          # (To be implemented)
    ├── investigation/
    │   ├── case_manager.gd     # (To be implemented)
    │   ├── deduction_system.gd # (To be implemented)
    │   └── case_file_ui.gd     # Crosshair and interaction prompts
    └── managers/
        ├── game_manager.gd     # Scene management and UI connections
        ├── save_system.gd      # (To be implemented)
        └── audio_manager.gd    # (To be implemented)
```

## Key Systems

- **First-Person Controller**: Investigation-focused movement (3.5 units/sec walk speed)
- **Interaction System**: Raycast-based object interaction with UI prompts
- **Evidence System**: (To be implemented) Collection and analysis mechanics
- **Dialogue System**: (To be implemented) NPC interviews and conversations

## Notes

- The project uses Godot 4.4
- Main scene is set to test_level.tscn
- Collision layers: Layer 1 = Environment, Layer 2 = Interactables
- Input map configured for WASD movement and E for interaction