extends Node

# Analyzes the specific navigation setup in NewStation scene

func _ready():
	print("\n=== NAVIGATION SCENE ANALYZER ===")
	
	await get_tree().process_frame
	
	# Find the existing NavigationRegion3D
	var nav_region = get_node_or_null("/root/NewStation/NavigationRegion3D")
	if not nav_region:
		print("ERROR: NavigationRegion3D not found at expected path!")
		return
	
	print("✓ Found NavigationRegion3D at: ", nav_region.get_path())
	print("  Transform: ", nav_region.transform)
	print("  Position: ", nav_region.global_position)
	
	# Check navigation mesh
	var nav_mesh = nav_region.navigation_mesh
	if nav_mesh:
		print("✓ NavigationMesh exists")
		print("  Vertices: ", nav_mesh.get_vertices().size())
		print("  Polygons: ", nav_mesh.get_polygon_count())
		print("  Cell size: ", nav_mesh.cell_size)
		print("  Cell height: ", nav_mesh.cell_height)
		print("  Agent radius: ", nav_mesh.agent_radius)
		print("  Agent height: ", nav_mesh.agent_height)
		
		if nav_mesh.get_vertices().size() == 0:
			print("❌ PROBLEM: Navigation mesh has no vertices!")
		
		# Check geometry source settings
		print("  Geometry type: ", nav_mesh.geometry_parsed_geometry_type)
		print("  Collision mask: ", nav_mesh.geometry_collision_mask)
	else:
		print("❌ PROBLEM: No NavigationMesh assigned!")
		return
	
	# Check Station collision setup
	var station = get_node_or_null("/root/NewStation/NavigationRegion3D/Station")
	if station:
		print("✓ Found Station StaticBody3D")
		print("  Transform: ", station.transform)
		print("  Collision layer: ", station.collision_layer)
		print("  Collision mask: ", station.collision_mask)
		
		# Check collision shapes
		var collision_shapes = []
		_find_collision_shapes(station, collision_shapes)
		print("  Collision shapes found: ", collision_shapes.size())
		
		for i in range(collision_shapes.size()):
			var shape_node = collision_shapes[i]
			var shape = shape_node.shape
			if shape:
				print("    Shape ", i + 1, ": ", shape.get_class())
				if shape is ConcavePolygonShape3D:
					print("      Faces: ", shape.get_faces().size() / 3)
			else:
				print("    Shape ", i + 1, ": No shape assigned!")
	else:
		print("❌ PROBLEM: Station StaticBody3D not found!")
	
	# Check CSG collision boxes
	var csg_nodes = []
	_find_csg_nodes(nav_region, csg_nodes)
	if csg_nodes.size() > 0:
		print("✓ Found ", csg_nodes.size(), " CSG nodes with collision")
		for csg in csg_nodes:
			print("  ", csg.name, " - Size: ", csg.size, " - Collision: ", csg.use_collision)
	
	# Test navigation from NPC position
	var npc = get_tree().get_first_node_in_group("npcs")
	if npc:
		print("\n--- NPC Navigation Test ---")
		print("NPC position: ", npc.global_position)
		
		# Get navigation map
		var nav_map = nav_region.get_navigation_map()
		if nav_map.is_valid():
			print("✓ Navigation map is valid")
			
			# Test closest point
			var closest = NavigationServer3D.map_get_closest_point(nav_map, npc.global_position)
			var distance = npc.global_position.distance_to(closest)
			print("Closest point on navmesh: ", closest)
			print("Distance to navmesh: ", distance)
			
			if distance > 2.0:
				print("❌ PROBLEM: NPC is too far from navigation mesh!")
				print("  This explains why targets are unreachable")
			
			# Test a few room positions
			var test_positions = [
				Vector3(0, 0, 10),    # Laboratory 
				Vector3(40, 0, -2),   # Medical Bay
				Vector3(-12, 0, 8)    # Security Office
			]
			
			for pos in test_positions:
				var closest_to_room = NavigationServer3D.map_get_closest_point(nav_map, pos)
				var room_distance = pos.distance_to(closest_to_room)
				print("Room test ", pos, " -> closest: ", closest_to_room, " (dist: ", room_distance, ")")
		else:
			print("❌ PROBLEM: Navigation map is invalid!")
	
	print("\n=== RECOMMENDATIONS ===")
	if nav_mesh and nav_mesh.get_vertices().size() > 0:
		print("1. NavigationMesh exists but may need re-baking")
		print("2. Try: Select NavigationRegion3D → Bake NavigationMesh")
		print("3. Check if NPC starting position is on the navigation mesh")
	else:
		print("1. Navigation mesh needs to be baked!")
		print("2. Ensure Station has proper collision shapes")
		print("3. Set navigation mesh geometry source correctly")
	
	print("=== END ANALYZER ===\n")

func _find_collision_shapes(node: Node, shapes: Array):
	if node is CollisionShape3D:
		shapes.append(node)
	
	for child in node.get_children():
		_find_collision_shapes(child, shapes)

func _find_csg_nodes(node: Node, csg_nodes: Array):
	if node is CSGBox3D and node.use_collision:
		csg_nodes.append(node)
	
	for child in node.get_children():
		_find_csg_nodes(child, csg_nodes)