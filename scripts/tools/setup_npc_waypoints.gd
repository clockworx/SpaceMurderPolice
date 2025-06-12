@tool
extends EditorScript

func _run():
    print("=== Setting Up NPC Waypoints ===")
    
    # Get the currently open scene
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene is currently open!")
        return
    
    print("Working with scene: ", edited_scene.name)
    
    # Find or create Waypoints node
    var waypoints_node = edited_scene.find_child("Waypoints", true, false)
    if not waypoints_node:
        waypoints_node = Node3D.new()
        waypoints_node.name = "Waypoints"
        edited_scene.add_child(waypoints_node)
        waypoints_node.owner = edited_scene
        print("Created Waypoints node")
    else:
        # Clear existing waypoints
        for child in waypoints_node.get_children():
            child.queue_free()
        print("Cleared existing waypoints")
    
    # Define waypoint positions for different areas
    # Y=0.2 to be on the navmesh
    var waypoint_data = [
        # Medical Bay area
        {"name": "MedicalBay_1", "pos": Vector3(40, 0.2, 0)},
        {"name": "MedicalBay_2", "pos": Vector3(45, 0.2, -5)},
        {"name": "MedicalBay_3", "pos": Vector3(45, 0.2, 5)},
        
        # Laboratory area
        {"name": "Lab_1", "pos": Vector3(0, 0.2, 5)},
        {"name": "Lab_2", "pos": Vector3(-5, 0.2, 8)},
        {"name": "Lab_3", "pos": Vector3(5, 0.2, 8)},
        
        # Engineering area
        {"name": "Engineering_1", "pos": Vector3(-40, 0.2, 5)},
        {"name": "Engineering_2", "pos": Vector3(-35, 0.2, 10)},
        {"name": "Engineering_3", "pos": Vector3(-45, 0.2, 10)},
        
        # Security Office area
        {"name": "Security_1", "pos": Vector3(-10, 0.2, 10)},
        {"name": "Security_2", "pos": Vector3(-15, 0.2, 5)},
        {"name": "Security_3", "pos": Vector3(-15, 0.2, 15)},
        
        # Server Room area (for AI Specialist)
        {"name": "Server_1", "pos": Vector3(20, 0.2, -5)},
        {"name": "Server_2", "pos": Vector3(25, 0.2, -10)},
        {"name": "Server_3", "pos": Vector3(15, 0.2, -10)},
        
        # Central area (common paths)
        {"name": "Central_1", "pos": Vector3(0, 0.2, 0)},
        {"name": "Central_2", "pos": Vector3(10, 0.2, 0)},
        {"name": "Central_3", "pos": Vector3(-10, 0.2, 0)},
    ]
    
    # Create waypoint nodes
    for wp_data in waypoint_data:
        var waypoint = Node3D.new()
        waypoint.name = wp_data.name
        waypoint.position = wp_data.pos
        waypoints_node.add_child(waypoint)
        waypoint.owner = edited_scene
        
        # Add a visual indicator (small sphere)
        var mesh_instance = MeshInstance3D.new()
        var sphere_mesh = SphereMesh.new()
        sphere_mesh.radial_segments = 8
        sphere_mesh.height = 0.5
        sphere_mesh.radius = 0.25
        mesh_instance.mesh = sphere_mesh
        
        # Create material
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(1, 1, 0, 0.5)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mesh_instance.material_override = material
        
        waypoint.add_child(mesh_instance)
        mesh_instance.owner = edited_scene
    
    print("Created ", waypoint_data.size(), " waypoints")
    
    # Now assign waypoints to NPCs
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if npcs_node:
        print("\nAssigning waypoints to NPCs...")
        
        for npc in npcs_node.get_children():
            if not npc is Node3D:
                continue
                
            var assigned_waypoints = []
            
            # Assign waypoints based on NPC name/role
            if npc.name == "MedicalOfficer":
                assigned_waypoints = ["MedicalBay_1", "MedicalBay_2", "MedicalBay_3", "Central_1"]
            elif npc.name == "ChiefScientist":
                assigned_waypoints = ["Lab_1", "Lab_2", "Lab_3", "Central_2"]
            elif npc.name == "Engineer":
                assigned_waypoints = ["Engineering_1", "Engineering_2", "Engineering_3", "Central_3"]
            elif npc.name == "SecurityChief":
                assigned_waypoints = ["Security_1", "Security_2", "Security_3", "Central_1"]
            elif npc.name == "AISpecialist":
                assigned_waypoints = ["Server_1", "Server_2", "Server_3", "Central_2"]
            elif npc.name == "SecurityOfficer":
                assigned_waypoints = ["Security_2", "Central_1", "Central_2", "Central_3"]
            
            # Set waypoint paths if NPC has waypoint_nodes property
            if "waypoint_nodes" in npc:
                var waypoint_paths = []
                for wp_name in assigned_waypoints:
                    var wp_node = waypoints_node.find_child(wp_name, false, false)
                    if wp_node:
                        waypoint_paths.append(wp_node.get_path())
                
                if waypoint_paths.size() > 0:
                    npc.set("waypoint_nodes", waypoint_paths)
                    print("  - Assigned ", waypoint_paths.size(), " waypoints to ", npc.name)
    
    print("\n✓ Waypoint setup complete!")
    print("\nNotes:")
    print("- Waypoints are placed at Y=0.2 to match the navigation mesh")
    print("- Each NPC has area-specific patrol points")
    print("- Yellow spheres show waypoint locations")
    print("- You can hide the waypoint meshes after testing")
