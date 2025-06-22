@tool
extends EditorScript

# Tool script to generate waypoints for the station
# Run this from Script Editor: File -> Run

func _run():
    var scene_root = get_scene()
    if not scene_root:
        print("No scene open!")
        return
    
    # Find or create Waypoints node
    var waypoints_parent = scene_root.get_node_or_null("Waypoints")
    if not waypoints_parent:
        print("No Waypoints node found!")
        return
    
    # Clear existing waypoints
    for child in waypoints_parent.get_children():
        child.queue_free()
    
    # Define waypoint positions for the station
    var waypoints_data = {
        # Room center waypoints
        "Laboratory_Center": Vector3(0.0, 0.0, 10.0),
        "MedicalBay_Center": Vector3(40.2, 0.0, -2.3),
        "Security_Center": Vector3(-12.3, 0.0, 8.0),
        "Engineering_Center": Vector3(-13.0, 0.0, 10.0),
        "CrewQuarters_Center": Vector3(4.0, 0.0, -28.0),
        "Cafeteria_Center": Vector3(6.0, 0.0, 18.0),
        
        # Main hallway waypoints
        "Hallway_LabExit": Vector3(6.0, 0.0, 4.0),
        "Hallway_Central": Vector3(0.0, 0.0, 4.0),
        "Hallway_East": Vector3(15.0, 0.0, 4.0),
        "Hallway_FarEast": Vector3(25.0, 0.0, 4.0),
        "Hallway_MedicalApproach": Vector3(35.0, 0.0, 3.5),
        "Hallway_West": Vector3(-10.0, 0.0, 4.0),
        "Hallway_SecurityApproach": Vector3(-12.0, 0.0, 4.0),
        
        # South hallway (to crew quarters)
        "Hallway_SouthTurn": Vector3(0.0, 0.0, 0.0),
        "Hallway_South": Vector3(0.0, 0.0, -4.0),
        "Hallway_CrewTurn": Vector3(3.87, 0.0, -4.0),
        "Hallway_CrewApproach": Vector3(3.87, 0.0, -20.0),
        
        # North hallway (to cafeteria)
        "Hallway_CafeteriaApproach": Vector3(6.0, 0.0, 10.0),
        
        # Corner waypoints for smooth navigation
        "Corner_LabMedical": Vector3(10.0, 0.0, 4.0),
        "Corner_LabSecurity": Vector3(-5.0, 0.0, 4.0),
        "Corner_SecurityEngineering": Vector3(-12.5, 0.0, 6.0),
        "Corner_CentralSouth": Vector3(0.0, 0.0, 2.0),
        "Corner_SouthCrew": Vector3(2.0, 0.0, -4.0),
        
        # Additional navigation aids
        "Nav_LabNorth": Vector3(0.0, 0.0, 12.0),
        "Nav_LabSouth": Vector3(0.0, 0.0, 8.0),
        "Nav_MedicalEntry": Vector3(37.0, 0.0, 3.0),
        "Nav_SecurityEntry": Vector3(-12.5, 0.0, 5.5),
        "Nav_CrewEntry": Vector3(3.87, 0.0, -24.0),
        "Nav_CafeteriaEntry": Vector3(6.0, 0.0, 14.0)
    }
    
    # Create waypoint nodes
    for waypoint_name in waypoints_data:
        var waypoint = Node3D.new()
        waypoint.name = waypoint_name
        waypoint.position = waypoints_data[waypoint_name]
        
        # Add to appropriate groups based on name
        if waypoint_name.ends_with("_Center"):
            var room_name = waypoint_name.replace("_Center", "")
            waypoint.add_to_group(room_name + "_Waypoint")
        elif waypoint_name.begins_with("Hallway_"):
            waypoint.add_to_group("hallway_waypoints")
        elif waypoint_name.begins_with("Corner_"):
            waypoint.add_to_group("corner_waypoints")
        elif waypoint_name.begins_with("Nav_"):
            waypoint.add_to_group("navigation_waypoints")
        
        waypoints_parent.add_child(waypoint)
        waypoint.owner = scene_root
        
        # Add a visual indicator in editor
        var debug_mesh = MeshInstance3D.new()
        debug_mesh.name = "DebugVisual"
        var sphere = SphereMesh.new()
        sphere.radius = 0.25
        sphere.height = 0.5
        debug_mesh.mesh = sphere
        
        # Color code by type
        var material = StandardMaterial3D.new()
        if waypoint_name.ends_with("_Center"):
            material.albedo_color = Color.BLUE
        elif waypoint_name.begins_with("Hallway_"):
            material.albedo_color = Color.YELLOW
        elif waypoint_name.begins_with("Corner_"):
            material.albedo_color = Color.ORANGE
        else:
            material.albedo_color = Color.CYAN
        
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        debug_mesh.material_override = material
        debug_mesh.visible = true  # Always visible in editor
        
        waypoint.add_child(debug_mesh)
        debug_mesh.owner = scene_root
    
    print("Generated ", waypoints_data.size(), " waypoints!")
    print("Waypoints created:")
    for name in waypoints_data:
        print("  - ", name, " at ", waypoints_data[name])
    
    # Save the scene
    var packed_scene = PackedScene.new()
    packed_scene.pack(scene_root)
    
    print("\nWaypoints generated successfully!")
    print("Color coding:")
    print("  - Blue: Room centers")
    print("  - Yellow: Hallway waypoints")
    print("  - Orange: Corner waypoints")
    print("  - Cyan: Navigation aids")