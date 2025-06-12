@tool
extends EditorScript

func _run():
    print("=== Enabling NPC Patrol Behavior ===")
    
    # Get the currently open scene
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene is currently open!")
        return
    
    print("Working with scene: ", edited_scene.name)
    
    # Create simple patrol waypoints
    var waypoints_node = edited_scene.find_child("Waypoints", true, false)
    if not waypoints_node:
        waypoints_node = Node3D.new()
        waypoints_node.name = "Waypoints"
        edited_scene.add_child(waypoints_node)
        waypoints_node.owner = edited_scene
    
    # Clear existing waypoints
    for child in waypoints_node.get_children():
        child.queue_free()
    
    # Create a simple triangle patrol pattern
    var patrol_positions = [
        Vector3(5, 0.5, 5),
        Vector3(5, 0.5, -5),
        Vector3(-5, 0.5, 0),
    ]
    
    print("\nCreating patrol waypoints:")
    for i in range(patrol_positions.size()):
        var waypoint = Node3D.new()
        waypoint.name = "Waypoint" + str(i)
        waypoint.position = patrol_positions[i]
        waypoints_node.add_child(waypoint)
        waypoint.owner = edited_scene
        
        # Visual marker
        var mesh = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(0.5, 2, 0.5)
        mesh.mesh = box
        
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(1, 0, 1, 0.7)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mesh.material_override = material
        
        waypoint.add_child(mesh)
        mesh.owner = edited_scene
        
        print("  - Created waypoint at ", patrol_positions[i])
    
    # Update NPCs
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if npcs_node:
        print("\nConfiguring NPCs for patrol:")
        
        # Get waypoint paths
        var waypoint_paths = []
        for i in range(waypoints_node.get_child_count()):
            var wp = waypoints_node.get_child(i)
            waypoint_paths.append(wp.get_path())
        
        for npc in npcs_node.get_children():
            if npc is CharacterBody3D:
                # Set waypoints
                if "waypoint_nodes" in npc:
                    npc.set("waypoint_nodes", waypoint_paths)
                
                # Enable patrol state
                if "current_state" in npc:
                    npc.set("current_state", 2)  # PATROL state
                
                # Set patrol index
                if "current_waypoint_index" in npc:
                    npc.set("current_waypoint_index", 0)
                
                # Disable wandering
                if "wander_radius" in npc:
                    npc.set("wander_radius", 0.0)
                
                print("  - ", npc.name, ": Set to patrol mode with ", waypoint_paths.size(), " waypoints")
    
    print("\n✓ Patrol enabled!")
    print("\nNPCs should now:")
    print("- Move between the purple waypoint markers")
    print("- Follow a triangle patrol pattern")
    print("\nIf they're still stuck:")
    print("- Make sure they're not inside collision geometry")
    print("- Check that the navigation mesh is properly baked")
