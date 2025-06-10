# Waypoint Door Navigation Guide

## The Problem
When waypoints are placed in different rooms, NPCs will try to walk straight through walls instead of using doors.

## The Solution
Add intermediate waypoints at doorways to guide NPCs through proper paths.

## Example Pattern
For a patrol route that goes from inside a room to outside:
1. Waypoint1 (inside room)
2. Waypoint2 (near door, inside)
3. **WaypointDoor** (at doorway)
4. Waypoint3 (outside room)
5. **WaypointDoor** (return through door)

## Implementation
In the scene, I added:
- `ScientistWaypointDoor` at the Laboratory 3 door position
- Updated the ChiefScientist waypoint array to include the door waypoint twice:
  - Once when going out (waypoint 2 → door → waypoint 3)
  - Once when returning (waypoint 3 → door → back to waypoint 1)

## Tips
- Place door waypoints slightly offset from the actual door to avoid collision
- Include door waypoints in both directions for smooth patrol loops
- Use descriptive labels like "Door" to identify these waypoints easily
- Door waypoints don't need pausing - NPCs will move through quickly