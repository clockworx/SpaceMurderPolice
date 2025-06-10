# Cleanup Notes for GitHub Upload

## Before Uploading

### 1. Run Cleanup Script
- Open the scene in Godot
- Run `/scripts/tools/cleanup_for_github.gd` to disable all debug visuals
- Save all scenes after running

### 2. Tool Scripts to Review
The `/scripts/tools/` directory contains 54 tool scripts used during development. Consider:
- Moving them to a separate `dev-tools` branch
- Adding `/scripts/tools/` to `.gitignore`
- Or keeping only essential ones like `cleanup_for_github.gd`

### 3. Debug Features Status
After cleanup, NPCs will have:
- ✅ Detection system: ENABLED (working invisibly)
- ❌ Detection indicator (green/red sphere): HIDDEN
- ❌ Vision cone (blue cone): HIDDEN
- ❌ Range line (red line): HIDDEN
- ❌ State labels: HIDDEN
- ❌ Debug console output: DISABLED

### 4. Important Systems Implemented
- **Line of Sight Detection**: NPCs detect players within range and angle
- **Movement States**: PATROL, IDLE, TALK states with transitions
- **Waypoint Navigation**: NPCs follow predefined waypoint paths
- **Face Indicators**: Visual indicators showing NPC facing direction
- **Dynamic Vision Cone**: Debug visualization that updates with detection parameters

### 5. Key Files Modified
- `/scripts/npcs/npc_base.gd` - Core NPC functionality
- `/scripts/npcs/waypoint_npc_final.gd` - Waypoint NPC extension
- Various scene files with NPC instances

### 6. Console Output
The game will still show:
- Game initialization messages
- Evidence spawn messages
- Door warnings (expected - no sabotage manager yet)
- Critical errors only

### 7. Testing Before Upload
1. Run the game and ensure NPCs patrol normally
2. Test that NPCs still detect the player (even without visual indicators)
3. Verify no debug spam in console
4. Check that interaction prompts still work

## To Re-enable Debug Features
In the Inspector for any NPC:
- Line of Sight Detection > Show Detection Indicator = true
- Line of Sight Detection > Show Vision Cone = true

Or in code:
```gdscript
npc.show_detection_indicator = true
npc.show_vision_cone = true
```