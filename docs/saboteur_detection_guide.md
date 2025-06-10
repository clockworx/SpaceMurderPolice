# Saboteur Detection System Guide

## Overview
The saboteur detection system allows NPCs to detect the player and switch between patrol, investigation, and return-to-patrol states. This is designed for NPCs that can become saboteurs during gameplay.

## Configuration

### NPC Properties
In the UnifiedNPC inspector, configure these properties:

#### NPC Properties Group
- `can_be_saboteur`: Must be `true` for the NPC to use saboteur behavior

#### Saboteur Mode Group
- `enable_saboteur_behavior`: Toggle to enable/disable detection behavior
- `detection_range`: How far the NPC can detect the player (default: 10.0)
- `vision_angle`: Field of view angle in degrees (default: 60.0)
- `investigation_duration`: How long to investigate when player is detected (default: 3.0)
- `return_to_patrol_speed`: Speed when returning to patrol route (default: 3.0)

## How It Works

### States
1. **PATROL**: Normal waypoint movement, checking for player detection
2. **INVESTIGATE**: Stop and look around when player is detected
3. **RETURN_TO_PATROL**: Navigate back to the last waypoint after investigation

### Detection System
- The NPC checks for player detection only during PATROL state
- Detection requires:
  - Player within `detection_range`
  - Clear line of sight (no walls/obstacles)
  - Player within `vision_angle` (cone of vision)
- When detected, NPC switches to INVESTIGATE state

### Investigation Behavior
- NPC stops at current position
- Rotates in place to "look around"
- After `investigation_duration` seconds, switches to RETURN_TO_PATROL
- Remembers the last waypoint before investigation

### Return to Patrol
- NPC navigates back to the last waypoint it was heading to
- Uses `return_to_patrol_speed` for movement
- Once reached, resumes normal PATROL behavior

## Setup Example

```gdscript
# In your scene setup:
var npc = $UnifiedNPC
npc.can_be_saboteur = true
npc.enable_saboteur_behavior = true
npc.detection_range = 12.0
npc.vision_angle = 45.0
npc.investigation_duration = 4.0
```

## Testing
1. Place a UnifiedNPC in your scene with waypoints
2. Enable `can_be_saboteur` and `enable_saboteur_behavior`
3. Enable `show_state_label` to see state changes
4. Run the scene and move the player in front of the NPC
5. The NPC should detect you, investigate, then return to patrol

## Dynamic Saboteur Transformation
During gameplay, you can transform any NPC into a saboteur:

```gdscript
# Transform NPC into active saboteur
npc.can_be_saboteur = true
npc.enable_saboteur_behavior = true

# Optionally use with SaboteurCharacterModes for visual changes
var modes = npc.get_node("SaboteurCharacterModes")
if modes:
    modes.switch_to_saboteur_mode()
```

## Debug Features
- `show_state_label`: Shows current state above NPC
- `debug_state_changes`: Prints state transitions to console
- State label colors:
  - Green: PATROL
  - Red: INVESTIGATE (with [!] indicator)
  - Orange: RETURN_TO_PATROL (shows target waypoint)

## Notes
- Detection only works when `enable_saboteur_behavior` is true
- NPCs without `can_be_saboteur` will never use detection behavior
- The system integrates with existing waypoint patrol behavior
- Compatible with SaboteurPatrolAI for more advanced saboteur behavior