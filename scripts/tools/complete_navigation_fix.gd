@tool
extends EditorScript

func _run():
	print("=== Complete Navigation Fix for NewStation ===")
	
	var scene_path = "res://scenes/levels/NewStation.tscn"
	var scene = load(scene_path) as PackedScene
	if not scene:
		print("ERROR: Could not load NewStation scene")
		return
		
	var root = scene.instantiate()
	
	# 1. Fix NavigationRegion3D position
	var nav_region = root.find_child("NavigationRegion3D", true, false)
	if nav_region:
		print("\n1. Fixing NavigationRegion3D...")
		# Move navigation region to ground level
		nav_region.transform.origin.y = 0.0
		print("   - Set NavigationRegion3D Y position to 0.0")
		
		# Ensure navigation mesh settings are optimal
		if nav_region.navigation_mesh:
			var nav_mesh = nav_region.navigation_mesh
			# These settings prevent the warnings
			nav_mesh.cell_size = 0.1
			nav_mesh.cell_height = 0.1
			nav_mesh.agent_height = 1.8
			nav_mesh.agent_radius = 0.3
			nav_mesh.agent_max_climb = 0.4
			nav_mesh.agent_max_slope = 45.0
			
			# Geometry settings
			nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
			nav_mesh.geometry_collision_mask = 1  # Only parse layer 1 (environment)
			
			# Region settings
			nav_mesh.region_min_size = 2.0
			nav_mesh.region_merge_size = 10.0
			
			# Edge settings
			nav_mesh.edge_max_length = 12.0
			nav_mesh.edge_max_error = 1.3
			
			# Detail settings
			nav_mesh.detail_sample_distance = 6.0
			nav_mesh.detail_sample_max_error = 1.0
			
			# Filters
			nav_mesh.filter_low_hanging_obstacles = true
			nav_mesh.filter_ledge_spans = true
			nav_mesh.filter_walkable_low_height_spans = true
			
			print("   - Updated all NavigationMesh settings")
	
	# 2. Fix Floor Collision
	var floor_nodes = []
	_find_floor_nodes(root, floor_nodes)
	
	print("\n2. Setting up floor collision...")
	for floor in floor_nodes:
		if floor.name.contains("Floor") or floor.name.contains("Ground"):
			floor.collision_layer = 1  # Environment layer
			floor.collision_mask = 0   # Floor doesn't need to detect anything
			print("   - Fixed collision for: ", floor.name)
	
	# 3. Fix all NPCs
	var npcs_node = root.find_child("NPCs", true, false)
	if npcs_node:
		print("\n3. Fixing all NPCs...")
		
		for npc in npcs_node.get_children():
			if npc is CharacterBody3D:
				# Ensure proper Y position
				if npc.transform.origin.y < 0.5:
					npc.transform.origin.y = 1.0
					print("   - Fixed ", npc.name, " Y position to 1.0")
				
				# Ensure collision settings
				npc.collision_layer = 4  # NPC layer
				npc.collision_mask = 1   # Collide with environment only
				
				# Ensure NavigationAgent3D exists and is configured
				var nav_agent = null
				for child in npc.get_children():
					if child is NavigationAgent3D:
						nav_agent = child
						break
				
				if not nav_agent:
					nav_agent = NavigationAgent3D.new()
					nav_agent.name = "NavigationAgent3D"
					npc.add_child(nav_agent)
					nav_agent.owner = root
					print("   - Added NavigationAgent3D to ", npc.name)
				
				# Configure NavigationAgent3D with matching settings
				nav_agent.path_desired_distance = 0.2
				nav_agent.target_desired_distance = 0.5
				nav_agent.path_max_distance = 1.0
				nav_agent.avoidance_enabled = true
				nav_agent.radius = 0.3  # Match nav mesh agent_radius
				nav_agent.height = 1.8  # Match nav mesh agent_height
				nav_agent.max_neighbors = 10
				nav_agent.max_speed = 3.5
				nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
				nav_agent.avoidance_priority = 1.0
				
				# Enable properties
				if "use_hybrid_movement" in npc:
					npc.use_hybrid_movement = true
	
	# 4. Ensure main floor exists
	var main_floor = root.find_child("Floor", true, false)
	if not main_floor:
		print("\n4. WARNING: No main floor found! Navigation mesh needs geometry to bake against.")
		print("   Please ensure your level has floor geometry on collision layer 1")
	
	# Save the scene
	var packed = PackedScene.new()
	packed.pack(root)
	var error = ResourceSaver.save(packed, scene_path)
	
	if error == OK:
		print("\n✓ Scene saved successfully!")
		print("\n=== NEXT STEPS ===")
		print("1. Open the NewStation scene in the editor")
		print("2. Select the NavigationRegion3D node")
		print("3. In the toolbar, click 'Bake NavigationMesh'")
		print("4. You should see a blue mesh overlay showing walkable areas")
		print("5. Save the scene again")
		print("\nThe navigation warnings should now be resolved!")
	else:
		print("\n✗ ERROR: Failed to save scene: ", error)
	
	root.queue_free()

func _find_floor_nodes(node: Node, result: Array) -> void:
	if node is StaticBody3D:
		result.append(node)
	
	for child in node.get_children():
		_find_floor_nodes(child, result)