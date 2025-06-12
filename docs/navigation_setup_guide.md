# Navigation Setup Guide

## Overview
NPCs in this project support two movement systems:
1. **Direct Movement** - Simple straight-line movement, good for open areas
2. **NavMesh Movement** - Pathfinding around obstacles using Godot's NavigationServer3D

## Setting Up Navigation in Your Scene

### 1. Add a NavigationRegion3D
- Add a `NavigationRegion3D` node to your scene
- This will contain the navigation mesh for pathfinding

### 2. Create Navigation Mesh Geometry
Use CSG nodes to define walkable areas:
```
NavigationRegion3D
├── NavMeshBase (CSGBox3D) - The main floor area
├── WallCutout1 (CSGBox3D, operation = Subtract) - Cut out wall areas
├── WallCutout2 (CSGBox3D, operation = Subtract)
└── WallCutout3 (CSGBox3D, operation = Subtract)
```

### 3. Bake the Navigation Mesh
1. Select the NavigationRegion3D node
2. In the toolbar, click "Bake NavigationMesh"
3. The navigation mesh will be generated, avoiding obstacles

### 4. Configure NPCs
Set `use_navmesh = true` on NPCs that should use pathfinding:
- Good for complex environments with obstacles
- NPCs will automatically path around walls and objects

Set `use_navmesh = false` for simple movement:
- Good for open areas or predetermined paths
- More predictable movement patterns

## Testing
Use the movement test scene at `scenes/test/movement_test.tscn`:
- Press SPACE to toggle between movement systems
- Press N to move to next waypoint
- Press R to reset position

## Troubleshooting

### NPCs Going Through Walls
1. Make sure navigation mesh is properly baked
2. Check that wall areas are excluded from the navigation mesh
3. Increase NavigationAgent3D radius for better clearance
4. Verify collision layers are set correctly

### NPCs Getting Stuck
1. Check navigation mesh has no gaps or disconnected areas
2. Ensure waypoints are on the navigation mesh
3. Verify NPC collision shapes aren't too large
4. Use debug visualization to see the navigation path