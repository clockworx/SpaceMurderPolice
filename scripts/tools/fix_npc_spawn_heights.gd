@tool
extends EditorScript

func _run():
	print("=== Fixing NPC Spawn Heights in NewStation ===")
	
	var scene_path = "res://scenes/levels/NewStation.tscn"
	var scene = load(scene_path) as PackedScene
	if not scene:
		print("ERROR: Could not load NewStation scene")
		return
		
	var root = scene.instantiate()
	
	# Find all NPCs and adjust their Y positions
	var npcs_node = root.find_child("NPCs", true, false)
	if npcs_node:
		print("Found NPCs node with ", npcs_node.get_child_count(), " children")
		
		for npc in npcs_node.get_children():
			if npc is CharacterBody3D:
				var old_pos = npc.transform.origin
				# Set Y position to 1.0 to ensure NPCs are above the floor
				npc.transform.origin.y = 1.0
				print("Fixed ", npc.name, " height from ", old_pos.y, " to ", npc.transform.origin.y)
	
	# Also fix the NavigationRegion3D height if needed
	var nav_region = root.find_child("NavigationRegion3D", true, false)
	if nav_region:
		print("\nNavigationRegion3D Y position: ", nav_region.transform.origin.y)
		# Navigation mesh is at Y=0.33, which should be fine
	
	# Save the modified scene
	var packed = PackedScene.new()
	packed.pack(root)
	var error = ResourceSaver.save(packed, scene_path)
	
	if error == OK:
		print("\n✓ Scene saved successfully!")
		print("\nNPCs should now spawn at the correct height above the navigation mesh.")
	else:
		print("\n✗ ERROR: Failed to save scene: ", error)
	
	root.queue_free()