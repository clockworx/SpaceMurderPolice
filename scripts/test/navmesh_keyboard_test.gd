extends Node
class_name NavMeshKeyboardTest

# Keyboard-based NavMesh testing - no UI interaction needed

var room_positions: Dictionary = {
	"Laboratory": "Laboratory_Waypoint",
	"Medical Bay": "MedicalBay_Waypoint", 
	"Security Office": "Security_Waypoint",
	"Engineering": "Engineering_Waypoint",
	"Crew Quarters": "CrewQuarters_Waypoint",
	"Cafeteria": "Cafeteria_Waypoint"
}

var npc: NPCBase
var help_label: Label

func _ready():
	print("NavMesh Keyboard Test ready")
	print("Controls:")
	print("  1-6: Navigate to specific rooms")
	print("  0: Run test sequence through all rooms")
	print("  H: Toggle help display")
	
	# Find NPC - try multiple methods
	npc = get_tree().get_first_node_in_group("npcs")
	if not npc:
		# Try finding by node path
		npc = get_node_or_null("/root/NewStation/NPCs/ChiefScientist")
		if not npc:
			# Try finding by class
			var all_nodes = []
			_get_all_nodes(get_tree().root, all_nodes)
			for node in all_nodes:
				if node.has_method("force_move_to_position") and node.get("npc_name"):
					npc = node
					print("Found NPC by class: ", node.npc_name)
					break
	
	if not npc:
		print("ERROR: No NPC found!")
		return
	
	print("Found NPC: ", npc.npc_name if npc.get("npc_name") else npc.name)
		
	# Ensure NavMesh is enabled and disable standard waypoint following
	npc.use_navmesh = true
	npc.use_waypoints = false  # Disable standard waypoint following to avoid interference
	
	# Wait a frame to ensure waypoint-guided nav is initialized
	await get_tree().process_frame
	
	# Force runtime initialization if needed
	if npc.has_method("_ensure_waypoint_guided_nav_initialized"):
		npc._ensure_waypoint_guided_nav_initialized()
		await get_tree().process_frame
	
	# Force NPC to reposition to room center if against wall
	print("\nChecking NPC initial position...")
	if npc.global_position.x > 2.5 or npc.global_position.x < -2.5:  # Likely against a wall
		print("NPC appears to be against a wall, repositioning to laboratory center")
		# Move to lab center first
		var lab_center = Vector3(0.0, npc.global_position.y, 10.0)
		npc.global_position = lab_center
		await get_tree().create_timer(0.5).timeout
		print("NPC repositioned to: ", npc.global_position)
	
	# Debug: List all waypoints
	print("\nDEBUG: Checking waypoint positions:")
	for room_name in room_positions:
		var waypoint_name = room_positions[room_name]
		var waypoint = get_tree().get_first_node_in_group(waypoint_name)
		if waypoint:
			print("  ", room_name, " (", waypoint_name, ") at: ", waypoint.global_position)
		else:
			print("  ", room_name, " (", waypoint_name, ") - NOT FOUND!")
	
	# Create help display
	_create_help_display()

func _create_help_display():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	help_label = Label.new()
	help_label.position = Vector2(20, 20)
	help_label.add_theme_font_size_override("font_size", 16)
	help_label.add_theme_color_override("font_color", Color(1, 1, 0))
	help_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	help_label.add_theme_constant_override("shadow_offset_x", 2)
	help_label.add_theme_constant_override("shadow_offset_y", 2)
	
	help_label.text = """NavMesh Keyboard Controls:
1: Laboratory
2: Medical Bay  
3: Security Office
4: Engineering
5: Crew Quarters
6: Cafeteria
0: Test All Rooms
H: Hide This Help"""
	
	canvas.add_child(help_label)

