@tool
extends EditorScript

# This script updates the NewStation scene to use hybrid movement NPCs
# Run from Script Editor with the NewStation scene open

func _run():
	var edited_scene = get_scene()
	if not edited_scene:
		print("No scene open!")
		return
		
	if edited_scene.name != "NewStation":
		print("Please open NewStation.tscn first!")
		return
	
	print("Setting up NPCs with hybrid movement system...")
	
	# Find the NPCs node
	var npcs_node = edited_scene.get_node_or_null("NPCs")
	if not npcs_node:
		print("Creating NPCs node...")
		npcs_node = Node3D.new()
		npcs_node.name = "NPCs"
		edited_scene.add_child(npcs_node)
		npcs_node.owner = edited_scene
	
	# Remove existing NPCs
	for child in npcs_node.get_children():
		print("Removing old NPC: ", child.name)
		child.queue_free()
	
	# Wait for nodes to be freed
	await edited_scene.get_tree().process_frame
	
	# Load the base NPC scene
	var npc_scene = load("res://scenes/npcs/npc_base.tscn")
	if not npc_scene:
		print("Could not load npc_base.tscn!")
		return
	
	# Create NPCs with proper placement
	var npcs_to_create = [
		{
			"name": "Dr_Sarah_Chen",
			"npc_name": "Dr. Sarah Chen",
			"role": "Medical Officer",
			"position": Vector3(-20, 0.1, 15),  # Medical Bay
			"dialogue_id": "medical_officer_greeting",
			"can_be_saboteur": false,
			"assigned_room": "Medical Bay"
		},
		{
			"name": "Dr_Marcus_Webb",
			"npc_name": "Dr. Marcus Webb", 
			"role": "Chief Scientist",
			"position": Vector3(5, 0.1, 12),  # Laboratory (near crime scene)
			"dialogue_id": "scientist_greeting",
			"can_be_saboteur": false,
			"assigned_room": "Laboratory"
		},
		{
			"name": "Alex_Chen",
			"npc_name": "Alex Chen",
			"role": "Station Engineer",
			"position": Vector3(-40, 0.1, 7),  # Engineering Bay
			"dialogue_id": "engineer_greeting",
			"can_be_saboteur": true,  # This is our potential saboteur
			"assigned_room": "Engineering Bay"
		},
		{
			"name": "Jake_Torres",
			"npc_name": "Jake Torres",
			"role": "Security Chief",
			"position": Vector3(-13, 0.1, 10),  # Security Office
			"dialogue_id": "security_greeting",
			"can_be_saboteur": false,
			"assigned_room": "Security Office"
		},
		{
			"name": "Dr_Zara_Okafor",
			"npc_name": "Dr. Zara Okafor",
			"role": "AI Specialist",
			"position": Vector3(25, 0.1, 5),  # Communications Center
			"dialogue_id": "ai_specialist_greeting",
			"can_be_saboteur": false,
			"assigned_room": "Communications Center"
		},
		{
			"name": "Security_Officer",
			"npc_name": "Security Officer Riley",
			"role": "Security Personnel",
			"position": Vector3(-10, 0.1, 8),  # Near Security Office
			"dialogue_id": "security_officer_greeting",
			"can_be_saboteur": false,
			"assigned_room": "Security Office"
		}
	]
	
	# Create each NPC
	for npc_data in npcs_to_create:
		print("Creating NPC: ", npc_data.name)
		
		var npc_instance = npc_scene.instantiate()
		npc_instance.name = npc_data.name
		npcs_node.add_child(npc_instance)
		npc_instance.owner = edited_scene
		
		# Set position
		npc_instance.position = npc_data.position
		
		# Configure NPC properties
		npc_instance.set("npc_name", npc_data.npc_name)
		npc_instance.set("role", npc_data.role)
		npc_instance.set("initial_dialogue_id", npc_data.dialogue_id)
		npc_instance.set("can_be_saboteur", npc_data.can_be_saboteur)
		npc_instance.set("assigned_room", npc_data.assigned_room)
		
		# Enable hybrid movement system
		npc_instance.set("use_hybrid_movement", true)
		npc_instance.set("use_waypoints", false)  # We'll set up waypoints later
		npc_instance.set("wander_radius", 3.0)
		
		# Set collision layer to interactable
		npc_instance.set("collision_layer", 4)
		npc_instance.set("collision_mask", 1)
		
		# Set initial state to IDLE
		npc_instance.set("current_state", 1)
		
		# Enable appropriate features based on role
		if npc_data.can_be_saboteur:
			npc_instance.set("enable_saboteur_behavior", true)
			npc_instance.set("enable_sound_detection", true)
			npc_instance.set("enable_los_detection", true)
			npc_instance.set("show_detection_indicator", true)
		else:
			npc_instance.set("enable_saboteur_behavior", false)
			npc_instance.set("enable_sound_detection", false)
			npc_instance.set("enable_los_detection", false)
			npc_instance.set("show_detection_indicator", false)
		
		print("  - Configured ", npc_data.name, " at ", npc_data.position)
	
	# Set up some basic waypoints for key areas
	var waypoints_node = edited_scene.get_node_or_null("Waypoints")
	if waypoints_node:
		print("\nFound existing waypoints node - NPCs can use these for patrolling")
	else:
		print("\nNo waypoints found - NPCs will wander within their radius")
	
	print("\nNPC setup complete!")
	print("Remember to:")
	print("1. Save the scene")
	print("2. Set up specific waypoints for each area if needed")
	print("3. Test NPC movement in each room")
	print("4. Ensure NavigationRegion3D covers all walkable areas")