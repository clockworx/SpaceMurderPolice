extends MovementInterface
class_name DirectMovement

var character: CharacterBody3D
var target_position: Vector3 = Vector3.ZERO
var movement_speed: float = 3.5
var reach_distance: float = 2.0  # Increased for better stopping distance
var is_active: bool = false
var path_check_raycast: RayCast3D
var stuck_timer: float = 0.0
var stuck_threshold: float = 2.0
var last_position: Vector3
var avoidance_radius: float = 1.5  # Distance to maintain from other characters
var avoidance_force: float = 5.0  # Strength of avoidance
var rotation_speed: float = 10.0  # How fast to rotate towards movement direction

func _init(body: CharacterBody3D = null) -> void:
	if body:
		character = body

func _ready() -> void:
	set_physics_process(false)
	_setup_raycast()

func _setup_raycast() -> void:
	if not character:
		return
		
	path_check_raycast = RayCast3D.new()
	path_check_raycast.enabled = true
	path_check_raycast.collision_mask = 1  # Check environment layer
	character.add_child(path_check_raycast)
	path_check_raycast.position.y = 0.5  # Chest height

func move_to_position(position: Vector3) -> void:
	# Don't check full path at start - just start moving
	# We'll check for obstacles during movement
	
	# print("DirectMovement: move_to_position called with ", position)
	
	# Ensure Y position matches character's current Y
	target_position = position
	if character:
		target_position.y = character.global_position.y
		last_position = character.global_position
	else:
		last_position = Vector3.ZERO
	
	is_active = true
	stuck_timer = 0.0
	set_physics_process(true)
	# print("DirectMovement: is_active = ", is_active, ", physics process enabled")

func stop_movement() -> void:
	is_active = false
	set_physics_process(false)
	if character:
		character.velocity = Vector3.ZERO

func is_moving() -> bool:
	return is_active

func get_current_target() -> Vector3:
	return target_position

func _physics_process(delta: float) -> void:
	if not character or not is_active:
		return
	
	var current_pos = character.global_position
	var distance = current_pos.distance_to(target_position)
	
	# print("DirectMovement: Distance to target: ", distance)
	
	if distance <= reach_distance:
		stop_movement()
		movement_completed.emit()
		return
	
	var direction = (target_position - current_pos).normalized()
	direction.y = 0
	
	# Add avoidance for other NPCs
	var avoidance_vector = _calculate_avoidance()
	direction += avoidance_vector
	direction = direction.normalized()
	
	character.velocity.x = direction.x * movement_speed
	character.velocity.z = direction.z * movement_speed
	
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	else:
		character.velocity.y = 0
	
	character.move_and_slide()
	
	# Rotate to face movement direction
	if direction.length() > 0.1:
		var look_direction = Vector3(direction.x, 0, direction.z)
		var target_transform = character.transform.looking_at(character.global_position + look_direction, Vector3.UP)
		character.transform = character.transform.interpolate_with(target_transform, rotation_speed * delta)
	
	# Check for stuck condition
	var movement_delta = current_pos.distance_to(last_position)
	if movement_delta < 0.01:  # Not moving
		stuck_timer += delta
		if stuck_timer > stuck_threshold:
			print("DirectMovement: Stuck! Movement delta: ", movement_delta)
			movement_failed.emit("Stuck - no movement detected")
			stop_movement()
	else:
		stuck_timer = 0.0
		last_position = current_pos

func _calculate_avoidance() -> Vector3:
	var avoidance = Vector3.ZERO
	var my_pos = character.global_position
	
	# Check for other NPCs in the scene
	var npcs = character.get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc == character or not npc is CharacterBody3D:
			continue
			
		var other_pos = npc.global_position
		var distance = my_pos.distance_to(other_pos)
		
		# If within avoidance radius, push away
		if distance < avoidance_radius and distance > 0.1:
			var push_direction = (my_pos - other_pos).normalized()
			var push_strength = (avoidance_radius - distance) / avoidance_radius
			avoidance += push_direction * push_strength * avoidance_force
	
	# Also check for player if present
	var player = character.get_tree().get_first_node_in_group("player")
	if player and player is CharacterBody3D:
		var player_pos = player.global_position
		var distance = my_pos.distance_to(player_pos)
		
		if distance < avoidance_radius and distance > 0.1:
			var push_direction = (my_pos - player_pos).normalized()
			var push_strength = (avoidance_radius - distance) / avoidance_radius
			avoidance += push_direction * push_strength * avoidance_force
	
	avoidance.y = 0  # Keep avoidance horizontal
	return avoidance