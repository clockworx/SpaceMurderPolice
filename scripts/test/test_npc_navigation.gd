extends Node

# Simple test script to verify NPC navigation is working
# Add this to your scene tree to test

func _ready():
	print("\n=== NPC Navigation Test Starting ===")
	
	# Wait for scene to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Find the NPC
	var npc = get_tree().get_first_node_in_group("npcs")
	if not npc:
		print("ERROR: No NPC found in 'npcs' group!")
		return
		
	print("Found NPC: ", npc.npc_name)
	print("NPC Position: ", npc.global_position)
	
	# Check if simple navigation is available
	if npc.get("simple_nav") and npc.simple_nav:
		print("Simple navigation is available!")
		
		# Test navigation to Security Office
		print("\nTesting navigation to Security Office...")
		npc.simple_nav.navigate_to_room("Security_Waypoint")
		
		# Monitor progress
		_monitor_navigation(npc)
	else:
		print("ERROR: Simple navigation not initialized on NPC!")
		print("Available properties:")
		for prop in npc.get_property_list():
			if prop.name.contains("nav"):
				print("  ", prop.name, " = ", npc.get(prop.name))

func _monitor_navigation(npc):
	var check_count = 0
	while check_count < 30:  # Monitor for 30 seconds max
		await get_tree().create_timer(1.0).timeout
		check_count += 1
		
		if npc.simple_nav and npc.simple_nav.is_navigating_active():
			print("Navigation active - Position: ", npc.global_position)
		else:
			print("Navigation completed or stopped")
			break
	
	print("\n=== Test Complete ===")