@tool
extends EditorScript

func _run():
	print("=== Adding Navigation Floor to NewStation ===")
	
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
	
	# Check if Station node has proper setup
	var station = root.find_child("Station", true, false)
	if station and station is StaticBody3D:
		print("Found Station StaticBody3D")
		station.collision_layer = 1
		station.collision_mask = 0
		
		# Check for collision shapes
		var has_collision = false
		for child in station.get_children():
			if child is CollisionShape3D:
				has_collision = true
				break
		
		if not has_collision:
			print("WARNING: Station has no CollisionShape3D children!")
	
	# Update NavigationMesh settings for maximum compatibility
	if nav_region.navigation_mesh:
		var nm = nav_region.navigation_mesh
		# Use PARSED_GEOMETRY_BOTH (2) to parse both mesh instances and colliders
		nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
		nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
		nm.geometry_collision_mask = 1  # Only parse layer 1
		
		# Ensure proper agent settings
		nm.cell_size = 0.25
		nm.cell_height = 0.25
		nm.agent_height = 1.75
		nm.agent_radius = 0.5
		nm.agent_max_climb = 0.25
		nm.agent_max_slope = 45.0
		
		# Region settings
		nm.region_min_size = 2.0
		nm.region_merge_size = 10.0
		
		# Edge settings
		nm.edge_max_length = 12.0
		nm.edge_max_error = 1.3
		
		# Voxel settings
		nm.detail_sample_distance = 6.0
		nm.detail_sample_max_error = 1.0
		
		# Filters
		nm.filter_low_hanging_obstacles = true
		nm.filter_ledge_spans = true
		nm.filter_walkable_low_height_spans = true
		
		print("Updated NavigationMesh settings")
	
	# Create a simple floor if absolutely needed
	var create_floor = false  # Set to true if you want to add a debug floor
	
	if create_floor:
		print("\nAdding debug floor...")
		var floor_body = StaticBody3D.new()
		floor_body.name = "DebugNavigationFloor"
		floor_body.collision_layer = 1
		floor_body.collision_mask = 0
		root.add_child(floor_body)
		floor_body.owner = root
		
		# Add collision shape
		var col_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(100, 0.1, 100)
		col_shape.shape = box_shape
		col_shape.transform.origin.y = -0.05
		floor_body.add_child(col_shape)
		col_shape.owner = root
		
		# Add visual mesh
		var mesh_inst = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(100, 0.1, 100)
		mesh_inst.mesh = box_mesh
		mesh_inst.transform.origin.y = -0.05
		floor_body.add_child(mesh_inst)
		mesh_inst.owner = root
		
		print("Debug floor added!")
	
	# Save the scene
	var packed = PackedScene.new()
	packed.pack(root)
	var error = ResourceSaver.save(packed, scene_path)
	
	if error == OK:
		print("\n✓ Scene saved successfully!")
		print("\nNEXT STEPS:")
		print("1. Open NewStation scene in editor")
		print("2. Select NavigationRegion3D")
		print("3. In the toolbar, click 'Bake NavigationMesh'")
		print("4. If baking still doesn't work:")
		print("   - Run the diagnose_navigation.gd script to see what geometry is found")
		print("   - Set create_floor = true in this script and run again")
		print("   - Make sure the Station node has CollisionShape3D children")
	else:
		print("\n✗ ERROR: Failed to save scene: ", error)
	
	root.queue_free()