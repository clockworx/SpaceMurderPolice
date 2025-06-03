extends StaticBody3D
class_name SlidingDoor

@export var slide_distance: float = 2.0
@export var slide_duration: float = 1.0
@export var auto_close_delay: float = 3.0
@export var door_name: String = "Door"
@export var slide_direction: Vector3 = Vector3.RIGHT  # Direction to slide in local space

var door_mesh: MeshInstance3D
var collision_shape: CollisionShape3D

var is_open: bool = false
var is_moving: bool = false
var tween: Tween
var close_timer: Timer
var initial_position: Vector3

signal door_opened
signal door_closed

func _ready():
	collision_layer = 2  # Interactable layer
	collision_mask = 1   # Collide with environment
	
	# Find nodes
	door_mesh = get_node_or_null("DoorMesh")
	collision_shape = get_node_or_null("CollisionShape3D")
	
	if not door_mesh:
		push_error("SlidingDoor: DoorMesh node not found!")
		return
		
	if not collision_shape:
		push_error("SlidingDoor: CollisionShape3D node not found!")
	
	# Store initial position
	initial_position = door_mesh.position
	# Door initialized
	
	# Create auto-close timer
	close_timer = Timer.new()
	close_timer.wait_time = auto_close_delay
	close_timer.one_shot = true
	close_timer.timeout.connect(_on_close_timer_timeout)
	add_child(close_timer)

func interact():
	if not door_mesh:
		push_error("Cannot interact - DoorMesh is null!")
		return
		
	if is_moving:
		return
		
	if is_open:
		close_door()
	else:
		open_door()

func open_door():
	if is_open or is_moving or not door_mesh:
		return
		
	# Opening door
	is_moving = true
	
	# Kill any existing tween
	if tween and tween.is_valid():
		tween.kill()
	
	# Create new tween for opening
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	var target_pos = initial_position + (slide_direction.normalized() * slide_distance)
	# Opening door
	
	tween.tween_property(door_mesh, "position", target_pos, slide_duration)
	tween.tween_callback(_on_door_opened)

func close_door():
	if not is_open or is_moving or not door_mesh:
		return
		
	# Closing door
	is_moving = true
	close_timer.stop()
	
	# Kill any existing tween
	if tween and tween.is_valid():
		tween.kill()
	
	# Create new tween for closing
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(door_mesh, "position", initial_position, slide_duration)
	tween.tween_callback(_on_door_closed)

func _on_door_opened():
	is_open = true
	is_moving = false
	if collision_shape:
		collision_shape.disabled = true
	door_opened.emit()
	# Door opened
	
	# Start auto-close timer
	close_timer.start()

func _on_door_closed():
	is_open = false
	is_moving = false
	if collision_shape:
		collision_shape.disabled = false
	door_closed.emit()
	# Door closed

func _on_close_timer_timeout():
	close_door()

func get_interaction_prompt() -> String:
	return "Press [E] to " + ("close" if is_open else "open") + " " + door_name