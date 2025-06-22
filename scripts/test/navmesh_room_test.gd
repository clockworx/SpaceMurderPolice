extends Node
class_name NavMeshRoomTest

# Test script to verify NavMesh navigation between rooms

var test_positions: Dictionary = {
	"Laboratory": Vector3(0, 0, 0),
	"Medical Bay": Vector3(-15, 0, 0),
	"Security Office": Vector3(15, 0, 0),
	"Engineering": Vector3(0, 0, -15),
	"Crew Quarters": Vector3(-15, 0, -15),
	"Cafeteria": Vector3(15, 0, -15)
}

var current_test_index: int = 0
var test_running: bool = false
var npc: NPCBase
var ui_control: Control
var ui_visible: bool = true

func _ready():
	print("NavMesh Room Test starting...")
	
	# Wait for scene to load
	await get_tree().process_frame
	
	# Find NPC
	npc = get_tree().get_first_node_in_group("npcs")
	if not npc:
		print("ERROR: No NPC found for testing!")
		return
	
	print("Found NPC: ", npc.npc_name)
	
	# Ensure NPC is using NavMesh
	npc.use_navmesh = true
	npc.use_waypoints = false
	
	# Create test UI
	_create_test_ui()

func _create_test_ui():
	# Release mouse for UI interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	ui_control = Control.new()
	ui_control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui_control.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it captures mouse
	add_child(ui_control)
	
	# Add background panel
	var panel = Panel.new()
	panel.position = Vector2(10, 100)
	panel.size = Vector2(300, 400)
	panel.modulate = Color(0.1, 0.1, 0.1, 0.8)
	ui_control.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "NavMesh Room Navigation Test"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var instructions = Label.new()
	instructions.text = "Press F2 to toggle this UI\nF1 for main debug UI"
	instructions.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(instructions)
	
	var start_button = Button.new()
	start_button.text = "Start Room Navigation Test"
	start_button.pressed.connect(_start_test)
	vbox.add_child(start_button)
	
	var stop_button = Button.new()
	stop_button.text = "Stop Test"
	stop_button.pressed.connect(_stop_test)
	vbox.add_child(stop_button)
	
	# Add individual room buttons
	vbox.add_child(HSeparator.new())
	
	var room_label = Label.new()
	room_label.text = "Direct Room Navigation:"
	vbox.add_child(room_label)
	
	for room_name in test_positions:
		var button = Button.new()
		button.text = "Go to " + room_name
		button.pressed.connect(_go_to_room.bind(room_name))
		vbox.add_child(button)
	
	# Status label
	vbox.add_child(HSeparator.new())
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Status: Ready"
	vbox.add_child(status_label)

func _start_test():
	if test_running:
		return
	
	print("Starting NavMesh room navigation test...")
	test_running = true
	current_test_index = 0
	_test_next_room()

func _stop_test():
	test_running = false
	print("Test stopped")
	_update_status("Test stopped")

func _test_next_room():
	if not test_running or not npc:
		return
	
	var room_names = test_positions.keys()
	if current_test_index >= room_names.size():
		print("Test complete! All rooms visited.")
		_update_status("Test complete!")
		test_running = false
		return
	
	var room_name = room_names[current_test_index]
	var position = test_positions[room_name]
	
	print("Testing navigation to: ", room_name)
	_update_status("Navigating to " + room_name + "...")
	
	# Find the actual room waypoint position
	var waypoint = get_tree().get_first_node_in_group(room_name.replace(" ", "") + "_Waypoint")
	if waypoint and waypoint is Node3D:
		position = waypoint.global_position
		print("  Using waypoint position: ", position)
	else:
		print("  Using fallback position: ", position)
	
	# Move NPC
	npc.force_move_to_position(position)
	
	# Wait for movement to complete or timeout
	await _wait_for_movement_complete(15.0)
	
	# Move to next room
	current_test_index += 1
	if test_running:
		await get_tree().create_timer(2.0).timeout
		_test_next_room()

func _wait_for_movement_complete(timeout: float):
	var timer = 0.0
	while timer < timeout and npc.movement_system.is_moving():
		await get_tree().create_timer(0.1).timeout
		timer += 0.1
	
	if timer >= timeout:
		print("  Movement timed out!")
		_update_status("Movement timed out!")
	else:
		print("  Movement completed!")
		_update_status("Reached destination")

func _go_to_room(room_name: String):
	if not npc:
		return
	
	print("Manual navigation to: ", room_name)
	var position = test_positions[room_name]
	
	# Try to find actual waypoint
	var waypoint = get_tree().get_first_node_in_group(room_name.replace(" ", "") + "_Waypoint")
	if waypoint and waypoint is Node3D:
		position = waypoint.global_position
	
	_update_status("Going to " + room_name)
	npc.force_move_to_position(position)

func _update_status(text: String):
	var status_label = ui_control.get_node_or_null("Panel/VBoxContainer/StatusLabel")
	if status_label:
		status_label.text = "Status: " + text

func _input(event):
	# Press F2 to toggle test UI
	if event.is_action_pressed("ui_focus_next") or (event is InputEventKey and event.pressed and event.keycode == KEY_F2):
		ui_visible = not ui_visible
		ui_control.visible = ui_visible
		
		if ui_visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		print("NavMesh test UI toggled: ", ui_visible)