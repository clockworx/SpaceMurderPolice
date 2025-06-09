extends Node

# This script ensures NPCs start moving properly after initialization

static func initialize_npcs():
	# Wait a moment for everything to settle
	await Engine.get_main_loop().create_timer(1.0).timeout
	
	# Find all NPCs and ensure they start moving
	var npcs = Engine.get_main_loop().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.has_method("_choose_new_target"):
			print("Initializing movement for " + npc.npc_name)
			# Force them to pick a target
			npc.idle_timer = 0.1
			npc.is_idle = true