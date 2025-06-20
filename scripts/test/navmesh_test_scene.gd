extends Node3D

# Script to set up and test NavMesh navigation in NewStation scene

@onready var npc = $ChiefScientist

func _ready():
	print("NavMesh Test Scene starting...")
	
	# Wait for scene to be fully loaded
	await get_tree().process_frame
	
	# Find the NPC
	if not npc:
		npc = get_tree().get_first_node_in_group("npcs")
	
	if npc:
		print("Found NPC: ", npc.npc_name)
		# Enable NavMesh movement
		npc.use_navmesh = true
		npc.use_waypoints = false  # Disable waypoint system
		print("Switched NPC to NavMesh movement system")
		
		# Create UI for testing
		_create_test_ui()
	else:
		print("ERROR: No NPC found!")

func _create_test_ui():
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	add_child(vbox)
	
	var label = Label.new()
	label.text = "NavMesh Navigation Test"
	label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label)
	
	var movement_button = Button.new()
	movement_button.text = "Switch Movement System"
	movement_button.pressed.connect(_toggle_movement_system)
	vbox.add_child(movement_button)
	
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Current: " + ("NavMesh" if npc.use_navmesh else "Direct/Waypoint")
	vbox.add_child(status_label)

func _toggle_movement_system():
	if npc:
		npc.use_navmesh = not npc.use_navmesh
		var status_label = $VBoxContainer/StatusLabel
		if status_label:
			status_label.text = "Current: " + ("NavMesh" if npc.use_navmesh else "Direct/Waypoint")
		print("Switched to: ", "NavMesh" if npc.use_navmesh else "Direct/Waypoint")

func _input(event):
	# Press F2 to toggle between movement systems
	if event.is_action_pressed("ui_focus_next"):  # F2 key
		_toggle_movement_system()