@tool
extends EditorScript

func _run():
    print("=== Complete NPC Fix ===")
    
    # Get the currently open scene
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene is currently open!")
        return
    
    print("Working with scene: ", edited_scene.name)
    
    # Find NPCs node
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs node found!")
        return
    
    # 1. Fix NPC positions - put them on the ground
    print("\n1. Fixing NPC positions:")
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Set to ground level (navigation mesh is at Y=0.188)
            npc.position.y = 1.0  # Character height above ground
            
            # Ensure gravity is enabled
            if "motion_mode" in npc:
                npc.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
            
            print("   - ", npc.name, " positioned at Y=", npc.position.y)
    
    # 2. Fix the chief scientist transform (it has rotation)
    var chief_scientist = npcs_node.find_child("ChiefScientist", false, false)
    if chief_scientist:
        # Reset rotation to identity
        chief_scientist.transform.basis = Basis.IDENTITY
        print("   - Reset ChiefScientist rotation")
    
    # 3. Create simple waypoints
    var waypoints_node = edited_scene.find_child("Waypoints", true, false)
    if not waypoints_node:
        waypoints_node = Node3D.new()
        waypoints_node.name = "Waypoints"
        edited_scene.add_child(waypoints_node)
        waypoints_node.owner = edited_scene
    
    # Clear old waypoints
    for child in waypoints_node.get_children():
        child.queue_free()
    
    # Create waypoints for each NPC's area
    var waypoint_sets = {
        "MedicalOfficer": [
            Vector3(30, 0.5, 0),
            Vector3(35, 0.5, 5),
            Vector3(40, 0.5, 0),
            Vector3(35, 0.5, -5)
        ],
        "ChiefScientist": [
            Vector3(-5, 0.5, -5),
            Vector3(5, 0.5, -5),
            Vector3(5, 0.5, 5),
            Vector3(-5, 0.5, 5)
        ],
        "Engineer": [
            Vector3(-40, 0.5, 0),
            Vector3(-35, 0.5, 5),
            Vector3(-30, 0.5, 5),
            Vector3(-35, 0.5, 0)
        ],
        "SecurityChief": [
            Vector3(-15, 0.5, 0),
            Vector3(-10, 0.5, 5),
            Vector3(-5, 0.5, 5),
            Vector3(-10, 0.5, 0)
        ],
        "AISpecialist": [
            Vector3(15, 0.5, -10),
            Vector3(25, 0.5, -10),
            Vector3(25, 0.5, -5),
            Vector3(15, 0.5, -5)
        ],
        "SecurityOfficer": [
            Vector3(0, 0.5, 10),
            Vector3(0, 0.5, -10),
            Vector3(-10, 0.5, 0),
            Vector3(10, 0.5, 0)
        ]
    }
    
    print("\n2. Creating waypoints:")
    for npc_name in waypoint_sets:
        var positions = waypoint_sets[npc_name]
        for i in range(positions.size()):
            var waypoint = Node3D.new()
            waypoint.name = npc_name + "_WP_" + str(i)
            waypoint.position = positions[i]
            waypoints_node.add_child(waypoint)
            waypoint.owner = edited_scene
            print("   - Created ", waypoint.name, " at ", positions[i])
    
    # 4. Assign waypoints to NPCs and fix their properties
    print("\n3. Configuring NPCs:")
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D and npc.name in waypoint_sets:
            # Get this NPC's waypoints
            var waypoint_paths = []
            for i in range(4):  # Each NPC has 4 waypoints
                var wp_name = npc.name + "_WP_" + str(i)
                var wp = waypoints_node.find_child(wp_name, false, false)
                if wp:
                    waypoint_paths.append(wp.get_path())
            
            # Set waypoints
            if "waypoint_nodes" in npc:
                npc.set("waypoint_nodes", waypoint_paths)
                print("   - ", npc.name, ": Assigned ", waypoint_paths.size(), " waypoints")
            
            # Set to PATROL state
            if "current_state" in npc:
                npc.set("current_state", 2)  # PATROL
            
            # Set waypoint index
            if "current_waypoint_index" in npc:
                npc.set("current_waypoint_index", 0)
            
            # Set proper wander radius
            if "wander_radius" in npc:
                npc.set("wander_radius", 2.0)
            
            # Ensure use_hybrid_movement is true
            if "use_hybrid_movement" in npc:
                npc.set("use_hybrid_movement", true)
    
    print("\n✓ Complete fix applied!")
    print("\nWhat was fixed:")
    print("- NPCs positioned at Y=1.0 (proper height)")
    print("- Each NPC has their own patrol route")
    print("- NPCs set to PATROL state")
    print("- ChiefScientist rotation reset")
    print("\nNPCs should now walk on the ground and patrol their areas.")
