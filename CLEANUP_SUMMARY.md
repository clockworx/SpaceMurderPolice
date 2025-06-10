# Project Cleanup Summary

## Safe to Delete (24 files)

### 1. Backup Files (1)
- `scenes/levels/NewStation.tscn.backup`

### 2. Test/Debug Scripts (9)
These are development tools that aren't needed for the game:
- `scripts/test/debug_npc_facing.gd`
- `scripts/test/npc_state_display.gd`
- `scripts/test/saboteur_detection_tuner.gd`
- `scripts/test/saboteur_vision_debug.gd`
- `scripts/test/test_npc_proximity.gd`
- `scripts/test/test_npc_states.gd`
- `scripts/test/test_saboteur_detection.gd`
- `scripts/test/test_sound_detection.gd`
- `scripts/test/toggle_state_labels.gd`

### 3. Orphaned UID Files (3)
These are references to deleted scripts:
- `scripts/npcs/simple_direct_waypoint.gd.uid`
- `scripts/npcs/waypoint_debug.gd.uid`
- `scripts/npcs/waypoint_npc_collision_fix.gd.uid`

### 4. Duplicate Files (1)
- `scripts/investigation/case_file_ui.gd` (duplicate of `scripts/ui/case_file_ui.gd`)

### 5. Unused Unity/Migration Files (2)
- `scripts/tools/update_npcs_to_unified.gd` (migration complete, NPCs use npc_base)
- `scenes/npcs/unified_npc_base.tscn` (0 NPCs use this)

### 6. Old Waypoint Iterations (2)
- `scripts/npcs/smart_waypoint_npc.gd` (superseded by waypoint_npc_final)
- `scripts/npcs/waypoint_npc_fixed.gd` (superseded by waypoint_npc_final)

### 7. Test Scenes (2)
- `scenes/levels/simple_station.tscn` (test version)
- `scenes/rooms/room_template.tscn` (template file)

### 8. Temporary Fixes (1)
- `scripts/managers/waypoint_fix_manager.gd` (temporary fix)

### 9. Empty Directories (1)
- `scenes/navigation/` (empty folder)

### 10. Unused Scripts (2)
- `scripts/npcs/unified_npc.gd` (not used, NPCs use npc_base.gd)
- `scripts/levels/unified_station_builder.gd` (check if NewStation uses it)

## Files to Keep

### Core NPC System
- `scripts/npcs/npc_base.gd` - Main NPC class (all 7 NPCs use this)
- `scripts/npcs/waypoint_3d.gd` - Base waypoint class
- `scripts/npcs/waypoint_npc_final.gd` - Latest waypoint implementation
- `scenes/npcs/npc_base.tscn` - Base scene for NPCs

### Essential Scripts
- All manager scripts (except waypoint_fix_manager)
- All environment scripts
- All UI scripts (except duplicate case_file_ui)
- Player scripts
- Ship scripts
- Evidence scripts

## How to Clean Up

1. **In Godot Editor:**
   - Open the FileSystem dock
   - Navigate to each file
   - Right-click → Delete
   - Confirm deletion

2. **Or use the cleanup script:**
   - Open `scripts/tools/project_cleanup.gd`
   - Run it from Tools → Script Editor → File → Run
   - Review the list
   - Delete files manually

## Space Saved
Approximately 24 files will be removed, cleaning up the project structure significantly.

## Post-Cleanup
After cleanup, you should:
1. Clear Godot's cache (Project → Reload Current Project)
2. Check that all scenes still load properly
3. Test that NPCs still function correctly