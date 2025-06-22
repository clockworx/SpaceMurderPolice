# NavMesh Navigation Test Guide

## Setup Complete

The Godot NavMesh navigation system is now fully set up with:

1. **NavigationRegion3D** - You've added and baked the navigation mesh
2. **NavigationLink3D nodes** - Present on all 6 doors to connect rooms
3. **NavMeshMovement** - Uses NavigationAgent3D for pathfinding
4. **Debug Visualization** - Multiple visualization tools added

## Testing Tools Added

### 1. NavMesh Room Test (Auto-added to scene)
- Provides buttons to test navigation to each room
- "Start Room Navigation Test" - Cycles through all rooms automatically
- Individual room buttons for manual testing
- Shows status of current navigation

### 2. Navigation Debug Visualizer (F1 to toggle)
- Shows NavigationAgent3D paths in red
- Displays waypoints and current targets
- Shows NPC movement system status

### 3. Navigation Link Visualizer (Always visible)
- Yellow lines show NavigationLink3D connections
- Green spheres at start positions
- Red spheres at end positions
- Labels show which door each link belongs to

## How to Test

1. **Run the scene** (F5)
2. **Check console output** for:
   - "NavigationSetupManager: Found existing NavigationRegion3D" (or navigation maps)
   - "NavigationLinkVisualizer: Found 6 navigation links"
   - NavMesh movement debug messages

3. **Use the test UI** (appears on left side):
   - Click any "Go to [Room]" button
   - Watch the NPC navigate using NavMesh
   - Yellow lines show NavigationLink3D connections at doors

4. **Press F1** for additional debug info:
   - See current movement system (should show "NavMesh")
   - Force move to specific rooms
   - Toggle between movement systems (for comparison)

## What to Look For

### Success Indicators:
- NPC smoothly navigates through doorways
- NavigationLink3D connections visible as yellow lines
- Console shows "Target is reachable" messages
- NPC reaches destination rooms successfully

### Potential Issues:
- "Target may not be reachable!" - Navigation mesh might have gaps
- NPC gets stuck at doors - NavigationLink3D placement may need adjustment
- No path found - Check if navigation mesh covers all areas

## NavigationLink3D Details

Each door has a NavigationLink3D with:
- **Start Position**: Vector3(0, 0, -2) - Outside the door
- **End Position**: Vector3(0, 0, 2) - Inside the door
- **Bidirectional**: true - Can traverse both ways

These links connect the navigation mesh regions between rooms, allowing the NPC to plan paths through doorways.

## Console Debug Output

When an NPC moves, you'll see:
```
NavMeshMovement: move_to_position called with (x, y, z)
NavMeshMovement: Target is reachable
NavMeshMovement: Path has N points
NavMeshMovement: Navigation finished, distance to target: X
```

## Adjustments You Can Make

1. **NavigationAgent3D settings** (in navmesh_movement.gd):
   - `radius`: Agent size for avoidance
   - `max_speed`: Movement speed
   - `target_desired_distance`: How close to get to target

2. **NavigationLink3D positions** (in scene):
   - Adjust start/end positions if NPCs struggle at doors
   - Can be done in Godot editor on each door

3. **Navigation mesh rebaking**:
   - Select NavigationRegion3D in scene
   - Click "Bake NavigationMesh" in inspector