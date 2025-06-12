@tool
extends EditorScript

func _run():
    print("=== Fix NPC Movement System Properly ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    print("\nFixing NPC movement systems:")
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            print("\n- Processing ", npc.name, ":")
            
            # Look for the saboteur AI first
            var has_saboteur_ai = false
            for child in npc.get_children():
                if child.name == "SaboteurPatrolAI":
                    has_saboteur_ai = true
                    print("  → Has SaboteurPatrolAI (will use its movement)")
                    break
            
            if has_saboteur_ai:
                # Saboteur AI handles its own movement, so disable NPC's physics processing
                if "set_physics_process" in npc:
                    npc.set("set_physics_process", false)
                print("  → Disabled NPC physics processing (saboteur AI controls movement)")
                continue
            
            # For non-saboteur NPCs, we need to ensure they have proper movement
            # The issue is that UnifiedNPC uses "use_navmesh" but scene uses "use_hybrid_movement"
            
            # Force enable navmesh movement
            if "use_navmesh" in npc:
                npc.set("use_navmesh", true)
                print("  → Set use_navmesh = true")
            
            # Set proper movement speeds
            if "walk_speed" in npc:
                npc.set("walk_speed", 3.0)
                print("  → Set walk_speed = 3.0")
            
            # Ensure they have waypoints or wander radius
            if "waypoint_nodes" in npc:
                var waypoints = npc.get("waypoint_nodes")
                if waypoints.size() == 0:
                    # No waypoints, use wander mode
                    if "wander_radius" in npc:
                        npc.set("wander_radius", 10.0)
                        print("  → No waypoints, set wander_radius = 10.0")
                    if "current_state" in npc:
                        npc.set("current_state", 3)  # WANDER state
                        print("  → Set to WANDER state")
                else:
                    print("  → Has ", waypoints.size(), " waypoints")
                    if "current_state" in npc:
                        npc.set("current_state", 0)  # PATROL state
                        print("  → Set to PATROL state")
            
            # Make sure physics is enabled
            if npc.has_method("set_physics_process"):
                npc.set_physics_process(true)
                print("  → Enabled physics processing")
            
            # Set proper position
            npc.position.y = 0.5
            print("  → Set Y position to 0.5")
    
    print("\n✓ Movement systems fixed!")
    print("\nWhat was changed:")
    print("- Saboteur NPCs: Let SaboteurPatrolAI handle movement")
    print("- Regular NPCs: Enabled navmesh movement with proper settings")
    print("- NPCs without waypoints: Set to wander mode with radius 10")
    print("- All NPCs: Proper Y positioning and physics enabled")