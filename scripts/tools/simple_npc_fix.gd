@tool
extends EditorScript

func _run():
    print("=== Simple NPC Movement Fix ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    # Just make NPCs stand still at their positions
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        return
    
    print("\nSetting NPCs to stationary mode:")
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Set to IDLE state
            if "current_state" in npc:
                npc.set("current_state", 0)  # IDLE
            
            # Clear waypoints
            if "waypoint_nodes" in npc:
                npc.set("waypoint_nodes", [])
            
            # Disable wandering
            if "wander_radius" in npc:
                npc.set("wander_radius", 0.0)
            
            # Ensure they're grounded
            if npc.has_method("move_and_slide"):
                npc.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
            
            # Set floor position
            npc.position.y = 1.0
            
            print("  - ", npc.name, ": Set to stationary at Y=", npc.position.y)
    
    print("\n✓ NPCs set to stationary mode")
    print("They will now stand in place without floating or moving.")
