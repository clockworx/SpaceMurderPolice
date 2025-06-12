@tool
extends EditorScript

# Complete setup for NewStation NPCs and Navigation
# Run this with NewStation.tscn open

func _run():
    var scene = get_scene()
    if not scene:
        print("No scene open!")
        return
    
    print("=== Complete NewStation Setup ===\n")
    
    # Step 1: Fix script errors by ensuring NPCs use base NPC scene
    print("Step 1: Updating NPCs to use hybrid movement...")
    var npcs_node = scene.get_node_or_null("NPCs")
    if npcs_node:
        for npc in npcs_node.get_children():
            if npc.has_method("set"):
                # Core movement settings
                npc.set("use_hybrid_movement", true)
                npc.set("use_waypoints", false)
                npc.set("wander_radius", 5.0)
                npc.set("current_state", 1)  # IDLE
                
                # Collision settings
                npc.set("collision_layer", 4)  # Interactable
                npc.set("collision_mask", 1)   # Collide with environment
                
                print("  - Updated ", npc.name)
    
    # Step 2: Set up NavigationRegion3D
    print("\nStep 2: Setting up Navigation...")
    var nav_region = scene.get_node_or_null("NavigationRegion3D")
    if not nav_region:
        nav_region = NavigationRegion3D.new()
        nav_region.name = "NavigationRegion3D"
        scene.add_child(nav_region)
        nav_region.owner = scene
    
    # Create optimized navigation mesh for space station
    var nav_mesh = NavigationMesh.new()
    
    # Agent configuration for human-sized NPCs
    nav_mesh.agent_radius = 0.6
    nav_mesh.agent_height = 1.8
    nav_mesh.agent_max_climb = 0.4
    nav_mesh.agent_max_slope = 45.0
    
    # Mesh generation settings - MUST match project settings!
    nav_mesh.cell_size = 0.25  # Default Godot cell size
    nav_mesh.cell_height = 0.25  # Default Godot cell height
    nav_mesh.region_min_size = 2.0
    nav_mesh.region_merge_size = 10.0
    nav_mesh.edge_max_length = 12.0
    nav_mesh.edge_max_error = 1.3
    nav_mesh.vertices_per_polygon = 6.0
    nav_mesh.detail_sample_distance = 6.0
    nav_mesh.detail_sample_max_error = 1.0
    
    # Filtering
    nav_mesh.filter_low_hanging_obstacles = true
    nav_mesh.filter_ledge_spans = true
    nav_mesh.filter_walkable_low_height_spans = true
    
    # CRITICAL: Set up geometry parsing
    nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
    nav_mesh.geometry_collision_mask = 1  # Only environment layer
    nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
    nav_mesh.geometry_source_group_name = ""  # Parse all
    
    nav_region.navigation_mesh = nav_mesh
    
    # Step 3: Create navigation geometry if needed
    print("\nStep 3: Checking navigation geometry...")
    
    # Check if Station node has collision
    var station_node = scene.get_node_or_null("Station")
    if station_node:
        print("  - Found Station node with collision")
        # Make sure station is on the right collision layer
        if station_node.has_method("set"):
            station_node.set("collision_layer", 1)  # Environment layer
            station_node.set("collision_mask", 0)   # Don't need to collide with anything
    
    # Add a navigation floor helper if needed
    var nav_floor = nav_region.get_node_or_null("NavigationFloor")
    if not nav_floor:
        print("  - Creating navigation floor helper...")
        
        # Create an invisible floor for navigation
        var floor_body = StaticBody3D.new()
        floor_body.name = "NavigationFloor"
        floor_body.collision_layer = 1  # Environment layer
        floor_body.collision_mask = 0
        
        var floor_shape = CollisionShape3D.new()
        var box_shape = BoxShape3D.new()
        box_shape.size = Vector3(150, 0.1, 150)  # Large floor
        floor_shape.shape = box_shape
        floor_shape.position = Vector3(0, -0.05, 0)  # Just below ground level
        
        floor_body.add_child(floor_shape)
        nav_region.add_child(floor_body)
        floor_body.owner = scene
        floor_shape.owner = scene
        
        print("  - Added navigation floor")
    
    print("\n=== SETUP COMPLETE ===")
    print("\nIMPORTANT - Manual steps required:")
    print("1. Save the scene (Ctrl+S)")
    print("2. Select the NavigationRegion3D node")
    print("3. In the toolbar, click 'Bake NavigationMesh'")
    print("   (or in Inspector, scroll down and click the button)")
    print("4. Wait for baking to complete (check console)")
    print("5. Save the scene again")
    print("\nThe navigation mesh should now work with the hybrid movement system!")
    
    # Optional: Add debug visualization
    var debug_instance = MeshInstance3D.new()
    debug_instance.name = "NavMeshDebugView"
    var debug_mesh = BoxMesh.new()
    debug_mesh.size = Vector3(0.1, 0.1, 0.1)
    debug_instance.mesh = debug_mesh
    debug_instance.visible = false  # Hidden by default
    nav_region.add_child(debug_instance)
    debug_instance.owner = scene
    
    print("\nTip: You can enable NavMeshDebugView to see the navigation mesh")
