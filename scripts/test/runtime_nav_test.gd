extends Node

# Runtime navigation test that can be activated with a key

var test_active: bool = false
var npc: NPCBase = null
var nav_test = null

func _ready():
	print("Runtime Navigation Test ready - Press F9 to activate")
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F9:
			if not test_active:
				activate_test()
			else:
				deactivate_test()

func activate_test():
	print("\n=== ACTIVATING NAVIGATION TEST ===")
	test_active = true
	
	# Find NPC
	npc = get_tree().get_first_node_in_group("npcs")
	if not npc:
		# Try finding by path
		npc = get_node_or_null("/root/NewStation/NPCs/ChiefScientist")
	
	if not npc:
		print("ERROR: No NPC found!")
		test_active = false
		return
	
	print("Found NPC: ", npc.npc_name if npc.get("npc_name") else npc.name)
	
	# Create navigation test
	nav_test = preload("res://scripts/test/navmesh_keyboard_test.gd").new()
	add_child(nav_test)
	
	print("Navigation test activated! Use number keys 1-6 to navigate")

func deactivate_test():
	print("Deactivating navigation test")
	test_active = false
	if nav_test:
		nav_test.queue_free()
		nav_test = null