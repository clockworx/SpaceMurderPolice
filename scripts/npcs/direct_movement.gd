extends MovementInterface
class_name DirectMovement

var character: CharacterBody3D
var target_position: Vector3 = Vector3.ZERO
var movement_speed: float = 3.5
var reach_distance: float = 0.3  # Distance to consider target reached
var is_active: bool = false
var path_check_raycast: RayCast3D
var stuck_timer: float = 0.0
var stuck_threshold: float = 2.0
var last_position: Vector3
var avoidance_radius: float = 1.5  # Distance to maintain from other characters
var avoidance_force: float = 5.0  # Strength of avoidance
var rotation_speed: float = 10.0  # How fast to rotate towards movement direction
var wall_detection_distance: float = 2.0  # Distance to check for walls
var wall_avoidance_force: float = 8.0  # Strength of wall avoidance
var wall_check_rays: int = 8  # Number of rays to cast for wall detection
var doorway_detection_angle: float = 45.0  # Angle to check if heading through doorway
var min_movement_threshold: float = 0.1  # Minimum movement to prevent flickering
var previous_direction: Vector3 = Vector3.ZERO  # For smoothing
var direction_smoothing: float = 0.15  # How much to smooth direction changes

func _init(body: CharacterBody3D = null) -> void:
	if body:
		character = body
		# Get reach distance from NPC if available
		if body.has_method("get") and body.get("waypoint_reach_distance"):
			reach_distance = body.waypoint_reach_distance

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
	
	# Add avoidance for other NPCs and walls
	var avoidance_vector = _calculate_avoidance()
	var wall_avoidance = _calculate_wall_avoidance()
	
	# Check if we're heading through a doorway (reduce wall avoidance)
	var is_in_doorway = _is_heading_through_doorway(direction)
	if is_in_doorway:
		wall_avoidance *= 0.2  # Greatly reduce wall avoidance in doorways
	
	direction += avoidance_vector + wall_avoidance
	
	# Prevent flickering by ensuring minimum movement
	if direction.length() < min_movement_threshold:
		direction = (target_position - current_pos).normalized()
		direction.y = 0
	else:
		direction = direction.normalized()
	
	# Smooth direction changes to prevent flickering
	if previous_direction.length() > 0.1:
		direction = previous_direction.lerp(direction, direction_smoothing)
		direction = direction.normalized()
	
	previous_direction = direction
	
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

func _calculate_wall_avoidance() -> Vector3:
	if not character:
		return Vector3.ZERO
	
	var avoidance = Vector3.ZERO
	var space_state = character.get_world_3d().direct_space_state
	var my_pos = character.global_position
	
	# Reduce wall avoidance when very close to target (helps with doorways)
	var distance_to_target = my_pos.distance_to(target_position)
	var avoidance_multiplier = 1.0
	if distance_to_target < 3.0:
		avoidance_multiplier = distance_to_target / 3.0  # Fade out avoidance near target
	
	# Cast rays in a circle around the character
	for i in range(wall_check_rays):
		var angle = (i / float(wall_check_rays)) * TAU
		var direction = Vector3(cos(angle), 0, sin(angle))
		
		# Use shorter detection distance when close to target
		var detection_dist = wall_detection_distance
		if distance_to_target < 2.0:
			detection_dist = wall_detection_distance * 0.5
		
		# Cast ray from character position
		var from = my_pos + Vector3(0, 0.5, 0)  # Raise slightly to avoid ground
		var to = from + direction * detection_dist
		
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [character]
		query.collision_mask = 1  # Environment layer
		
		var result = space_state.intersect_ray(query)
		if result:
			# Calculate distance to wall
			var wall_distance = my_pos.distance_to(result.position)
			if wall_distance < wall_detection_distance:
				# Push away from wall
				var push_direction = -direction
				var push_strength = (wall_detection_distance - wall_distance) / wall_detection_distance
				avoidance += push_direction * push_strength * wall_avoidance_force
	
	avoidance.y = 0  # Keep avoidance horizontal
	return avoidance * avoidance_multiplier

func _is_heading_through_doorway(movement_direction: Vector3) -> bool:
	if not character or movement_direction.length() < 0.1:
		return false
	
	var space_state = character.get_world_3d().direct_space_state
	var my_pos = character.global_position
	
	# Check forward direction for walls on both sides (doorway detection)
	var forward = movement_direction.normalized()
	var right = forward.cross(Vector3.UP).normalized()
	
	# Cast rays to the left and right
	var check_distance = 1.5
	var from = my_pos + Vector3(0, 0.5, 0)
	
	var left_query = PhysicsRayQueryParameters3D.create(
		from,
		from + (-right) * check_distance
	)
	left_query.exclude = [character]
	left_query.collision_mask = 1
	
	var right_query = PhysicsRayQueryParameters3D.create(
		from,
		from + right * check_distance
	)
	right_query.exclude = [character]
	right_query.collision_mask = 1
	
	var left_hit = space_state.intersect_ray(left_query)
	var right_hit = space_state.intersect_ray(right_query)
	
	# If we have walls on both sides at similar distances, we're likely in a doorway
	if left_hit and right_hit:
		var left_dist = from.distance_to(left_hit.position)
		var right_dist = from.distance_to(right_hit.position)
		
		# Check if walls are roughly equidistant (doorway)
		if abs(left_dist - right_dist) < 1.0 and left_dist < 2.0 and right_dist < 2.0:
			return true
	
	return false