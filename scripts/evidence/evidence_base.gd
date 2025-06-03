extends StaticBody3D
class_name Interactable

@export var interaction_prompt: String = "Press [E] to interact"
@export var object_name: String = "Object"

signal interacted

func interact():
	print("Interacted with: " + object_name)
	interacted.emit()

func get_interaction_prompt() -> String:
	return interaction_prompt