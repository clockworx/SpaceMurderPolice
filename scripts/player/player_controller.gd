extends CharacterBody3D

const WALK_SPEED = 3.5
const MOUSE_SENSITIVITY = 0.002
const GRAVITY = 9.8

@onready var camera_holder = $CameraHolder
@onready var camera = $CameraHolder/Camera3D
@onready var interaction_ray = $CameraHolder/Camera3D/InteractionRay

var interaction_system: InteractionSystem

signal interactable_detected(interactable)
signal interactable_lost

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	interaction_system = InteractionSystem.new()
	add_child(interaction_system)
	interaction_system.setup(interaction_ray)
	interaction_system.interactable_detected.connect(_on_interactable_detected)
	interaction_system.interactable_lost.connect(_on_interactable_lost)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_holder.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_holder.rotation.x = clamp(camera_holder.rotation.x, -1.5, 1.5)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("interact"):
		interaction_system.interact()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	var input_dir = Vector2()
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED * delta * 3)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED * delta * 3)
	
	move_and_slide()
	
	interaction_system.check_interaction()

func _on_interactable_detected(interactable):
	interactable_detected.emit(interactable)

func _on_interactable_lost():
	interactable_lost.emit()