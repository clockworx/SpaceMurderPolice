extends Node3D

@export var test_waypoints: Array[Vector3] = [
	Vector3(3, 0, 0),
	Vector3(5, 0, 0),
	Vector3(5, 0, 5),
	Vector3(0, 0, 5),
	Vector3(-5, 0, 5),
	Vector3(-5, 0, 0),
	Vector3(-5, 0, -5),
	Vector3(0, 0, -5),
	Vector3(5, 0, -5)
]

var direct_npc: NPCBase
var navmesh_npc: NPCBase
var selected_npc: NPCBase
var current_waypoint_index: int = 0
var waypoint_markers: Array[MeshInstance3D] = []

func _ready():
	# Find NPCs
	direct_npc = get_node_or_null("../TestNPC_Direct")
	navmesh_npc = get_node_or_null("../TestNPC_NavMesh")
	
	if not direct_npc or not navmesh_npc:
		push_error("Could not find test NPCs!")
		return
	
	# Select first NPC by default
	selected_npc = direct_npc
	
	# Create waypoint markers
	_create_waypoint_markers()
	
	print("NPC Movement Test Started")
	print("Direct NPC uses: ", "NavMesh" if direct_npc.use_navmesh else "Direct", " movement")
	print("NavMesh NPC uses: ", "NavMesh" if navmesh_npc.use_navmesh else "Direct", " movement")
	print("Selected: ", selected_npc.npc_name)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_select_npc(direct_npc)
			KEY_2:
				_select_npc(navmesh_npc)
			KEY_N:
				_move_to_next_waypoint()
			KEY_R:
				_reset_positions()
			KEY_SPACE:
				_toggle_movement_system()

func _select_npc(npc: NPCBase):
	selected_npc = npc
	print("\nSelected: ", selected_npc.npc_name)
	print("Movement system: ", "NavMesh" if selected_npc.use_navmesh else "Direct")

func _move_to_next_waypoint():
	if not selected_npc:
		return
	
	var target = test_waypoints[current_waypoint_index]
	print("\nMoving ", selected_npc.npc_name, " to waypoint ", current_waypoint_index, " at ", target)
	
	# Set NPC to patrol state and move
	selected_npc.set_patrol_state()
	selected_npc.move_to_position(target)
	
	# Update waypoint index
	current_waypoint_index = (current_waypoint_index + 1) % test_waypoints.size()
	_update_marker_colors()

func _reset_positions():
	print("\nResetting NPC positions")
	
	if direct_npc:
		direct_npc.global_position = Vector3(-5, 0.1, 0)
		direct_npc.stop_movement()
		direct_npc.set_idle_state()
	
	if navmesh_npc:
		navmesh_npc.global_position = Vector3(5, 0.1, 0)
		navmesh_npc.stop_movement()
		navmesh_npc.set_idle_state()
	
	current_waypoint_index = 0
	_update_marker_colors()

func _toggle_movement_system():
	if not selected_npc:
		return
	
	print("\nToggling movement system for ", selected_npc.npc_name)
	
	# Stop current movement
	selected_npc.stop_movement()
	
	# Toggle the system
	selected_npc.use_navmesh = !selected_npc.use_navmesh
	
	# Recreate movement system
	if selected_npc.movement_system:
		selected_npc.movement_system.queue_free()
	
	if selected_npc.use_navmesh:
		selected_npc.movement_system = NavMeshMovement.new(selected_npc)
	else:
		selected_npc.movement_system = DirectMovement.new(selected_npc)
	
	selected_npc.add_child(selected_npc.movement_system)
	selected_npc.movement_system.movement_completed.connect(selected_npc._on_movement_completed)
	selected_npc.movement_system.movement_failed.connect(selected_npc._on_movement_failed)
	
	print("Now using: ", "NavMesh" if selected_npc.use_navmesh else "Direct", " movement")

func _create_waypoint_markers():
	for i in range(test_waypoints.size()):
		var marker = MeshInstance3D.new()
		
		# Create sphere mesh
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		
		marker.mesh = sphere
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		material.emission_enabled = true
		material.emission = Color.WHITE
		material.emission_energy = 0.3
		
		marker.material_override = material
		marker.position = test_waypoints[i]
		
		# Add label
		var label = Label3D.new()
		label.text = str(i)
		label.position.y = 0.5
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color.BLACK
		marker.add_child(label)
		
		get_parent().add_child(marker)
		waypoint_markers.append(marker)

func _update_marker_colors():
	for i in range(waypoint_markers.size()):
		var material = waypoint_markers[i].material_override as StandardMaterial3D
		if material:
			if i == current_waypoint_index:
				material.albedo_color = Color.YELLOW  # Next target
			else:
				material.albedo_color = Color.WHITE
			material.emission = material.albedo_color