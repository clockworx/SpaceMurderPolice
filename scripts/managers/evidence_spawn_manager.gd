extends Node
class_name EvidenceSpawnManager

@export var evidence_scenes: Array[PackedScene] = []
@export var spawn_count_min: int = 5
@export var spawn_count_max: int = 8
@export var guaranteed_evidence_types: Array[String] = ["Weapon", "Digital", "Physical"]

var spawn_points: Array[Node3D] = []
var spawned_evidence: Array[Node] = []

signal evidence_spawned(count: int)

func _ready():
	add_to_group("evidence_spawn_manager")
	
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Find all spawn points in the scene
	_find_spawn_points()
	
	# Spawn evidence
	_spawn_evidence()

func _find_spawn_points():
	spawn_points.clear()
	var all_spawn_points = get_tree().get_nodes_in_group("evidence_spawn_point")
	spawn_points.append_array(all_spawn_points)
	
	print("Evidence Spawn Manager: Found ", spawn_points.size(), " spawn points")

func _spawn_evidence():
	if spawn_points.is_empty():
		push_error("No spawn points found!")
		return
		
	if evidence_scenes.is_empty():
		push_error("No evidence scenes configured!")
		return
	
	# Check game mode
	print("Evidence Spawn Manager: Current game mode is ", GameStateManager.get_mode_name())
	if GameStateManager.is_story_mode():
		_spawn_story_mode_evidence()
	else:
		_spawn_random_mode_evidence()

func _spawn_random_mode_evidence():
	# Determine how many evidence items to spawn
	var spawn_count = randi_range(spawn_count_min, spawn_count_max)
	spawn_count = min(spawn_count, spawn_points.size())
	
	# Shuffle spawn points
	var available_points = spawn_points.duplicate()
	available_points.shuffle()
	
	# Keep track of evidence types spawned
	var spawned_types: Dictionary = {}
	
	# First, ensure we spawn at least one of each guaranteed type
	for type in guaranteed_evidence_types:
		if available_points.is_empty():
			break
			
		var scene = _get_scene_for_type(type)
		if scene:
			var spawn_point = available_points.pop_front()
			_spawn_evidence_at_point(scene, spawn_point)
			spawned_types[type] = spawned_types.get(type, 0) + 1
	
	# Then spawn random evidence for remaining slots
	while spawned_evidence.size() < spawn_count and not available_points.is_empty():
		var spawn_point = available_points.pop_front()
		var random_scene = evidence_scenes[randi() % evidence_scenes.size()]
		_spawn_evidence_at_point(random_scene, spawn_point)
	
	print("Evidence Spawn Manager: Spawned ", spawned_evidence.size(), " evidence items (Random Mode)")
	evidence_spawned.emit(spawned_evidence.size())

func _spawn_story_mode_evidence():
	# Story mode - manually placed evidence with narrative logic
	print("Evidence Spawn Manager: Starting story mode evidence spawn")
	var story_evidence = _get_current_story_evidence()
	print("Evidence Spawn Manager: Story has ", story_evidence.size(), " evidence items to spawn")
	
	for evidence_data in story_evidence:
		print("Evidence Spawn Manager: Attempting to spawn ", evidence_data.type, " at ", evidence_data.position)
		var scene = _get_scene_for_type(evidence_data.type)
		if scene:
			print("Evidence Spawn Manager: Found scene for type ", evidence_data.type)
			var evidence = scene.instantiate()
			
			# Add to scene first
			get_tree().current_scene.add_child(evidence)
			
			# Force the node to be ready
			if not evidence.is_node_ready():
				await evidence.ready
			
			# Set fixed position from story data, with raycast adjustment
			var spawn_pos = evidence_data.position
			
			# Perform a raycast to find the surface below
			var space_state = get_tree().root.world_3d.direct_space_state
			var query = PhysicsRayQueryParameters3D.create(
				spawn_pos + Vector3.UP * 3,  # Start above
				spawn_pos - Vector3.UP * 3   # Cast down
			)
			query.collision_mask = 1  # Only hit environment layer
			
			var result = space_state.intersect_ray(query)
			if result:
				# Place evidence slightly above the surface
				spawn_pos = result.position + Vector3.UP * 0.5
				print("Evidence Spawn Manager: Adjusted position to avoid geometry")
			
			evidence.global_position = spawn_pos
			print("Evidence Spawn Manager: Placed ", evidence_data.evidence_id, " at ", evidence.global_position)
			print("  - Type: ", evidence_data.type)
			print("  - Description: ", evidence_data.description)
			
			# Add to evidence group for detection
			evidence.add_to_group("evidence")
			
			# Set specific properties for story mode
			if evidence.has_method("setup_story_evidence"):
				evidence.setup_story_evidence(evidence_data)
			
			spawned_evidence.append(evidence)
			
			# Connect signals
			if evidence.has_signal("evidence_collected"):
				evidence.evidence_collected.connect(_on_evidence_collected)
				
				var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
				if evidence_manager and evidence_manager.has_method("_on_evidence_collected"):
					evidence.evidence_collected.connect(evidence_manager._on_evidence_collected)
					
			print("Evidence Spawn Manager: Successfully spawned ", evidence_data.evidence_id)
		else:
			push_error("Evidence Spawn Manager: Could not find scene for type: " + evidence_data.type)
	
	print("Evidence Spawn Manager: Spawned ", spawned_evidence.size(), " evidence items (Story Mode)")
	evidence_spawned.emit(spawned_evidence.size())

