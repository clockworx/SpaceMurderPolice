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
	nav_agent.path_desired_distance = 1.0  # Standard path following
	nav_agent.target_desired_distance = 1.0  # Increased to ensure we get close enough
	nav_agent.path_max_distance = 1.0  # Standard path distance
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 0.8  # Match navigation mesh agent_radius for centered paths
	nav_agent.height = 1.75
	nav_agent.max_neighbors = 10
	nav_agent.neighbor_distance = 2.0  # Detection radius for other agents
	nav_agent.time_horizon_agents = 2.0
	nav_agent.time_horizon_obstacles = 0.5
	nav_agent.max_speed = movement_speed
	nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	nav_agent.simplify_path = true  # Remove unnecessary path points
	nav_agent.navigation_layers = 1  # Ensure we're on the right layer
	nav_agent.debug_enabled = true  # Enable debug visualization
	
	# Wait a frame for navigation to be ready
	await character.get_tree().process_frame
	
	character.add_child(nav_agent)
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	# print("NavMeshMovement: NavigationAgent3D created and connected")

func move_to_position(position: Vector3) -> void:
	if not nav_agent:
		movement_failed.emit("NavigationAgent3D not initialized")
		return
	
	print("NavMeshMovement: move_to_position called with ", position)
	
	# Check if navigation map exists
	var nav_map = nav_agent.get_navigation_map()
	if not nav_map or not nav_map.is_valid():
		print("NavMeshMovement: ERROR - No valid navigation map!")
		movement_failed.emit("No navigation map")
		return
	
	# Don't adjust Y position for NavMesh - let it handle terrain
	nav_agent.target_position = position
	is_active = true
	set_physics_process(true)
	
	# Wait a frame for navigation to update
	await character.get_tree().process_frame
	
	# Check if target is reachable
	if nav_agent.is_target_reachable():
		print("NavMeshMovement: Target is reachable")
		var path = nav_agent.get_current_navigation_path()
		print("NavMeshMovement: Path has ", path.size(), " points")
		if path.size() > 0:
			print("  First point: ", path[0])
			print("  Last point: ", path[path.size()-1])
	else:
		print("NavMeshMovement: WARNING - Target may not be reachable!")
		# Try to get closest point on navmesh
		var closest = NavigationServer3D.map_get_closest_point(nav_map, position)
		print("  Closest point on navmesh: ", closest)
		print("  Distance to target: ", position.distance_to(closest))

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
		print("NavMeshMovement: Navigation finished, distance to target: ", distance_to_target)
		if distance_to_target <= nav_agent.target_desired_distance:
			return
		else:
			print("NavMeshMovement: Still moving to final position")
	
	var next_position = nav_agent.get_next_path_position()
	var current_pos = character.global_position
	
	# Temporarily disable centering offset to diagnose navigation issues
	# next_position = _apply_centering_offset(current_pos, next_position)
	
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
	print("NavMeshMovement: Navigation finished signal received!")
	var distance_to_target = character.global_position.distance_to(nav_agent.target_position)
	print("  Distance to target: ", distance_to_target)
	print("  Character position: ", character.global_position)
	print("  Target position: ", nav_agent.target_position)
	
	if distance_to_target > 2.0:
		print("  WARNING: Navigation finished but still far from target!")
	
	stop_movement()
	movement_completed.emit()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if is_active and character:
		_apply_movement(safe_velocity, get_physics_process_delta_time())

func _apply_centering_offset(current_pos: Vector3, target_pos: Vector3) -> Vector3:
	# Simple offset system to push away from walls
	var offset_distance = 1.0  # How far to push from walls
	var space_state = character.get_world_3d().direct_space_state
	
	# Cast rays to detect nearby walls
	var offset = Vector3.ZERO
	var ray_count = 8
	
	for i in range(ray_count):
		var angle = (i / float(ray_count)) * TAU
		var direction = Vector3(cos(angle), 0, sin(angle))
		
		var from = current_pos + Vector3(0, 0.5, 0)
		var to = from + direction * 2.0  # Check 2 units away
		
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [character]
		query.collision_mask = 1  # Environment layer
		
		var result = space_state.intersect_ray(query)
		if result:
			# Wall detected, push away from it
			var distance = from.distance_to(result.position)
			if distance < 2.0:
				var push_strength = (2.0 - distance) / 2.0
				offset -= direction * push_strength * offset_distance
	
	# Apply offset to target position
	var adjusted_target = target_pos + offset * 0.3  # Apply 30% of the offset
	
	# Check for nearby navigation links and use them
	var nav_links = character.get_tree().get_nodes_in_group("navigation_links")
	for link in nav_links:
		if not (link is NavigationLink3D) or not link.enabled:
			continue
			
		var link_center = link.global_transform * ((link.start_position + link.end_position) / 2.0)
		var distance_to_link = current_pos.distance_to(link_center)
		
		# If we're approaching a navigation link, use its center
		if distance_to_link < 3.0:
			var to_link = (link_center - current_pos).normalized()
			var to_target = (target_pos - current_pos).normalized()
			
			if to_link.dot(to_target) > 0.5:  # Heading toward the link
				return link_center  # Use exact link center for doorways
	
	return adjusted_target

