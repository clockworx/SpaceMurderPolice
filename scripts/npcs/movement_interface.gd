extends Node
class_name MovementInterface

signal movement_completed
signal movement_failed(reason: String)

func move_to_position(target_position: Vector3) -> void:
	push_error("MovementInterface.move_to_position() is not implemented in " + get_class())

func stop_movement() -> void:
	push_error("MovementInterface.stop_movement() is not implemented in " + get_class())

func is_moving() -> bool:
	push_error("MovementInterface.is_moving() is not implemented in " + get_class())
	return false

func get_current_target() -> Vector3:
	push_error("MovementInterface.get_current_target() is not implemented in " + get_class())
	return Vector3.ZERO