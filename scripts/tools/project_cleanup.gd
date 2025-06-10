@tool
extends EditorScript

# Project Cleanup Tool
# This script identifies and optionally removes unused files from the project
# Run from: Tools > Script Editor > File > Run

func _run():
    print("=== Space Murder Police Project Cleanup ===")
    print("This tool will help identify unused files. Review carefully before deleting!")
    print("")
    
    var files_to_review = {
        "Backup Files": [
            "res://scenes/levels/NewStation.tscn.backup"
        ],
        
        "Test/Debug Scripts": [
            "res://scripts/test/debug_npc_facing.gd",
            "res://scripts/test/npc_state_display.gd",
            "res://scripts/test/saboteur_detection_tuner.gd",
            "res://scripts/test/saboteur_vision_debug.gd",
            "res://scripts/test/test_npc_proximity.gd",
            "res://scripts/test/test_npc_states.gd",
            "res://scripts/test/test_saboteur_detection.gd",
            "res://scripts/test/test_sound_detection.gd",
            "res://scripts/test/toggle_state_labels.gd"
        ],
        
        "Orphaned UID Files (missing scripts)": [
            "res://scripts/npcs/simple_direct_waypoint.gd.uid",
            "res://scripts/npcs/waypoint_debug.gd.uid",
            "res://scripts/npcs/waypoint_npc_collision_fix.gd.uid"
        ],
        
        "Potential Duplicate/Old Waypoint Scripts": [
            # Keeping waypoint_3d.gd as it's the base waypoint
            "res://scripts/npcs/smart_waypoint_npc.gd",  # Older iteration
            "res://scripts/npcs/waypoint_npc_fixed.gd",   # Fixed version, but we have final
            # Keeping waypoint_npc_final.gd as it seems to be the latest
        ],
        
        "Temporary/Migration Tools": [
            "res://scripts/tools/update_npcs_to_unified.gd",
            "res://scripts/managers/waypoint_fix_manager.gd"
        ],
        
        "Duplicate Files": [
            "res://scripts/investigation/case_file_ui.gd"  # Duplicate of ui/case_file_ui.gd
        ],
        
        "Test/Template Scenes": [
            "res://scenes/levels/simple_station.tscn",
            "res://scenes/rooms/room_template.tscn"
        ],
        
        "Potentially Unused (verify before removing)": [
            "res://scripts/levels/unified_station_builder.gd",  # Check if used by NewStation
            "res://scenes/npcs/unified_npc_base.tscn"  # If all NPCs use npc_base.tscn
        ]
    }
    
    print("Files organized by category:")
    print("==================================================")  # 50 equal signs
    
    for category in files_to_review:
        print("\n" + category + ":")
        for file_path in files_to_review[category]:
            if FileAccess.file_exists(file_path):
                print("  ✓ " + file_path + " (exists)")
            else:
                print("  ✗ " + file_path + " (not found)")
    
    print("\n==================================================")  # 50 equal signs
    print("\nRECOMMENDATIONS:")
    print("1. SAFE TO DELETE:")
    print("   - Backup files (.backup)")
    print("   - Orphaned UID files")
    print("   - Test/debug scripts (unless actively debugging)")
    print("   - Duplicate files")
    print("")
    print("2. REVIEW BEFORE DELETING:")
    print("   - Old waypoint scripts (ensure waypoint_npc_final.gd works correctly)")
    print("   - Template scenes (unless needed for future development)")
    print("   - Migration tools (if migration is complete)")
    print("")
    print("3. KEEP:")
    print("   - waypoint_3d.gd (base waypoint class)")
    print("   - waypoint_npc_final.gd (latest waypoint NPC implementation)")
    print("   - All currently functioning systems")
    print("")
    print("To delete files, use the FileSystem dock in Godot Editor")
    print("Right-click on file -> Delete")
    
    # Count total files that could be cleaned
    var total_files = 0
    for category in files_to_review:
        total_files += files_to_review[category].size()
    
    print("\nTotal files identified for review: " + str(total_files))
    
    # Check for empty directories
    print("\nEmpty directories to consider removing:")
    print("  - scenes/navigation/ (empty)")

func check_file_references(file_path: String) -> Array:
    # This would check if file is referenced anywhere
    # For now, return empty array
    return []