@tool
extends EditorScript

# Tool script to help configure NavigationMesh settings for better baking
# To use: Open this script and press File -> Run

func _run():
	print("=== Navigation Mesh Setup Tool ===")
	
	# Find NavigationRegion3D in the scene
	var nav_region = _find_navigation_region()
	if not nav_region:
		print("ERROR: No NavigationRegion3D found in scene!")
		return
	
	print("Found NavigationRegion3D: ", nav_region.name)
	
	# Create or get NavigationMesh
	var nav_mesh = nav_region.navigation_mesh
	if not nav_mesh:
		nav_mesh = NavigationMesh.new()
		nav_region.navigation_mesh = nav_mesh
		print("Created new NavigationMesh")
	
	# Configure optimal settings for indoor space station
	print("\nApplying optimal settings for space station...")
	
	# Cell/Voxel settings - smaller values = more detail
	nav_mesh.cell_size = 0.1  # Smaller for more precision (was 0.25)
	nav_mesh.cell_height = 0.05  # Smaller for better vertical precision
	
	# Agent settings - match your character size
	nav_mesh.agent_height = 1.8  # Typical human height
	nav_mesh.agent_radius = 0.3  # Narrower to fit through doors
	nav_mesh.agent_max_climb = 0.3  # Small steps/ramps
	nav_mesh.agent_max_slope = 30.0  # Moderate slopes
	
	# Region settings - helps connect separate areas
	nav_mesh.region_min_size = 2.0  # Smaller to capture small rooms
	nav_mesh.region_merge_size = 10.0  # Moderate merging
	
	# Edge settings
	nav_mesh.edge_max_length = 5.0  # Shorter edges for better paths
	nav_mesh.edge_max_error = 0.5  # Tighter error tolerance
	
	# Detail settings
	nav_mesh.detail_sample_distance = 3.0  # More detailed sampling
	nav_mesh.detail_sample_max_error = 0.5  # Lower error
	
	# Geometry parsing - CRITICAL for proper baking
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1  # Only environment layer
	
	# Source geometry filters - what to include
	nav_mesh.filter_low_hanging_obstacles = true
	nav_mesh.filter_ledge_spans = true
	nav_mesh.filter_walkable_low_height_spans = true
	
	print("\nSettings applied!")
	print("\nIMPORTANT TIPS:")
	print("1. Make sure your floor has StaticBody3D with CollisionShape3D")
	print("2. Collision layer should be set to 1 (environment)")
	print("3. Walls should also have collision shapes")
	print("4. Doors should have small gaps or be excluded from baking")
	print("\nNow click 'Bake NavigationMesh' in the inspector!")
	
	# Print current settings for verification
	print("\nCurrent settings:")
	print("  Cell size: ", nav_mesh.cell_size)
	print("  Agent radius: ", nav_mesh.agent_radius)
	print("  Agent height: ", nav_mesh.agent_height)
	print("  Geometry type: ", nav_mesh.geometry_parsed_geometry_type)
	print("  Collision mask: ", nav_mesh.geometry_collision_mask)

func _find_navigation_region() -> NavigationRegion3D:
	var edited_scene = get_editor_interface().get_edited_scene_root()
	if not edited_scene:
		return null
	
	# Search recursively
	return _find_node_recursive(edited_scene, NavigationRegion3D) as NavigationRegion3D

func _find_node_recursive(node: Node, type) -> Node:
	if node.get_class() == type.get_class_name():
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, type)
		if result:
			return result
	
	return null