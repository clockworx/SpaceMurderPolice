@tool
extends EditorScript

func _run():
    print("=== Force NPC Patrol Movement ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    # Find NPCs
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    # Create clear patrol routes
    var waypoints_node = edited_scene.find_child("Waypoints", true, false)
    if waypoints_node:
        # Remove old waypoints
        for child in waypoints_node.get_children():
            child.queue_free()
    else:
        waypoints_node = Node3D.new()
        waypoints_node.name = "Waypoints"
        edited_scene.add_child(waypoints_node)
        waypoints_node.owner = edited_scene
    
    # Create a large square patrol path
    var patrol_points = [
        Vector3(20, 0.5, 20),    # Northeast
        Vector3(20, 0.5, -20),   # Southeast  
        Vector3(-20, 0.5, -20),  # Southwest
        Vector3(-20, 0.5, 20),   # Northwest
    ]
    
    # Create waypoints
    print("\nCreating patrol waypoints:")
    for i in range(patrol_points.size()):
        var waypoint = Node3D.new()
        waypoint.name = "PatrolPoint_" + str(i)
        waypoint.position = patrol_points[i]
        waypoints_node.add_child(waypoint)
        waypoint.owner = edited_scene
        
        # Large visible marker
        var mesh = MeshInstance3D.new()
        var cylinder = CylinderMesh.new()
        cylinder.height = 5.0
        cylinder.top_radius = 2.0
        cylinder.bottom_radius = 2.0
        mesh.mesh = cylinder
        
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0, 1, 1, 0.7)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.emission_enabled = true
        material.emission = Color(0, 1, 1, 1)
        material.emission_energy = 0.5
        mesh.material_override = material
        
        waypoint.add_child(mesh)
        mesh.owner = edited_scene
        
        print("  - Created waypoint at ", patrol_points[i])
    
    # Configure NPCs
    print("\nConfiguring NPCs for patrol:")
    
    # Get waypoint paths
    var waypoint_paths = []
    for i in range(waypoints_node.get_child_count()):
        waypoint_paths.append(waypoints_node.get_child(i).get_path())
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Force specific settings
            npc.set("current_state", 2)  # PATROL state
            npc.set("waypoint_nodes", waypoint_paths)
            npc.set("current_waypoint_index", 0)
            npc.set("wander_radius", 0.0)  # Disable random wander
            npc.set("use_hybrid_movement", true)
            
            # Move NPC to first waypoint to start
            if waypoint_paths.size() > 0:
                var first_waypoint = waypoints_node.get_child(0)
                npc.position = first_waypoint.position
                npc.position.y = 0.5  # Proper height
            
            print("  - ", npc.name, ": Forced to patrol mode, starting at first waypoint")
    
    print("\n✓ Patrol movement forced!")
    print("\nNPCs should now:")
    print("- Move between the large cyan waypoint cylinders")
    print("- Follow a square patrol pattern")
    print("- Cover much more distance")
    print("\nIf they still don't move properly, the issue is in the NPC movement script itself.")
