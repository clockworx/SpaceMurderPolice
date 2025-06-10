# Waypoint System Guide

## Overview
The waypoint system provides a simple way for NPCs to follow predefined paths in the game world, with visual editor tools for easy path creation.

## Components

### 1. SimpleWaypointWalker
- Basic CharacterBody3D that moves between waypoints
- Located at: `scripts/npcs/simple_waypoint_walker.gd`
- Properties:
  - `waypoints`: Array of Vector3 positions (manual method)
  - `waypoint_nodes`: Array of NodePath references to waypoint nodes
  - `waypoint_path`: NodePath to a WaypointPath or Path3D node
  - `use_waypoint_nodes`: Use node references instead of positions
  - `use_waypoint_path`: Whether to use the path node or manual waypoints
  - `movement_speed`: Speed of movement (default: 3.0)
  - `waypoint_reach_distance`: Distance to consider waypoint reached (default: 1.0)

### 2. WaypointNPC
- Extends NPCBase to add waypoint functionality
- Located at: `scripts/npcs/waypoint_npc.gd`
- Maintains all NPC features (dialogue, relationships) while adding waypoints
- Falls back to random wandering if no waypoints are set

### 3. SelfContainedWaypointNPC (RECOMMENDED)
- Complete NPC with waypoints as child nodes
- Located at: `scripts/npcs/self_contained_waypoint_npc.gd`
- Each NPC is a self-contained asset with its own patrol path
- Waypoints are stored in a "Waypoints" child node
- Features:
  - Automatic collection of child waypoints
  - Pause at waypoints with configurable duration
  - Dynamic waypoint updates (move waypoints in editor)
  - Falls back to wandering if no waypoints found

### 3. Waypoint System with Visual Markers
- **Waypoint3D**: Visual waypoint with sphere mesh (Editor-Only)
  - Located at: `scripts/npcs/waypoint_3d.gd`
  - Shows colored sphere with label in editor
  - Automatically hidden during runtime
  - Properties:
    - `waypoint_color`: Color of the sphere
    - `waypoint_size`: Size of the sphere
    - `show_label`: Whether to show text label
    - `label_text`: Custom label (defaults to "W" + index)
    - `wait_time`: How long NPC pauses at this waypoint
  
- **WaypointContainer**: Container that draws paths between waypoints
  - Located at: `scripts/npcs/waypoint_container.gd`
  - Draws lines between waypoints in editor
  - Properties:
    - `show_path_lines`: Toggle path visualization
    - `path_color`: Color of the path lines
    - `loop_path`: Whether to connect last waypoint to first
  
- **WaypointPath3D**: Alternative using Godot's Path3D
  - Located at: `scripts/npcs/waypoint_path_3d.gd`
  - Uses built-in curve editing tools

### 4. Pre-configured NPCs with Waypoints
- `engineer_waypoint_npc.tscn` - Engineer with 4-point patrol route
- `security_chief_waypoint_npc.tscn` - Security Chief with 5-point patrol
- `medical_officer_waypoint_npc.tscn` - Medical Officer with 3-point route
- `chief_scientist_waypoint_npc.tscn` - Chief Scientist with lab patrol

## Usage

### Method 1: Self-Contained NPCs (RECOMMENDED - Cleanest)
1. Use one of the pre-configured NPC scenes (e.g., `engineer_waypoint_npc.tscn`)
2. Place the NPC in your level
3. Select the NPC and expand the "Waypoints" child node
4. Move the waypoint spheres to desired positions in the 3D view
5. Adjust waypoint properties (color, label, size) in Inspector
6. Configure pause durations and other patrol settings on the NPC

**Advantages:**
- Each NPC is a complete, self-contained asset
- Waypoints move with the NPC if repositioned
- Easy to duplicate NPCs with their patrol routes
- Clean scene hierarchy

### Method 2: Direct Node References (Most Flexible)
1. Add waypoint instances or Node3D with `Waypoint3D` script anywhere in scene
2. Position waypoints using the colored spheres
3. Add your NPC with `SimpleWaypointWalker` script  
4. In the Inspector, expand "Waypoint Nodes" array
5. Drag each waypoint node into the array slots
6. Enable `use_waypoint_nodes`

**Advantages:**
- Waypoints can be anywhere in the scene hierarchy
- Dynamic - move waypoints and NPC follows in real-time
- Easy to attach in Inspector by dragging nodes
- Can reuse waypoints for multiple NPCs

### Method 2: Using WaypointContainer (For Organized Paths)
1. Add a Node3D to your scene and attach `WaypointContainer` script
2. Add child Node3D nodes and attach `Waypoint3D` script to each
3. Position waypoints using the colored spheres in the editor
4. Set waypoint properties in the inspector:
   - Color, size, and labels for easy identification
   - Wait time if you want NPCs to pause
5. Add your NPC with `SimpleWaypointWalker` script
6. Set `waypoint_path` to point to your WaypointContainer
7. Enable `use_waypoint_path`

**Advantages:**
- Visible colored spheres in editor
- Labels show waypoint order
- Path lines connect waypoints
- Everything automatically hidden at runtime

### Method 2: Using Path3D (For curved paths)
1. Add a Path3D node to your scene
2. Attach the `WaypointPath3D` script to it
3. Use the Path3D editor tools to add curve points
4. Add your NPC with `SimpleWaypointWalker` script
5. Set the `waypoint_path` property to point to your Path3D node
6. Enable `use_waypoint_path`

### Method 3: Manual waypoints (original method)
1. Add a CharacterBody3D node to your scene
2. Attach the `SimpleWaypointWalker` script (or use `WaypointNPC` for full NPC features)
3. In the Inspector, find "Waypoint Settings"
4. Add waypoints by clicking the Array and adding Vector3 positions

### Setting waypoints via code:
```gdscript
# Get reference to the waypoint walker
var walker = $SimpleWaypointWalker

# Set waypoints
walker.waypoints = [
    Vector3(5, 1, 5),
    Vector3(5, 1, -5),
    Vector3(-5, 1, -5),
    Vector3(-5, 1, 5)
]

# Or add individual waypoints
walker.add_waypoint(Vector3(0, 1, 10))
```

## Debug Output
The system prints debug information to help with development:
- Initial waypoint count when starting
- Current target waypoint every 60 frames
- Distance to current target
- "Reached waypoint!" messages when switching targets

## Known Limitations (Task 1A)
- NPCs don't rotate to face movement direction (slides sideways)
- No obstacle avoidance
- Simple straight-line movement only
- No smooth transitions between waypoints

These limitations will be addressed in subsequent tasks.