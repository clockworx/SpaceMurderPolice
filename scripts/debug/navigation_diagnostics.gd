extends Node

# Diagnostic tool to check navigation setup

func _ready():
	print("\n=== NAVIGATION DIAGNOSTICS ===")
	
	# Wait for scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check for NavigationRegion3D
	var nav_regions = []
	_find_navigation_regions(get_tree().current_scene, nav_regions)
	
	print("Found ", nav_regions.size(), " NavigationRegion3D nodes")
	
	for region in nav_regions:
		print("\nNavigationRegion3D: ", region.name)
		print("  Enabled: ", region.enabled)
		print("  Navigation layers: ", region.navigation_layers)
		
		if region.navigation_mesh:
			var mesh = region.navigation_mesh
			print("  Has NavigationMesh: Yes")
			print("  Vertices: ", mesh.get_vertices().size())
			print("  Polygons: ", mesh.get_polygon_count())
			
			if mesh.get_vertices().size() == 0:
				print("  WARNING: Navigation mesh has no vertices! Need to bake it.")
		else:
			print("  Has NavigationMesh: No - Need to assign one!")
	
	# Check navigation maps
	var maps = NavigationServer3D.get_maps()
	print("\nNavigationServer3D maps: ", maps.size())
	
	for map in maps:
		var region_count = NavigationServer3D.map_get_regions(map).size()
		var agent_count = NavigationServer3D.map_get_agents(map).size()
		print("  Map ", map, ": ", region_count, " regions, ", agent_count, " agents")
		
		# Check if map is active
		if NavigationServer3D.map_is_active(map):
			print("    Map is ACTIVE")
		else:
			print("    Map is INACTIVE")
	
	# Check for NavigationAgent3D nodes
	var agents = []
	_find_navigation_agents(get_tree().current_scene, agents)
	print("\nFound ", agents.size(), " NavigationAgent3D nodes")
	
	for agent in agents:
		print("  Agent in: ", agent.get_parent().name)
		print("    Navigation layers: ", agent.navigation_layers)
		print("    Has navigation map: ", agent.get_navigation_map().is_valid() if agent.get_navigation_map() else false)
	
	print("\n=== END DIAGNOSTICS ===\n")
	
	# Run scene-specific analysis
	_analyze_newstation_scene()

func _analyze_newstation_scene():
	print("\n=== NEWSTATION SCENE ANALYSIS ===")
	
	# Find the existing NavigationRegion3D
	var nav_region = get_node_or_null("/root/NewStation/NavigationRegion3D")
	if not nav_region:
		print("ERROR: NavigationRegion3D not found at expected path!")
		return
	
	print("✓ Found NavigationRegion3D at: ", nav_region.get_path())
	print("  Global position: ", nav_region.global_position)
	
	# Check navigation mesh
	var nav_mesh = nav_region.navigation_mesh
	if nav_mesh and nav_mesh.get_vertices().size() > 0:
		print("✓ NavigationMesh has ", nav_mesh.get_vertices().size(), " vertices")
		
		# Test navigation from NPC position
		var npc = get_tree().get_first_node_in_group("npcs")
		if npc:
			print("\n--- NPC Navigation Test ---")
			print("NPC position: ", npc.global_position)
			
			# Get navigation map
			var nav_map = nav_region.get_navigation_map()
			if nav_map and nav_map.is_valid():
				var closest = NavigationServer3D.map_get_closest_point(nav_map, npc.global_position)
				var distance = npc.global_position.distance_to(closest)
				print("Closest point on navmesh: ", closest)
				print("Distance to navmesh: ", distance)
				
				if distance > 2.0:
					print("❌ PROBLEM: NPC is ", distance, " units from navigation mesh!")
					print("  This explains why targets are unreachable")
					print("  SOLUTION: Either move NPC closer or rebake navigation mesh")
				else:
					print("✓ NPC is close enough to navigation mesh")
	else:
		print("❌ PROBLEM: Navigation mesh has no vertices - needs rebaking!")
	
	print("=== END NEWSTATION ANALYSIS ===\n")

func _find_navigation_regions(node: Node, regions: Array):
	if node is NavigationRegion3D:
		regions.append(node)
	
	for child in node.get_children():
		_find_navigation_regions(child, regions)

func _find_navigation_agents(node: Node, agents: Array):
	if node is NavigationAgent3D:
		agents.append(node)
	
	for child in node.get_children():
		_find_navigation_agents(child, agents)