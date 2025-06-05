extends StaticBody3D
class_name ComputerStation

func _ready():
	add_to_group("interactable")
	collision_layer = 2

func interact():
	print("Opening ship computer...")
	var ship_interior = get_tree().get_first_node_in_group("ship_interior")
	if ship_interior and ship_interior.has_method("interact_with_station"):
		ship_interior.interact_with_station("computer")

func get_interaction_prompt() -> String:
	return "Press [E] to access computer"

func on_hover_start():
	pass

func on_hover_end():
	pass