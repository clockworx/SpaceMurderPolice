@tool
extends EditorScript

# This script sets up NavigationRegion3D for NewStation
# Run from Script Editor with NewStation.tscn open

func _run():
	var scene = get_scene()
	if not scene or scene.name != "NewStation":
		print("Please open NewStation.tscn first!")
		return
	
	print("Setting up Navigation for NewStation...")
	
	# Check if NavigationRegion3D already exists
	var nav_region = scene.get_node_or_null("NavigationRegion3D")
	if not nav_region:
		print("Creating NavigationRegion3D...")
		nav_region = NavigationRegion3D.new()
		nav_region.name = "NavigationRegion3D"
		scene.add_child(nav_region)
		nav_region.owner = scene
	
	# Create or update navigation mesh
	var nav_mesh = nav_region.navigation_mesh
	if not nav_mesh:
		print("Creating NavigationMesh...")
		nav_mesh = NavigationMesh.new()
		nav_region.navigation_mesh = nav_mesh
	
	# Configure navigation mesh parameters for indoor space station
	nav_mesh.agent_radius = 0.6  # Slightly larger than default for better NPC spacing
	nav_mesh.agent_height = 1.8  # Human height
	nav_mesh.agent_max_climb = 0.3  # Small step height
	nav_mesh.agent_max_slope = 45.0  # Reasonable slope
	nav_mesh.cell_size = 0.1  # Smaller cells for more precise navigation
	nav_mesh.cell_height = 0.1
	nav_mesh.region_min_size = 2.0  # Minimum region size
	nav_mesh.region_merge_size = 10.0  # Merge small regions
	nav_mesh.edge_max_length = 12.0
	nav_mesh.edge_max_error = 1.3
	nav_mesh.vertices_per_polygon = 6.0
	nav_mesh.detail_sample_distance = 6.0
	nav_mesh.detail_sample_max_error = 1.0
	
	# Set up filter settings
	nav_mesh.filter_low_hanging_obstacles = true
	nav_mesh.filter_ledge_spans = true
	nav_mesh.filter_walkable_low_height_spans = true
	
	# Geometry settings - parse from mesh instances
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	nav_mesh.geometry_collision_mask = 1  # Only parse collision layer 1 (environment)
	
	print("Navigation mesh configured!")
	print("\nIMPORTANT: Manual steps required:")
	print("1. Select the NavigationRegion3D node")
	print("2. In the Inspector, click 'Bake NavigationMesh'")
	print("3. Wait for baking to complete")
	print("4. Save the scene")
	
	# Try to add some visual geometry for the nav mesh if it doesn't exist
	var nav_geometry = nav_region.get_node_or_null("NavMeshGeometry")
	if not nav_geometry:
		print("\nCreating navigation geometry helper...")
		
		# Create a CSG combiner to define walkable areas
		var csg_combiner = CSGCombiner3D.new()
		csg_combiner.name = "NavMeshGeometry"
		csg_combiner.use_collision = true
		csg_combiner.collision_layer = 1
		nav_region.add_child(csg_combiner)
		csg_combiner.owner = scene
		
		# Add a large floor box
		var floor_box = CSGBox3D.new()
		floor_box.name = "StationFloor"
		floor_box.size = Vector3(100, 0.2, 100)  # Large floor area
		floor_box.position = Vector3(0, -0.1, 0)
		csg_combiner.add_child(floor_box)
		floor_box.owner = scene
		
		print("Added navigation floor geometry")
		print("You may need to adjust the floor size to match your station")
	
	# Also ensure NPCs are properly configured
	var npcs_node = scene.get_node_or_null("NPCs")
	if npcs_node:
		for npc in npcs_node.get_children():
			if npc.has_method("set"):
				# Make sure NPCs are on the right layers
				npc.set("collision_layer", 4)  # NPCs on layer 3 (bit 2)
				npc.set("collision_mask", 1)   # Collide with environment
		print("\nNPC collision layers verified")
	
	print("\n=== Setup Complete ===")
	print("Remember to bake the navigation mesh!")