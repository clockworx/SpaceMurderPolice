@tool
extends EditorScript

func _run():
	print("=== Fixing NPC Spawn Positions ===")
	
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
	
	# Define safe spawn positions for each NPC
	# These are open areas away from walls
	var safe_positions = {
		"MedicalOfficer": Vector3(35, 0.2, 0),      # Open area in medical bay
		"ChiefScientist": Vector3(0, 0.2, 0),       # Center of lab
		"Engineer": Vector3(-35, 0.2, 5),           # Open area in engineering
		"SecurityChief": Vector3(-10, 0.2, 5),      # Open area near security
		"AISpecialist": Vector3(20, 0.2, -5),       # Server room area
		"SecurityOfficer": Vector3(-5, 0.2, 0)      # Central patrol area
	}
	
	# Move each NPC to their safe position
	print("\nMoving NPCs to safe positions:")
	for npc in npcs_node.get_children():
		if npc is Node3D and npc.name in safe_positions:
			var old_pos = npc.position
			var new_pos = safe_positions[npc.name]
			npc.position = new_pos
			print("  - Moved ", npc.name, " from ", old_pos, " to ", new_pos)
			
			# Also ensure collision settings are correct
			if npc is CharacterBody3D:
				npc.set("collision_layer", 4)
				npc.set("collision_mask", 1)
	
	# Create visual markers at spawn positions
	var markers_node = Node3D.new()
	markers_node.name = "NPCSpawnMarkers"
	edited_scene.add_child(markers_node)
	markers_node.owner = edited_scene
	
	for npc_name in safe_positions:
		var pos = safe_positions[npc_name]
		var marker = Node3D.new()
		marker.name = npc_name + "_Spawn"
		marker.position = pos
		markers_node.add_child(marker)
		marker.owner = edited_scene
		
		# Add visual indicator
		var mesh = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.height = 0.2
		cylinder.top_radius = 0.5
		cylinder.bottom_radius = 0.5
		mesh.mesh = cylinder
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0, 1, 0, 0.5)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = material
		
		marker.add_child(mesh)
		mesh.owner = edited_scene
	
	print("\n✓ NPCs moved to safe spawn positions!")
	print("\nNotes:")
	print("- NPCs are now in open areas away from walls")
	print("- Green circles show spawn positions")
	print("- You can hide/delete NPCSpawnMarkers node after testing")
	print("\nNext steps:")
	print("1. Save the scene")
	print("2. Run the game to test movement")
	print("3. If still stuck, check that navigation mesh covers these areas")