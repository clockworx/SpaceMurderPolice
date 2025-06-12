@tool
extends EditorScript

func _run():
	print("=== Setting Up Simple NPC Patrol ===")
	
	# Get the currently open scene
	var edited_scene = get_editor_interface().get_edited_scene_root()
	if not edited_scene:
		print("ERROR: No scene is currently open!")
		return
	
	print("Working with scene: ", edited_scene.name)
	
	# Find or create Waypoints node
	var waypoints_node = edited_scene.find_child("Waypoints", true, false)
	if not waypoints_node:
		waypoints_node = Node3D.new()
		waypoints_node.name = "Waypoints"
		edited_scene.add_child(waypoints_node)
		waypoints_node.owner = edited_scene
	
	# Clear old waypoints
	for child in waypoints_node.get_children():
		child.queue_free()
	
	# Create patrol waypoints in a simple pattern
	var patrol_points = [
		# Central square patrol
		{"name": "PatrolPoint_1", "pos": Vector3(10, 0.5, 10)},
		{"name": "PatrolPoint_2", "pos": Vector3(10, 0.5, -10)},
		{"name": "PatrolPoint_3", "pos": Vector3(-10, 0.5, -10)},
		{"name": "PatrolPoint_4", "pos": Vector3(-10, 0.5, 10)},
		
		# Outer patrol points
		{"name": "PatrolPoint_5", "pos": Vector3(25, 0.5, 0)},
		{"name": "PatrolPoint_6", "pos": Vector3(-25, 0.5, 0)},
		{"name": "PatrolPoint_7", "pos": Vector3(0, 0.5, 25)},
		{"name": "PatrolPoint_8", "pos": Vector3(0, 0.5, -25)},
	]
	
	print("\nCreating patrol waypoints:")
	for wp_data in patrol_points:
		var waypoint = Node3D.new()
		waypoint.name = wp_data.name
		waypoint.position = wp_data.pos
		waypoints_node.add_child(waypoint)
		waypoint.owner = edited_scene
		
		# Visual indicator
		var mesh = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		mesh.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0, 1, 0, 0.7)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color(0, 1, 0, 1)
		material.emission_energy = 0.2
		mesh.material_override = material
		
		waypoint.add_child(mesh)
		mesh.owner = edited_scene
		
		print("  - Created ", wp_data.name, " at ", wp_data.pos)
	
	# Assign waypoints to NPCs
	var npcs_node = edited_scene.find_child("NPCs", true, false)
	if npcs_node:
		print("\nAssigning patrol routes to NPCs:")
		
		var npc_index = 0
		for npc in npcs_node.get_children():
			if npc is CharacterBody3D:
				# Give each NPC a different patrol route
				var waypoint_paths = []
				
				if npc_index == 0:  # Medical Officer - inner square
					waypoint_paths = [
						waypoints_node.get_path_to(waypoints_node.get_child(0)),
						waypoints_node.get_path_to(waypoints_node.get_child(1)),
						waypoints_node.get_path_to(waypoints_node.get_child(2)),
						waypoints_node.get_path_to(waypoints_node.get_child(3)),
					]
				elif npc_index == 1:  # Chief Scientist - reverse inner square
					waypoint_paths = [
						waypoints_node.get_path_to(waypoints_node.get_child(3)),
						waypoints_node.get_path_to(waypoints_node.get_child(2)),
						waypoints_node.get_path_to(waypoints_node.get_child(1)),
						waypoints_node.get_path_to(waypoints_node.get_child(0)),
					]
				elif npc_index == 2:  # Engineer - east-west patrol
					waypoint_paths = [
						waypoints_node.get_path_to(waypoints_node.get_child(4)),
						waypoints_node.get_path_to(waypoints_node.get_child(5)),
					]
				elif npc_index == 3:  # Security Chief - north-south patrol
					waypoint_paths = [
						waypoints_node.get_path_to(waypoints_node.get_child(6)),
						waypoints_node.get_path_to(waypoints_node.get_child(7)),
					]
				else:  # Others - mixed patrol
					waypoint_paths = [
						waypoints_node.get_path_to(waypoints_node.get_child(0)),
						waypoints_node.get_path_to(waypoints_node.get_child(4)),
						waypoints_node.get_path_to(waypoints_node.get_child(2)),
						waypoints_node.get_path_to(waypoints_node.get_child(5)),
					]
				
				# Set waypoints and enable patrol
				if "waypoint_nodes" in npc:
					npc.set("waypoint_nodes", waypoint_paths)
					print("  - ", npc.name, ": Assigned ", waypoint_paths.size(), " waypoints")
				
				# Set to wandering/patrol state
				if "current_state" in npc:
					npc.set("current_state", 1)  # WANDERING state
				
				# Set reasonable wander radius
				if "wander_radius" in npc:
					npc.set("wander_radius", 2.0)
				
				npc_index += 1
	
	print("\n✓ Patrol setup complete!")
	print("\nNPCs will now:")
	print("- Move between assigned waypoints")
	print("- Follow different patrol patterns")
	print("- Green spheres show patrol points")
	print("\nIf NPCs still aren't moving, check:")
	print("- Navigation mesh covers patrol areas")
	print("- NPCs have proper movement scripts attached")