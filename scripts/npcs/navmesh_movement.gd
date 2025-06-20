extends MovementInterface
class_name NavMeshMovement

var character: CharacterBody3D
var nav_agent: NavigationAgent3D
var movement_speed: float = 3.5
var is_active: bool = false
var rotation_speed: float = 10.0  # How fast to rotate towards movement direction

func _init(body: CharacterBody3D = null) -> void:
	if body:
		character = body

func _ready() -> void:
	set_physics_process(false)
	# Defer setup to ensure character is ready
	call_deferred("_setup_nav_agent")

func _setup_nav_agent() -> void:
	if not character:
		print("NavMeshMovement: No character assigned!")
		return
		
	# print("NavMeshMovement: Setting up NavigationAgent3D for ", character.name)
	
	# Check if NavigationAgent3D already exists as child
	for child in character.get_children():
		if child is NavigationAgent3D:
			nav_agent = child
			# print("NavMeshMovement: Found existing NavigationAgent3D")
			if not nav_agent.navigation_finished.is_connected(_on_navigation_finished):
				nav_agent.navigation_finished.connect(_on_navigation_finished)
			if not nav_agent.velocity_computed.is_connected(_on_velocity_computed):
				nav_agent.velocity_computed.connect(_on_velocity_computed)
			return
	
	# Create new NavigationAgent3D if none exists
	# print("NavMeshMovement: Creating new NavigationAgent3D")
	nav_agent = NavigationAgent3D.new()
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = character.get("waypoint_reach_distance") if character.has_method("get") and character.get("waypoint_reach_distance") else 0.3
	nav_agent.path_max_distance = 1.0
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 0.5  # Match navigation mesh settings
	nav_agent.height = 1.75
	nav_agent.max_neighbors = 10
	nav_agent.neighbor_distance = 2.0  # Detection radius for other agents
	nav_agent.time_horizon_agents = 2.0
	nav_agent.time_horizon_obstacles = 0.5
	nav_agent.max_speed = movement_speed
	nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	
	character.add_child(nav_agent)
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	# print("NavMeshMovement: NavigationAgent3D created and connected")

func move_to_position(position: Vector3) -> void:
	if not nav_agent:
		movement_failed.emit("NavigationAgent3D not initialized")
		return
	
	# print("NavMeshMovement: move_to_position called with ", position)
	
	# Ensure Y position matches character's current Y
	var adjusted_position = position
	if character:
		adjusted_position.y = character.global_position.y
	
	nav_agent.target_position = adjusted_position
	is_active = true
	set_physics_process(true)
	# print("NavMeshMovement: is_active = ", is_active, ", target set to ", adjusted_position)

func stop_movement() -> void:
	is_active = false
	set_physics_process(false)
	if character:
		character.velocity = Vector3.ZERO

func is_moving() -> bool:
	return is_active

func get_current_target() -> Vector3:
	if nav_agent:
		return nav_agent.target_position
	return Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not character or not nav_agent or not is_active:
		return
	
	var distance_to_target = character.global_position.distance_to(nav_agent.target_position)
	
	if nav_agent.is_navigation_finished():
		# print("NavMeshMovement: Navigation finished, distance to target: ", distance_to_target)
		if distance_to_target <= nav_agent.target_desired_distance:
			return
	
	var next_position = nav_agent.get_next_path_position()
	var current_pos = character.global_position
	var direction = (next_position - current_pos).normalized()
	direction.y = 0
	
	# print("NavMeshMovement: Moving from ", current_pos, " to next ", next_position)
	
	var desired_velocity = direction * movement_speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.velocity = desired_velocity
	else:
		_apply_movement(desired_velocity, delta)

func _apply_movement(velocity: Vector3, delta: float) -> void:
	character.velocity.x = velocity.x
	character.velocity.z = velocity.z
	
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	else:
		character.velocity.y = 0
	
	character.move_and_slide()
	
	# Rotate to face movement direction
	if velocity.length() > 0.1:
		var look_direction = Vector3(velocity.x, 0, velocity.z).normalized()
		if look_direction.length() > 0.1:
			var target_transform = character.transform.looking_at(character.global_position + look_direction, Vector3.UP)
			character.transform = character.transform.interpolate_with(target_transform, rotation_speed * delta)

func _on_navigation_finished() -> void:
	# print("NavMeshMovement: Navigation finished!")
	stop_movement()
	movement_completed.emit()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if is_active and character:
		_apply_movement(safe_velocity, get_physics_process_delta_time())