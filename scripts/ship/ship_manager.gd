extends Node
class_name ShipManager

# Manages transitions between ship and mission areas

static var current_mission_scene: String = ""
static var player_data: Dictionary = {}

signal entered_ship()
signal exited_ship()

func _ready():
	add_to_group("ship_manager")

func enter_ship(from_mission: String = ""):
	# Store current mission reference
	if from_mission != "":
		current_mission_scene = from_mission
	
	# Save player state
	_save_player_state()
	
	# Load ship scene
	print("Entering The Deduction...")
	get_tree().change_scene_to_file("res://scenes/ship/the_deduction.tscn")
	entered_ship.emit()

func exit_ship():
	# Return to mission
	if current_mission_scene == "":
		push_error("No mission scene to return to!")
		return
	
	print("Returning to mission...")
	get_tree().change_scene_to_file(current_mission_scene)
	
	# Wait for scene to load then restore player state
	await get_tree().process_frame
	_restore_player_state()
	
	exited_ship.emit()

func _save_player_state():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_data = {
			"position": player.global_position,
			"rotation": player.global_rotation,
			"evidence_count": _get_evidence_count()
		}

func _restore_player_state():
	var player = get_tree().get_first_node_in_group("player")
	if player and player_data.has("position"):
		# Move player to ship entrance location
		var ship_entrance = get_tree().get_first_node_in_group("ship_entrance")
		if ship_entrance:
			player.global_position = ship_entrance.global_position
		else:
			player.global_position = player_data["position"]
		
		player.global_rotation = player_data["rotation"]

func _get_evidence_count() -> int:
	var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
	if evidence_manager:
		return evidence_manager.collected_evidence.size()
	return 0

func can_enter_ship() -> bool:
	# Check if player can enter ship (e.g., not during night cycle)
	var day_night = get_tree().get_first_node_in_group("day_night_manager")
	if day_night and day_night.has_method("is_night_time"):
		return not day_night.is_night_time()
	return true