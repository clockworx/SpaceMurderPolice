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
	
	print("Evidence Spawn Manager: Spawned ", spawned_evidence.size(), " evidence items")
	evidence_spawned.emit(spawned_evidence.size())

func _get_scene_for_type(type: String) -> PackedScene:
	# Try to match evidence type with scene
	for scene in evidence_scenes:
		var resource_path = scene.resource_path.to_lower()
		if type.to_lower() in resource_path:
			return scene
	
	# Return random if no match
	return evidence_scenes[randi() % evidence_scenes.size()] if not evidence_scenes.is_empty() else null

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
