extends StaticBody3D
class_name ShipEntrance

@export var entrance_name: String = "The Deduction Airlock"
@export var require_all_evidence: bool = false
@export var minimum_evidence_count: int = 0

@onready var access_light = $AccessLight
@onready var interaction_area = $InteractionArea

var is_accessible: bool = true
var ship_manager: ShipManager

signal player_entered_ship()

func _ready():
	add_to_group("ship_entrance")
	add_to_group("interactable")
	
	# Find or create ship manager
	ship_manager = get_tree().get_first_node_in_group("ship_manager")
	if not ship_manager:
		ship_manager = ShipManager.new()
		get_tree().root.add_child(ship_manager)
	
	# Update access light
	_update_access_indicator()

func interact():
	if not is_accessible:
		print("The Deduction is not accessible at this time.")
		return
	
	# Check if player can enter
	if not ship_manager.can_enter_ship():
		print("Cannot enter ship during night cycle!")
		return
	
	# Check evidence requirements (only if explicitly set)
	if require_all_evidence or minimum_evidence_count > 0:
		var evidence_count = _get_collected_evidence_count()
		
		if require_all_evidence:
			var total_evidence = _get_total_evidence_count()
			if evidence_count < total_evidence:
				print("Collect all evidence before returning to ship (", evidence_count, "/", total_evidence, ")")
				return
		elif minimum_evidence_count > 0 and evidence_count < minimum_evidence_count:
			print("Collect more evidence before returning (", evidence_count, "/", minimum_evidence_count, ")")
			return
	
	# Enter the ship
	print("Entering The Deduction...")
	_board_ship()

func _board_ship():
	# Get current scene path
	var current_scene = get_tree().current_scene.scene_file_path
	
	# Transfer evidence to ship
	_transfer_evidence_to_ship()
	
	# Enter ship
	ship_manager.enter_ship(current_scene)
	player_entered_ship.emit()

func _transfer_evidence_to_ship():
	# Get evidence from mission and transfer to ship
	var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
	if evidence_manager and evidence_manager.has_method("get_collected_evidence"):
		var evidence = evidence_manager.get_collected_evidence()
		
		# This will be picked up by the ship when it loads
		ShipInterior.current_case_evidence = evidence
		print("Transferred ", evidence.size(), " evidence items to ship")

func _get_collected_evidence_count() -> int:
	var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
	if evidence_manager:
		return evidence_manager.collected_evidence.size()
	return 0

func _get_total_evidence_count() -> int:
	var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
	if evidence_manager:
		return evidence_manager.total_evidence_count
	return 0

func _update_access_indicator():
	if not access_light:
		return
	
	# Check if ship is accessible
	is_accessible = ship_manager.can_enter_ship() if ship_manager else true
	
	# Update light color
	var material = access_light.get_surface_override_material(0)
	if material and material is StandardMaterial3D:
		if is_accessible:
			material.emission = Color(0.2, 0.8, 0.2)  # Green when accessible
		else:
			material.emission = Color(0.8, 0.2, 0.2)  # Red when not accessible

func get_interaction_prompt() -> String:
	if not is_accessible:
		return "The Deduction (Not Accessible)"
	
	if require_all_evidence or minimum_evidence_count > 0:
		var evidence_count = _get_collected_evidence_count()
		if require_all_evidence:
			var total = _get_total_evidence_count()
			return "Press [E] to enter The Deduction (" + str(evidence_count) + "/" + str(total) + " evidence)"
		else:
			return "Press [E] to enter The Deduction (" + str(evidence_count) + "/" + str(minimum_evidence_count) + " evidence)"
	
	return "Press [E] to enter The Deduction"

func set_accessible(accessible: bool):
	is_accessible = accessible
	_update_access_indicator()