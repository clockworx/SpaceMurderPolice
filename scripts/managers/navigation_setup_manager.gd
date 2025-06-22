extends Node
class_name NavigationSetupManager

# This manager sets up navigation mesh for the level
# It can either use pre-baked navigation or generate it dynamically

@export var auto_generate_navmesh: bool = false  # Disabled - use pre-baked NavMesh
@export var navigation_mesh_settings: NavigationMesh

var navigation_region: NavigationRegion3D

func _ready():
	add_to_group("navigation_setup_manager")
	
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Check if NavigationRegion3D already exists
	navigation_region = get_tree().get_first_node_in_group("navigation_region")
	
	if not navigation_region:
		# Look for existing NavigationRegion3D in the scene
		var scene_root = get_tree().current_scene
		for child in scene_root.get_children():
			if child is NavigationRegion3D:
				navigation_region = child
				break
	
	if not navigation_region:
		# Try one more method to find it
		var regions = NavigationServer3D.get_maps()
		if regions.size() > 0:
			print("NavigationSetupManager: Found ", regions.size(), " navigation maps via NavigationServer3D")
			navigation_region = get_tree().get_first_node_in_group("NavigationRegion3D")
	
	if not navigation_region and auto_generate_navmesh:
		print("NavigationSetupManager: Creating NavigationRegion3D...")
		_create_navigation_region()
	elif navigation_region:
		print("NavigationSetupManager: Found existing NavigationRegion3D")
		_ensure_navigation_links_connected()
	else:
		print("NavigationSetupManager: No NavigationRegion3D found and auto-generate is disabled")
		# Still check for navigation links
		_ensure_navigation_links_connected()

func _create_navigation_region():
	var scene_root = get_tree().current_scene
	
	# Create NavigationRegion3D
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "NavigationRegion3D"
	navigation_region.add_to_group("navigation_region")
	scene_root.add_child(navigation_region)
	
	# Create NavigationMesh
	var nav_mesh = NavigationMesh.new()
	
	# Configure navigation mesh settings - CENTERED PATHS
	nav_mesh.cell_size = 0.1  # Smaller for better detail
	nav_mesh.cell_height = 0.05  # More precise vertical
	nav_mesh.agent_height = 1.8  # Human height
	nav_mesh.agent_radius = 0.8  # LARGER radius creates more centered paths
	nav_mesh.agent_max_climb = 0.3  # Small steps
	nav_mesh.agent_max_slope = 30.0  # Moderate slopes
	nav_mesh.region_min_size = 4.0  # Larger regions for smoother areas
	nav_mesh.region_merge_size = 20.0  # More aggressive merging
	nav_mesh.edge_max_length = 0.0  # No edge length limit for smoother areas
	nav_mesh.edge_max_error = 2.0  # Higher error = smoother, more centered paths
	nav_mesh.vertices_per_polygon = 6.0
	nav_mesh.detail_sample_distance = 12.0  # Much less detail = smoother paths
	nav_mesh.detail_sample_max_error = 2.0  # Higher error tolerance
	
	# Set geometry source - use static colliders
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1  # Environment layer
	
	navigation_region.navigation_mesh = nav_mesh
	
	# Bake the navigation mesh
	print("NavigationSetupManager: Baking navigation mesh...")
	NavigationServer3D.region_bake_navigation_mesh(nav_mesh, navigation_region)
	
	# Connect navigation completed signal if available
	await get_tree().create_timer(1.0).timeout  # Give it time to bake
	
	print("NavigationSetupManager: Navigation mesh created and baked")
	_ensure_navigation_links_connected()

func _ensure_navigation_links_connected():
	# Find all NavigationLink3D nodes and ensure they're properly connected
	var nav_links = get_tree().get_nodes_in_group("navigation_links")
	if nav_links.is_empty():
		# Try to find by type
		var scene_root = get_tree().current_scene
		_find_navigation_links_recursive(scene_root)
		nav_links = get_tree().get_nodes_in_group("navigation_links")
	
	print("NavigationSetupManager: Found ", nav_links.size(), " NavigationLink3D nodes")
	
	for link in nav_links:
		if link is NavigationLink3D:
			# Ensure the link is enabled
			link.enabled = true
			# Set bidirectional if not already
			if not link.bidirectional:
				link.bidirectional = true
			print("  - Link at ", link.get_parent().name, ": ", link.start_position, " -> ", link.end_position)

func _find_navigation_links_recursive(node: Node):
	if node is NavigationLink3D:
		node.add_to_group("navigation_links")
	
	for child in node.get_children():
		_find_navigation_links_recursive(child)

func regenerate_navigation_mesh():
	if navigation_region and navigation_region.navigation_mesh:
		print("NavigationSetupManager: Regenerating navigation mesh...")
		NavigationServer3D.region_bake_navigation_mesh(navigation_region.navigation_mesh, navigation_region)
		await get_tree().create_timer(1.0).timeout
		print("NavigationSetupManager: Navigation mesh regenerated")