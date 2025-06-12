@tool
extends EditorScript

# Quick navigation setup for NewStation
# This will create a navigation mesh from existing floor geometry

func _run():
	var scene = get_scene()
	if not scene:
		print("No scene open!")
		return
		
	print("Quick Navigation Setup for ", scene.name)
	
	# Find or create NavigationRegion3D
	var nav_region = scene.get_node_or_null("NavigationRegion3D")
	if not nav_region:
		nav_region = NavigationRegion3D.new()
		nav_region.name = "NavigationRegion3D"
		scene.add_child(nav_region)
		nav_region.owner = scene
		print("Created NavigationRegion3D")
	
	# Create navigation mesh with good defaults
	var nav_mesh = NavigationMesh.new()
	
	# Agent settings (for NPCs)
	nav_mesh.agent_radius = 0.8  # Give NPCs more space
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 45.0
	
	# Cell settings (precision)
	nav_mesh.cell_size = 0.2
	nav_mesh.cell_height = 0.2
	
	# Region settings
	nav_mesh.region_min_size = 2.0
	nav_mesh.region_merge_size = 10.0
	
	# Edge settings
	nav_mesh.edge_max_length = 12.0
	nav_mesh.edge_max_error = 1.5
	
	# Detail settings
	nav_mesh.vertices_per_polygon = 6.0
	nav_mesh.detail_sample_distance = 6.0
	nav_mesh.detail_sample_max_error = 1.0
	
	# Filter settings
	nav_mesh.filter_low_hanging_obstacles = true
	nav_mesh.filter_ledge_spans = true
	nav_mesh.filter_walkable_low_height_spans = true
	
	# IMPORTANT: Parse settings
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	nav_mesh.geometry_collision_mask = 0xFFFFFFFF  # Parse all layers initially
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	
	# Apply the navigation mesh
	nav_region.navigation_mesh = nav_mesh
	
	print("Navigation mesh configured!")
	print("\nNOTE: The navigation mesh needs to be baked manually:")
	print("1. Select the NavigationRegion3D node")
	print("2. Click 'Bake NavigationMesh' in the toolbar or Inspector")
	print("3. If baking fails, check that you have floor geometry")
	
	# Try to find existing floor/ground nodes
	var found_floors = false
	for child in scene.get_children():
		if child.name.to_lower().contains("floor") or child.name.to_lower().contains("ground") or child.name == "Station":
			found_floors = true
			print("Found potential floor geometry: ", child.name)
	
	if not found_floors:
		print("\nWARNING: No obvious floor geometry found!")
		print("Navigation mesh may not bake properly without floor collision shapes.")
		print("Consider adding a large invisible floor CollisionShape3D if needed.")
	
	print("\nSetup complete!")