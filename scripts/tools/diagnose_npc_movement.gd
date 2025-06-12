@tool
extends EditorScript

func _run():
    print("=== Diagnose NPC Movement Issues ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    # Check navigation mesh
    var nav_region = edited_scene.find_child("NavigationRegion3D", true, false)
    if nav_region:
        var nav_mesh = nav_region.navigation_mesh
        if nav_mesh:
            print("\nNavigation Mesh Status:")
            print("- Cell size: ", nav_mesh.cell_size)
            print("- Cell height: ", nav_mesh.cell_height)
            print("- Agent height: ", nav_mesh.agent_height)
            print("- Agent radius: ", nav_mesh.agent_radius)
            print("- Has polygon data: ", nav_mesh.get_polygon_count() > 0)
        else:
            print("\nWARNING: NavigationRegion3D has no navigation mesh!")
    else:
        print("\nWARNING: No NavigationRegion3D found!")
    
    print("\n==================================================")
    print("NPC DIAGNOSTICS:")
    print("==================================================")
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            print("\n[", npc.name, "]")
            print("Position: ", npc.position)
            print("On floor: ", npc.is_on_floor() if npc.has_method("is_on_floor") else "N/A")
            
            # Check script
            var script = npc.get_script()
            if script:
                print("Script: ", script.resource_path.get_file())
            else:
                print("Script: NONE!")
            
            # Check physics processing
            print("Physics processing: ", npc.is_physics_processing())
            
            # Check exported properties
            if "use_hybrid_movement" in npc:
                print("use_hybrid_movement: ", npc.get("use_hybrid_movement"))
            if "use_navmesh" in npc:
                print("use_navmesh: ", npc.get("use_navmesh"))
            if "current_state" in npc:
                var state = npc.get("current_state")
                var state_names = ["PATROL", "IDLE", "TALK", "WANDER", "INVESTIGATE", "RETURN_TO_PATROL"]
                print("current_state: ", state, " (", state_names[state] if state < state_names.size() else "UNKNOWN", ")")
            if "walk_speed" in npc:
                print("walk_speed: ", npc.get("walk_speed"))
            if "wander_radius" in npc:
                print("wander_radius: ", npc.get("wander_radius"))
            if "waypoint_nodes" in npc:
                var waypoints = npc.get("waypoint_nodes")
                print("waypoint_nodes: ", waypoints.size(), " waypoints")
                if waypoints.size() > 0:
                    for i in range(min(3, waypoints.size())):
                        print("  - Waypoint ", i, ": ", waypoints[i])
            
            # Check children
            print("Children:")
            for child in npc.get_children():
                if child is NavigationAgent3D:
                    print("  - NavigationAgent3D (enabled: ", child.avoidance_enabled, ")")
                    print("    - Target: ", child.target_position)
                    print("    - Is navigating: ", not child.is_navigation_finished())
                elif child.name == "SaboteurPatrolAI":
                    print("  - SaboteurPatrolAI (active: ", child.get("is_active") if "is_active" in child else "?", ")")
                elif child.name == "SimplePatrolMovement":
                    print("  - SimplePatrolMovement")
                elif child.get_class() == "Node" and child.has_method("move_to_position"):
                    print("  - Movement system: ", child.get_class())
    
    print("\n==================================================")
    print("DIAGNOSTIC SUMMARY:")
    print("==================================================")
    print("\nCommon issues to check:")
    print("1. NPCs might not have physics processing enabled")
    print("2. Navigation mesh might not be properly baked")
    print("3. Movement systems might not be calling move_and_slide()")
    print("4. NPCs might be stuck in IDLE state")
    print("5. Waypoints might be invalid or null")
