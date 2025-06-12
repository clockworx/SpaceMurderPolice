@tool
extends EditorScript

func _run():
    print("=== Fixing Station Navigation Setup ===")
    
    # Get the currently open scene
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene is currently open!")
        return
    
    print("Working with scene: ", edited_scene.name)
    
    # Check Station setup
    var station = edited_scene.find_child("Station", true, false)
    if station:
        print("\n1. Station Info:")
        print("   - Position: ", station.position)
        print("   - Is StaticBody3D: ", station is StaticBody3D)
        if station is StaticBody3D:
            print("   - Collision Layer: ", station.collision_layer)
            print("   - Collision Mask: ", station.collision_mask)
            
            # The station should be on layer 1 for navigation
            station.collision_layer = 1
            station.collision_mask = 0
            print("   - Updated collision layer to 1")
    
    # Check the navigation floor
    var nav_floor = edited_scene.find_child("NavigationFloor", true, false)
    if nav_floor:
        print("\n2. NavigationFloor (CSGBox3D) Info:")
        print("   - Position: ", nav_floor.position)
        print("   - Size: ", nav_floor.size if "size" in nav_floor else "N/A")
        # The floor is at Y=-0.5 with size 200x1x200, so top is at Y=0
    
    # Adjust NPCs to proper height
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if npcs_node:
        print("\n3. Adjusting NPC heights to floor level:")
        
        # The navigation mesh is baked on the CSGBox3D floor at Y=0
        # NPCs should be slightly above this
        var proper_height = 1.0  # 1 meter above floor
        
        for npc in npcs_node.get_children():
            if npc is CharacterBody3D:
                var old_pos = npc.position
                npc.position.y = proper_height
                
                # Also disable wandering to prevent random movement
                if "wander_radius" in npc:
                    npc.set("wander_radius", 0.0)
                if "current_state" in npc:
                    npc.set("current_state", 0)  # IDLE
                
                print("   - ", npc.name, ": Y=", old_pos.y, " -> Y=", proper_height)
    
    # Create test waypoints in definitely open areas
    var waypoints_node = edited_scene.find_child("Waypoints", true, false)
    if not waypoints_node:
        waypoints_node = Node3D.new()
        waypoints_node.name = "Waypoints"
        edited_scene.add_child(waypoints_node)
        waypoints_node.owner = edited_scene
    
    # Clear old waypoints
    for child in waypoints_node.get_children():
        child.queue_free()
    
    # Create test waypoints in open areas
    var test_positions = [
        {"name": "Center", "pos": Vector3(0, 1.0, 0)},
        {"name": "North", "pos": Vector3(0, 1.0, 20)},
        {"name": "South", "pos": Vector3(0, 1.0, -20)},
        {"name": "East", "pos": Vector3(20, 1.0, 0)},
        {"name": "West", "pos": Vector3(-20, 1.0, 0)},
    ]
    
    print("\n4. Creating test waypoints:")
    for wp_data in test_positions:
        var waypoint = Node3D.new()
        waypoint.name = wp_data.name + "_TestWaypoint"
        waypoint.position = wp_data.pos
        waypoints_node.add_child(waypoint)
        waypoint.owner = edited_scene
        
        # Visual marker
        var mesh = MeshInstance3D.new()
        var cylinder = CylinderMesh.new()
        cylinder.height = 3.0
        cylinder.top_radius = 1.0
        cylinder.bottom_radius = 1.0
        mesh.mesh = cylinder
        
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(1, 0, 0, 0.5)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.emission_enabled = true
        material.emission = Color(1, 0, 0, 1)
        material.emission_energy = 0.3
        mesh.material_override = material
        
        waypoint.add_child(mesh)
        mesh.owner = edited_scene
        
        print("   - Created waypoint at ", wp_data.pos)
    
    print("\n✓ Navigation setup fixed!")
    print("\nKey changes:")
    print("- Station collision layer set to 1")
    print("- NPCs raised to Y=1.0 (above navigation floor)")
    print("- Wander behavior disabled")
    print("- Test waypoints created in open areas")
    print("\nThe red cylinders show safe waypoint positions.")
