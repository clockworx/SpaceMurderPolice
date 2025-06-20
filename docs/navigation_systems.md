# Navigation Systems Documentation

## Overview

The SpaceMurderPolice project now supports two different navigation systems for NPCs:

1. **A* Waypoint Navigation** (Custom Implementation)
2. **NavMesh Navigation** (Godot Built-in)

NPCs can switch between these systems at runtime for testing and comparison.

## A* Waypoint Navigation System

### Components
- **WaypointNetworkManager**: Manages waypoint connections and A* pathfinding
- **DirectMovement**: Handles movement between waypoints with wall avoidance
- **Room & Hallway Waypoints**: Pre-placed Node3D markers for navigation

### Features
- Custom A* pathfinding algorithm
- Wall avoidance using raycasting
- Doorway detection for smoother transitions
- Movement smoothing to prevent flickering
- Intermediate waypoints for proper room connections

### How It Works
1. NPCs request a path to a destination room waypoint
2. WaypointNetworkManager calculates optimal path through waypoint network
3. DirectMovement handles movement between waypoints with obstacle avoidance
4. Wall detection uses 8 rays in a circle to avoid collisions
5. Doorway detection reduces avoidance when passing through doors

## NavMesh Navigation System

### Components
- **NavigationSetupManager**: Automatically creates and bakes navigation mesh
- **NavMeshMovement**: Uses NavigationAgent3D for pathfinding
- **NavigationLink3D**: Connects separate navigation regions (doors)
- **NavigationRegion3D**: Contains the baked navigation mesh

### Features
- Automatic navigation mesh generation
- Built-in avoidance with NavigationAgent3D
- Corridor funnel post-processing for smoother paths
- Support for NavigationLink3D at doorways
- Dynamic obstacle avoidance

### How It Works
1. NavigationSetupManager creates NavigationRegion3D on scene load
2. Navigation mesh is baked from level geometry
3. NPCs use NavigationAgent3D to request paths
4. NavigationServer3D handles pathfinding and avoidance
5. NavigationLink3D nodes connect rooms through doorways

## Switching Between Systems

### Runtime Toggle
- Press **F1** to open debug UI
- Click "Toggle Movement System" button
- Or use the `use_navmesh` property on NPCs

### In Editor
- Select NPC in scene
- Under "Movement System" group:
  - Check `use_navmesh` for NavMesh navigation
  - Uncheck for A* waypoint navigation

## Debug Visualization

The NavigationDebugVisualizer (F1 to toggle) shows:
- **Waypoints**: Blue spheres (regular), Green spheres (rooms)
- **Current Target**: Yellow sphere
- **Navigation Paths**: 
  - Green lines for planned path
  - Red lines for NavigationAgent3D path
  - Gray for completed segments
- **NPC Status**: Movement system in use

## Performance Comparison

### A* Waypoint System
**Pros:**
- Predictable paths through defined waypoints
- Good for structured environments
- Less computational overhead
- Easier to debug specific routes

**Cons:**
- Requires manual waypoint placement
- Less flexible for dynamic obstacles
- Can look unnatural in open areas

### NavMesh System
**Pros:**
- Natural-looking movement
- Handles any walkable surface
- Dynamic obstacle avoidance
- No manual waypoint setup needed

**Cons:**
- Higher computational cost
- Requires navigation mesh baking
- Can be unpredictable in complex geometry
- May need tweaking for different agent sizes

## Best Practices

1. **Use A* Waypoints when:**
   - You need predictable patrol routes
   - The environment has clear paths/hallways
   - Performance is critical
   - You want explicit control over NPC movement

2. **Use NavMesh when:**
   - NPCs need to navigate open areas
   - Dynamic obstacles are present
   - Natural movement is priority
   - You don't want to place waypoints manually

## Troubleshooting

### A* System Issues
- **NPC stuck at walls**: Increase `wall_avoidance_force` in DirectMovement
- **Flickering at doors**: Adjust `doorway_detection_angle` and `min_movement_threshold`
- **Not finding paths**: Check waypoint connections in WaypointNetworkManager

### NavMesh System Issues
- **NPC not moving**: Ensure NavigationRegion3D exists and mesh is baked
- **Stuck at doors**: Verify NavigationLink3D placement and connections
- **Poor avoidance**: Adjust NavigationAgent3D radius and neighbor distance
- **Path not found**: Check navigation mesh covers all walkable areas

## Code Examples

### Force NPC to use NavMesh
```gdscript
var npc = get_tree().get_first_node_in_group("npcs")
npc.use_navmesh = true
npc.move_to_position(target_position)
```

### Force NPC to use Waypoints
```gdscript
var npc = get_tree().get_first_node_in_group("npcs")
npc.use_navmesh = false
npc.use_waypoints = true
npc._navigate_to_room("MedicalBay_Waypoint")
```