extends Node

# Quick test for waypoint-guided navigation

func _ready():
	print("Testing Waypoint-Guided Navigation...")
	
	# Find the NPC
	var npc = get_tree().get_first_node_in_group("npcs")
	if not npc:
		print("ERROR: No NPC found!")
		return
	
	print("Found NPC: ", npc.npc_name)
	
	# Check if waypoint-guided nav is available
	if npc.has_method("get_waypoint_guided_nav"):
		var wp_nav = npc.get_waypoint_guided_nav()
		if wp_nav:
			print("SUCCESS: Waypoint-guided navigation initialized!")
			
			# Test navigation to Security Office
			print("Testing navigation to Security Office...")
			npc.force_move_to_position(Vector3(15, 0, -10))  # Approximate security office position
		else:
			print("WARNING: Waypoint-guided navigation not initialized")
	else:
		print("ERROR: NPC doesn't have get_waypoint_guided_nav method")
	
	# Wait and exit
	await get_tree().create_timer(2.0).timeout
	print("Test complete")
	get_tree().quit()