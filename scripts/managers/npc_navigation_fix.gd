extends Node

# Simple navigation fix for NPCs
func _ready():
    # Wait for scene to load
    await get_tree().process_frame
    await get_tree().process_frame
    
    print("\n=== NPC NAVIGATION FIX STARTING ===")
    
    # Get all NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("Found ", npcs.size(), " NPCs to fix")
    
    for npc in npcs:
        if not npc:
            continue
            
        print("Fixing NPC: ", npc.name)
        
        # Ensure NPC is visible
        npc.visible = true
        
        # Just log position, don't reset - user has positioned NPCs
        var pos = npc.global_position
        if abs(pos.x) > 15 or abs(pos.z) > 25:
            print("  - NPC at extreme position: ", pos)
        
        # Ensure NPC has proper collision setup
        if npc is CharacterBody3D:
            # Set up basic movement parameters
            npc.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
            npc.floor_stop_on_slope = true
            npc.floor_constant_speed = true
            npc.floor_snap_length = 0.1
            
        # Force NPCs to use simpler navigation
        if npc.has_method("set_meta"):
            npc.set_meta("use_simple_navigation", true)
            
        # Ensure walk speed is reasonable
        if "walk_speed" in npc:
            if npc.walk_speed > 5.0 or npc.walk_speed < 1.0:
                npc.walk_speed = 2.0
                
        # Reset any stuck states
        if npc.has_method("_choose_new_target"):
            npc.call_deferred("_choose_new_target")
    
    print("=== NPC NAVIGATION FIX COMPLETE ===\n")