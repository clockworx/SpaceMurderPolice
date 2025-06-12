@tool
extends EditorScript

func _run():
	print("=== Disabling NPC Wander Behavior ===")
	
	# Get the currently open scene
	var edited_scene = get_editor_interface().get_edited_scene_root()
	if not edited_scene:
		print("ERROR: No scene is currently open!")
		return
	
	print("Working with scene: ", edited_scene.name)
	
	# Find NPCs node
	var npcs_node = edited_scene.find_child("NPCs", true, false)
	if not npcs_node:
		print("ERROR: No NPCs node found!")
		return
	
	# Disable wander behavior for all NPCs
	print("\nDisabling wander behavior:")
	for npc in npcs_node.get_children():
		if npc is Node3D:
			# Set wander_radius to 0 to disable wandering
			if "wander_radius" in npc:
				npc.set("wander_radius", 0.0)
				print("  - Disabled wandering for ", npc.name)
			
			# Also disable initial movement states
			if "current_state" in npc:
				npc.set("current_state", 0)  # Set to IDLE state
				print("  - Set ", npc.name, " to IDLE state")
	
	# Create simple stationary waypoints at NPC spawn positions
	var waypoints_node = edited_scene.find_child("Waypoints", true, false)
	if not waypoints_node:
		waypoints_node = Node3D.new()
		waypoints_node.name = "Waypoints"
		edited_scene.add_child(waypoints_node)
		waypoints_node.owner = edited_scene
	
	# Clear existing waypoints
	for child in waypoints_node.get_children():
		child.queue_free()
	
	# Create a single waypoint at each NPC's position
	print("\nCreating stationary waypoints:")
	for npc in npcs_node.get_children():
		if npc is Node3D:
			var waypoint = Node3D.new()
			waypoint.name = npc.name + "_StationaryWaypoint"
			waypoint.position = npc.position
			waypoints_node.add_child(waypoint)
			waypoint.owner = edited_scene
			
			# Visual indicator
			var mesh = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.3
			sphere.height = 0.6
			mesh.mesh = sphere
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0, 0, 1, 0.5)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_override = material
			
			waypoint.add_child(mesh)
			mesh.owner = edited_scene
			
			# Assign this single waypoint to the NPC
			if "waypoint_nodes" in npc:
				npc.set("waypoint_nodes", [waypoint.get_path()])
				print("  - Created stationary waypoint for ", npc.name)
	
	print("\n✓ Wander behavior disabled!")
	print("\nNPCs will now:")
	print("- Stay at their spawn positions")
	print("- Not attempt to move randomly")
	print("- Only move when explicitly commanded")
	print("\nThis should prevent them from getting stuck in walls.")