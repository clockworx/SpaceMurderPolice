@tool
extends EditorScript

func _run():
    print("=== Final NPC Movement Fix ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    print("\nFixing NPC movement issues:")
    
    # Create waypoints for NPCs without them
    var waypoints_node = edited_scene.find_child("Waypoints", true, false)
    if not waypoints_node:
        waypoints_node = Node3D.new()
        waypoints_node.name = "Waypoints"
        edited_scene.add_child(waypoints_node)
        waypoints_node.owner = edited_scene
        print("Created Waypoints node")
    
    # Create shared waypoints
    var shared_waypoints = []
    var waypoint_positions = [
        Vector3(10, 0.5, 10),
        Vector3(10, 0.5, -10),
        Vector3(-10, 0.5, -10),
        Vector3(-10, 0.5, 10)
    ]
    
    for i in range(waypoint_positions.size()):
        var wp = Node3D.new()
        wp.name = "SharedWaypoint_" + str(i)
        wp.position = waypoint_positions[i]
        waypoints_node.add_child(wp)
        wp.owner = edited_scene
        shared_waypoints.append(wp)
    
    print("Created shared waypoints")
    
    # Fix each NPC
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            print("\nProcessing ", npc.name, ":")
            
            # Check for saboteur AI
            var has_saboteur_ai = false
            for child in npc.get_children():
                if child.name == "SaboteurPatrolAI":
                    has_saboteur_ai = true
                    print("  - Has SaboteurPatrolAI (skipping)")
                    # Make sure saboteur AI is active
                    if child.has_method("set_active"):
                        child.set("is_active", true)
                        child.set_physics_process(true)
                    break
            
            if has_saboteur_ai:
                continue
            
            # For regular NPCs
            # 1. Force hybrid movement off and use direct navmesh
            if "use_hybrid_movement" in npc:
                npc.set("use_hybrid_movement", false)
                print("  - Disabled hybrid movement")
            
            if "use_navmesh" in npc:
                npc.set("use_navmesh", true)
                print("  - Enabled navmesh movement")
            
            # 2. Set movement parameters
            if "walk_speed" in npc:
                npc.set("walk_speed", 3.5)
                print("  - Set walk_speed = 3.5")
            
            # 3. Set waypoints if none exist
            if "waypoint_nodes" in npc:
                var current_waypoints = npc.get("waypoint_nodes")
                if current_waypoints.size() == 0:
                    # Assign shared waypoints
                    var wp_paths = []
                    for wp in shared_waypoints:
                        wp_paths.append(wp.get_path())
                    npc.set("waypoint_nodes", wp_paths)
                    npc.set("use_waypoints", true)
                    print("  - Assigned shared waypoints")
            
            # 4. Set to PATROL state
            if "current_state" in npc:
                npc.set("current_state", 0)  # PATROL
                print("  - Set to PATROL state")
            
            # 5. Disable wander to force waypoint usage
            if "wander_radius" in npc:
                npc.set("wander_radius", 0.0)
                print("  - Disabled wander radius")
            
            # 6. Fix position
            npc.position.y = 0.5
            print("  - Fixed Y position")
            
            # 7. Ensure NavigationAgent3D exists
            var has_nav_agent = false
            for child in npc.get_children():
                if child is NavigationAgent3D:
                    has_nav_agent = true
                    # Configure nav agent
                    child.path_desired_distance = 0.5
                    child.target_desired_distance = 1.0
                    child.avoidance_enabled = true
                    child.radius = 0.5
                    child.height = 1.75
                    print("  - Configured NavigationAgent3D")
                    break
            
            if not has_nav_agent:
                var nav_agent = NavigationAgent3D.new()
                nav_agent.path_desired_distance = 0.5
                nav_agent.target_desired_distance = 1.0
                nav_agent.avoidance_enabled = true
                nav_agent.radius = 0.5
                nav_agent.height = 1.75
                npc.add_child(nav_agent)
                nav_agent.owner = edited_scene
                print("  - Added NavigationAgent3D")
    
    print("\n✓ Movement fix complete!")
    print("\nWhat was done:")
    print("- Created shared waypoints for all NPCs")
    print("- Disabled hybrid movement (seems buggy)")
    print("- Enabled direct navmesh movement")
    print("- Set proper movement speeds")
    print("- Ensured all NPCs have NavigationAgent3D")
    print("- Set NPCs to PATROL state with waypoints")
    print("\nNPCs should now move properly!")
