@tool
extends EditorScript

func _run():
    print("=== Navigation Mesh Diagnostic ===")
    
    var scene_path = "res://scenes/levels/NewStation.tscn"
    var scene = load(scene_path) as PackedScene
    if not scene:
        print("ERROR: Could not load NewStation scene")
        return
        
    var root = scene.instantiate()
    
    # Find NavigationRegion3D
    var nav_region = root.find_child("NavigationRegion3D", true, false)
    if not nav_region:
        print("ERROR: No NavigationRegion3D found!")
        root.queue_free()
        return
    
    print("\n1. NavigationRegion3D Info:")
    print("   - Position: ", nav_region.position)
    print("   - Has navigation_mesh: ", nav_region.navigation_mesh != null)
    
    if nav_region.navigation_mesh:
        var nm = nav_region.navigation_mesh
        print("\n2. NavigationMesh Settings:")
        print("   - cell_size: ", nm.cell_size)
        print("   - cell_height: ", nm.cell_height)
        print("   - agent_height: ", nm.agent_height)
        print("   - agent_radius: ", nm.agent_radius)
        print("   - geometry_parsed_geometry_type: ", nm.geometry_parsed_geometry_type)
        print("   - geometry_collision_mask: ", nm.geometry_collision_mask)
        print("   - geometry_source_geometry_mode: ", nm.geometry_source_geometry_mode)
        print("   - geometry_source_group_name: ", nm.geometry_source_group_name)
    
    # Find all StaticBody3D nodes that could be floors
    print("\n3. Potential Floor Geometry:")
    var static_bodies = []
    _find_static_bodies(root, static_bodies)
    
    for body in static_bodies:
        if body is StaticBody3D:
            print("\n   StaticBody3D: ", body.name)
            print("   - Position: ", body.position)
            print("   - Collision Layer: ", body.collision_layer)
            print("   - Has CollisionShape3D children: ", _has_collision_shape(body))
            
            # Check for MeshInstance3D
            var mesh_found = false
            for child in body.get_children():
                if child is MeshInstance3D and child.mesh:
                    mesh_found = true
                    print("   - Has MeshInstance3D: Yes (", child.mesh.get_class(), ")")
            if not mesh_found:
                print("   - Has MeshInstance3D: No")
    
    # Check the Station node specifically
    var station = root.find_child("Station", true, false)
    if station:
        print("\n4. Station Node Analysis:")
        print("   - Type: ", station.get_class())
        print("   - Position: ", station.position if station is Node3D else "N/A")
        if station is StaticBody3D:
            print("   - Collision Layer: ", station.collision_layer)
        
        # Look for mesh instances
        var meshes = []
        _find_mesh_instances(station, meshes)
        print("   - Found ", meshes.size(), " MeshInstance3D nodes")
        for mesh in meshes:
            if mesh.mesh:
                print("     - ", mesh.name, ": ", mesh.mesh.get_class())
    
    print("\n5. Recommendations:")
    print("   - Ensure floor geometry is on collision layer 1")
    print("   - Floor should have both MeshInstance3D and CollisionShape3D")
    print("   - NavigationMesh geometry_parsed_geometry_type should be PARSED_GEOMETRY_MESH_INSTANCES (0)")
    print("   - Or use PARSED_GEOMETRY_STATIC_COLLIDERS (1) if using collision shapes")
    
    root.queue_free()

func _find_static_bodies(node: Node, result: Array) -> void:
    if node is StaticBody3D:
        result.append(node)
    for child in node.get_children():
        _find_static_bodies(child, result)

func _has_collision_shape(node: Node) -> bool:
    for child in node.get_children():
        if child is CollisionShape3D:
            return true
    return false

func _find_mesh_instances(node: Node, result: Array) -> void:
    if node is MeshInstance3D:
        result.append(node)
    for child in node.get_children():
        _find_mesh_instances(child, result)
