extends Node3D

@export var waypoint_position: Vector3 = Vector3(5, 0, 0)

var npc: CharacterBody3D
var is_moving: bool = false

func _ready():
	npc = $SimpleTestNPC
	
	print("Debug Movement Test Started")
	print("Press SPACE to move to waypoint")
	print("NPC position: ", npc.global_position)
	print("Target position: ", waypoint_position)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select") and not is_moving:
		print("\n--- Starting movement ---")
		is_moving = true
		_move_npc()

func _move_npc():
	# Direct movement without any movement system
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not is_moving or not npc:
		return
	
	var distance = npc.global_position.distance_to(waypoint_position)
	print("Distance to target: ", distance)
	
	if distance < 1.0:
		print("Reached target!")
		is_moving = false
		set_physics_process(false)
		return
	
	var direction = (waypoint_position - npc.global_position).normalized()
	direction.y = 0
	
	npc.velocity.x = direction.x * 3.5
	npc.velocity.z = direction.z * 3.5
	
	if not npc.is_on_floor():
		npc.velocity.y -= 9.8 * delta
	else:
		npc.velocity.y = 0
	
	npc.move_and_slide()
	
	print("Moving - Velocity: ", npc.velocity)