func _input(event):
	if not event.is_pressed() or not npc:
		return
		
	if event is InputEventKey:
		match event.keycode:
			KEY_1:
				_go_to_room("Laboratory")
			KEY_2:
				_go_to_room("Medical Bay")
			KEY_3:
				_go_to_room("Security Office")
			KEY_4:
				_go_to_room("Engineering")
			KEY_5:
				_go_to_room("Crew Quarters")
			KEY_6:
				_go_to_room("Cafeteria")
			KEY_0:
				_test_all_rooms()
			KEY_H:
				if help_label:
					help_label.visible = not help_label.visible

func _go_to_room(room_name: String):
	var waypoint_name = room_positions.get(room_name, "")
	if waypoint_name.is_empty():
		print("Unknown room: ", room_name)
		return
		
	print("\n=== NAVIGATING TO ", room_name, " (", waypoint_name, ") ===")
	
	# Stop any current movement first
	if npc.has_method("stop_movement"):
		npc.stop_movement()
	
	# Force stop any waypoint following
	npc.is_paused = true
	npc.use_waypoints = false
	
	# Check if NPC has waypoint-guided navigation
	if npc.has_method("get_waypoint_guided_nav"):
		var wp_nav = npc.get_waypoint_guided_nav()
		if wp_nav:
			print("  [WAYPOINT-GUIDED] Navigation system found")
			# Stop any existing navigation
			wp_nav.stop_navigation()
			
			# Wait a frame
			await get_tree().process_frame
			
			# Try to navigate
			if wp_nav.navigate_to_room(waypoint_name):
				print("  [SUCCESS] Waypoint-guided navigation started!")
				# Update help text to show current destination
				if help_label:
					help_label.modulate = Color(1, 1, 0, 0.5)  # Dim while moving
					help_label.text += "\n\nNavigating to: " + room_name
				return
			else:
				print("  [FAILED] Waypoint-guided navigation couldn't find path")
		else:
			print("  [ERROR] Waypoint-guided nav is null!")
	else:
		print("  [ERROR] NPC doesn't have get_waypoint_guided_nav method")
	
	# Fallback: Find waypoint and use force_move_to_position
	print("  [FALLBACK] Using force_move_to_position")
	var waypoint = get_tree().get_first_node_in_group(waypoint_name)
	if waypoint and waypoint is Node3D:
		print("  Waypoint found at: ", waypoint.global_position)
		print("  NPC current position: ", npc.global_position)
		npc.force_move_to_position(waypoint.global_position)
		
		# Update help text to show current destination
		if help_label:
			help_label.modulate = Color(1, 1, 0, 0.5)  # Dim while moving
			help_label.text += "\n\nNavigating to: " + room_name
	else:
		print("ERROR: Waypoint not found: ", waypoint_name)
		# Try alternative search
		var alt_waypoint = get_node_or_null("/root/NewStation/Waypoints/" + waypoint_name)
		if alt_waypoint:
			print("  Found waypoint via alternate path at: ", alt_waypoint.global_position)
			npc.force_move_to_position(alt_waypoint.global_position)
		else:
			print("  Waypoint not found in scene tree either")

var test_index: int = 0
var test_running: bool = false

func _test_all_rooms():
	if test_running:
		print("Test already running")
		return
		
	print("Starting room navigation test...")
	test_running = true
	test_index = 0
	_test_next_room()

func _test_next_room():
	if not test_running:
		return
		
	var room_names = room_positions.keys()
	if test_index >= room_names.size():
		print("Test complete!")
		test_running = false
		if help_label:
			help_label.modulate = Color(1, 1, 0, 1)
			help_label.text = help_label.text.split("\n\n")[0]  # Remove status
		return
		
	var room_name = room_names[test_index]
	_go_to_room(room_name)
	
	# Wait and continue
	test_index += 1
	await get_tree().create_timer(8.0).timeout
	_test_next_room()

func _get_all_nodes(node: Node, array: Array):
	array.append(node)
	for child in node.get_children():
		_get_all_nodes(child, array)