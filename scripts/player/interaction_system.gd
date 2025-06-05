extends Node
class_name InteractionSystem

@export var interaction_range: float = 3.0
@export var interaction_layer: int = 2

var interaction_ray: RayCast3D
var current_interactable = null

signal interactable_detected(interactable)
signal interactable_lost

func setup(ray: RayCast3D) -> void:
	interaction_ray = ray
	interaction_ray.target_position = Vector3(0, 0, -interaction_range)
	interaction_ray.collision_mask = interaction_layer

func check_interaction() -> void:
	if not interaction_ray:
		return
		
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider != current_interactable:
			# Handle previous interactable
			if current_interactable:
				if current_interactable.has_method("on_hover_end"):
					current_interactable.on_hover_end()
				interactable_lost.emit()
			
			# Handle new interactable
			current_interactable = collider
			print("InteractionSystem: Hit ", collider.name, " - has interact: ", collider.has_method("interact"))
			if collider.has_method("interact"):
				if collider.has_method("on_hover_start"):
					collider.on_hover_start()
				interactable_detected.emit(collider)
	else:
		if current_interactable:
			if current_interactable.has_method("on_hover_end"):
				current_interactable.on_hover_end()
			current_interactable = null
			interactable_lost.emit()

func interact() -> void:
	if current_interactable and current_interactable.has_method("interact"):
		current_interactable.interact()