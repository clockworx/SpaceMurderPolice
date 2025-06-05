extends StaticBody3D
class_name EvidenceBoard

func _ready():
	add_to_group("interactable")
	collision_layer = 2

func interact():
	print("Opening evidence connection interface...")
	var ship_interior = get_tree().get_first_node_in_group("ship_interior")
	if ship_interior and ship_interior.has_method("interact_with_station"):
		ship_interior.interact_with_station("evidence_board")

func get_interaction_prompt() -> String:
	return "Press [E] to examine evidence board"

func on_hover_start():
	pass

func on_hover_end():
	pass