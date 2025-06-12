@tool
extends EditorScript

func _run():
	print("=== Fixing NPC Navigation Setup ===")
	
	var scene_path = "res://scenes/levels/NewStation.tscn"
	var scene = load(scene_path) as PackedScene
	if not scene:
		print("ERROR: Could not load NewStation scene")
		return
		
	var root = scene.instantiate()
	
	# Find NavigationRegion3D
	var nav_region = root.find_child("NavigationRegion3D", true, false)
	if nav_region:
		print("Found NavigationRegion3D")
		
		# Ensure navigation mesh settings are correct
		if nav_region.navigation_mesh:
			var nav_mesh = nav_region.navigation_mesh
			nav_mesh.agent_height = 1.8
			nav_mesh.agent_radius = 0.4  # Smaller radius for better navigation
			nav_mesh.agent_max_climb = 0.4
			nav_mesh.agent_max_slope = 45.0
			nav_mesh.cell_size = 0.1
			nav_mesh.cell_height = 0.1
			nav_mesh.edge_max_length = 12.0
			nav_mesh.edge_max_error = 1.3
			nav_mesh.region_min_size = 2.0
			nav_mesh.region_merge_size = 10.0
			nav_mesh.detail_sample_distance = 6.0
			nav_mesh.detail_sample_max_error = 1.0
			nav_mesh.filter_low_hanging_obstacles = true
			nav_mesh.filter_ledge_spans = true
			nav_mesh.filter_walkable_low_height_spans = true
			
			# Set geometry parsed type to both physics and visual
			nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
			nav_mesh.geometry_collision_mask = 1  # Only parse layer 1 (environment)
			
			print("Updated navigation mesh settings")
			
			# Mark navigation mesh as needing to be baked
			print("Navigation mesh needs to be baked in the editor!")
	
	# Find and fix all NPCs
	var npcs_node = root.find_child("NPCs", true, false)
	if npcs_node:
		print("\nFound NPCs node with ", npcs_node.get_child_count(), " children")
		
		for npc in npcs_node.get_children():
			if npc is CharacterBody3D:
				print("\nProcessing NPC: ", npc.name)
				
				# Add NavigationAgent3D if missing
				var nav_agent = null
				for child in npc.get_children():
					if child is NavigationAgent3D:
						nav_agent = child
						break
				
				if not nav_agent:
					print("  - Adding NavigationAgent3D to ", npc.name)
					nav_agent = NavigationAgent3D.new()
					nav_agent.name = "NavigationAgent3D"
					npc.add_child(nav_agent)
					nav_agent.owner = root
				
				# Configure NavigationAgent3D
				nav_agent.path_desired_distance = 0.5
				nav_agent.target_desired_distance = 1.0
				nav_agent.path_max_distance = 3.0
				nav_agent.avoidance_enabled = true
				nav_agent.radius = 0.3
				nav_agent.height = 1.8
				nav_agent.max_neighbors = 10
				nav_agent.neighbor_distance = 2.0
				nav_agent.time_horizon_agents = 2.0
				nav_agent.time_horizon_obstacles = 0.5
				nav_agent.max_speed = 3.5
				
				print("  - NavigationAgent3D configured")
				
				# Ensure NPC collision settings are correct
				npc.collision_layer = 4  # NPCs on layer 3
				npc.collision_mask = 1   # NPCs collide only with environment (layer 1)
				
				# Set NPC properties
				if "use_hybrid_movement" in npc:
					npc.use_hybrid_movement = true
					print("  - Hybrid movement enabled")
	
	# Save the modified scene
	var packed = PackedScene.new()
	packed.pack(root)
	var error = ResourceSaver.save(packed, scene_path)
	
	if error == OK:
		print("\n✓ Scene saved successfully!")
		print("\nIMPORTANT: You need to:")
		print("1. Open the NewStation scene in the editor")
		print("2. Select the NavigationRegion3D node")
		print("3. Click 'Bake NavigationMesh' in the toolbar or inspector")
		print("4. Save the scene again")
	else:
		print("\n✗ ERROR: Failed to save scene: ", error)
	
	root.queue_free()