func _get_current_story_evidence() -> Array:
	# Story: The Aurora Incident
	# Captain Diane Foster found dead in Laboratory 3
	return [
		{
			"type": "Weapon",
			"position": Vector3(-7.0, 1.5, 10.0),  # Laboratory 3 - above lab bench
			"description": "High-voltage plasma cutter with blood traces",
			"evidence_id": "aurora_weapon"
		},
		{
			"type": "Digital", 
			"position": Vector3(-7.0, 1.5, -5.0),  # Security Office - above desk
			"description": "Security logs showing deleted keycard access records",
			"evidence_id": "aurora_security_logs"
		},
		{
			"type": "Physical",
			"position": Vector3(7.0, 1.5, -20.0),  # Cafeteria - above table
			"description": "Captain's personal datapad with threatening messages",
			"evidence_id": "aurora_datapad"
		},
		{
			"type": "Document",
			"position": Vector3(7.0, 1.8, -10.0),  # Engineering - higher above console
			"description": "Sabotaged life support system diagnostics",
			"evidence_id": "aurora_diagnostics"
		},
		{
			"type": "Keycard",
			"position": Vector3(-7.0, 0.8, -15.0),  # Crew Quarters - above floor
			"description": "Riley's engineering keycard found outside quarters",
			"evidence_id": "aurora_keycard"
		},
		{
			"type": "Physical",
			"position": Vector3(0.0, 0.8, -10.0),  # Main hallway - above floor
			"description": "Bloody footprints leading from Lab 3 to Engineering",
			"evidence_id": "aurora_footprints"
		}
	]


func _get_scene_for_type(type: String) -> PackedScene:
	# Try to match evidence type with scene (case insensitive)
	var type_lower = type.to_lower()
	for scene in evidence_scenes:
		var resource_path = scene.resource_path.to_lower()
		if type_lower in resource_path:
			return scene
	
	# Return random if no match
	if not evidence_scenes.is_empty():
		push_warning("Evidence type '" + type + "' not found, using random scene")
		return evidence_scenes[randi() % evidence_scenes.size()]
	else:
		return null

func _spawn_evidence_at_point(scene: PackedScene, spawn_point: Node3D):
	var evidence = scene.instantiate()
	spawn_point.add_child(evidence)
	evidence.position = Vector3.ZERO
	
	# Add some random offset to make it less predictable
	var offset = Vector3(
		randf_range(-0.3, 0.3),
		0,
		randf_range(-0.3, 0.3)
	)
	evidence.position += offset
	
	# Randomize some properties
	if evidence.has_method("_on_spawn_randomize"):
		evidence._on_spawn_randomize()
	
	spawned_evidence.append(evidence)
	
	# Connect to evidence collected signal if available
	if evidence.has_signal("evidence_collected"):
		evidence.evidence_collected.connect(_on_evidence_collected)
		
		# Also connect to EvidenceManager
		var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
		if evidence_manager and evidence_manager.has_method("_on_evidence_collected"):
			evidence.evidence_collected.connect(evidence_manager._on_evidence_collected)
			print("Evidence Spawn Manager: Connected ", evidence.get("evidence_name"), " to Evidence Manager")

func _on_evidence_collected(evidence):
	spawned_evidence.erase(evidence)
	print("Evidence collected. Remaining: ", spawned_evidence.size())

func get_spawn_points_in_room(room_name: String) -> Array[Node3D]:
	var room_points: Array[Node3D] = []
	for point in spawn_points:
		var path_string = str(point.get_path())
		if room_name.to_lower() in path_string.to_lower():
			room_points.append(point)
	return room_points

func clear_all_evidence():
	for evidence in spawned_evidence:
		if is_instance_valid(evidence):
			evidence.queue_free()
	spawned_evidence.clear()

func respawn_evidence():
	clear_all_evidence()
	_spawn_evidence()
