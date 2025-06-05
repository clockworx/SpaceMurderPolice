extends StaticBody3D
class_name ShipExitDoor

func _ready():
	add_to_group("interactable")

func interact():
	print("Exiting The Deduction...")
	var ship_interior = get_parent()
	if ship_interior.has_method("_exit_to_mission"):
		ship_interior._exit_to_mission()

func get_interaction_prompt() -> String:
	return "Press [E] to exit ship"

func on_hover_start():
	pass

func on_hover_end():
	pass