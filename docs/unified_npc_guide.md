# Unified NPC System Guide

## Overview
The UnifiedNPC is a complete, reusable NPC system that can be dropped into any level with full customization options.

## Base Scene
- **Location**: `scenes/npcs/unified_npc_base.tscn`
- **Script**: `scripts/npcs/unified_npc.gd`

## Features

### Movement States
1. **PATROL** - Follow waypoints in order
2. **IDLE** - Stop and wait
3. **TALK** - Face a target (usually player)
4. **WANDER** - Random movement within radius

### Key Properties

#### NPC Properties
- `npc_name` - Display name
- `role` - Job/role description
- `initial_dialogue_id` - Starting dialogue
- `can_be_saboteur` - Can transform into antagonist

#### Movement Configuration
- `walk_speed` - Movement speed
- `rotation_speed` - Turn speed
- `current_state` - Starting state

#### Waypoint System
- `use_waypoints` - Enable waypoint navigation
- `waypoint_nodes` - Array of waypoint nodes
- `pause_at_waypoints` - Stop at each waypoint

#### Wander System (if no waypoints)
- `wander_radius` - How far to wander
- `idle_time_min/max` - Pause duration range

#### Interaction
- `react_to_player_proximity` - Auto state changes
- `idle_trigger_distance` - Stop when player near
- `talk_trigger_distance` - Face player when close

#### Visual Options
- `show_face_indicator` - Enable face direction indicator
- `face_indicator_type` - Cone, Eyes, Nose, or Arrow
- `show_state_label` - Debug label above head

## Usage Examples

### 1. Basic Patrol NPC
```gdscript
1. Instance unified_npc_base.tscn
2. Set name and role
3. Add waypoint nodes to the scene
4. Drag waypoints into waypoint_nodes array
5. Done!
```

### 2. Wandering NPC (No Waypoints)
```gdscript
1. Instance unified_npc_base.tscn
2. Set use_waypoints = false
3. Set wander_radius = 10.0
4. NPC will wander randomly
```

### 3. Stationary NPC
```gdscript
1. Instance unified_npc_base.tscn
2. Set current_state = IDLE
3. Set react_to_player_proximity = true
4. NPC will face player when approached
```

### 4. Custom Behavior
```gdscript
# In your scene script
func _ready():
    var npc = $UnifiedNPC
    
    # Custom state changes
    npc.set_idle_state()
    await get_tree().create_timer(5.0).timeout
    npc.set_patrol_state()
    
    # React to state changes
    npc.state_changed.connect(_on_npc_state_changed)

func _on_npc_state_changed(old_state, new_state):
    print("NPC changed from ", old_state, " to ", new_state)
```

## Creating Specialized NPCs

### Inherit from UnifiedNPC
```gdscript
extends UnifiedNPC
class_name GuardNPC

func _ready():
    super._ready()
    # Guard-specific setup
    walk_speed = 1.5  # Slower patrol
    idle_trigger_distance = 8.0  # More alert
```

### Or Configure in Scene
1. Instance unified_npc_base.tscn
2. Make it unique (right-click → Make Local)
3. Save as new scene (e.g., guard_npc.tscn)
4. Customize all properties
5. Reuse this configured NPC

## Best Practices

1. **Waypoints**: Place waypoint nodes as children of a Waypoints node for organization
2. **Face Indicators**: Use different colors for different NPC types
3. **State Labels**: Enable during development, disable for release
4. **Proximity**: Enable for important NPCs, disable for background NPCs
5. **Performance**: Limit proximity checks to key NPCs

## Migration from Old System

To convert existing NPCs:
1. Replace script with unified_npc.gd
2. Copy waypoint_nodes array content
3. Adjust any custom properties
4. Test state transitions

The UnifiedNPC combines all features into one flexible system!