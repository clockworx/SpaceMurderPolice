extends MovementInterface
class_name HybridMovement

var character: CharacterBody3D
var direct_movement: DirectMovement
var navmesh_movement: NavMeshMovement
var current_movement: MovementInterface
var is_active: bool = false
@export var rotation_speed: float = 10.0  # How fast NPCs rotate to face movement direction

# Failure tracking
var consecutive_failures: int = 0
var max_failures_before_switch: int = 2
var time_since_last_switch: float = 0.0
var min_time_between_switches: float = 3.0  # Don't switch too rapidly
var movement_start_position: Vector3 = Vector3.ZERO
var movement_target_position: Vector3 = Vector3.ZERO
var stuck_check_timer: float = 0.0
var stuck_check_interval: float = 2.0  # Check if stuck every 2 seconds
var min_progress_distance: float = 0.5  # Must move at least this far to be considered progress

# Performance tracking
var last_successful_system: String = ""
var system_performance: Dictionary = {
	"direct": {"successes": 0, "failures": 0},
	"navmesh": {"successes": 0, "failures": 0}
}

func _init(body: CharacterBody3D = null) -> void:
	if body:
		character = body

func _ready() -> void:
	if not character:
		push_error("HybridMovement: No character assigned!")
		return
	
	# Initialize both movement systems
	direct_movement = DirectMovement.new(character)
	navmesh_movement = NavMeshMovement.new(character)
	
	# Set rotation speed for both systems
	direct_movement.rotation_speed = rotation_speed
	navmesh_movement.rotation_speed = rotation_speed
	
	# Add them as children
	add_child(direct_movement)
	add_child(navmesh_movement)
	
	# Connect their signals
	direct_movement.movement_completed.connect(_on_direct_completed)
	direct_movement.movement_failed.connect(_on_direct_failed)
	navmesh_movement.movement_completed.connect(_on_navmesh_completed)
	navmesh_movement.movement_failed.connect(_on_navmesh_failed)
	
	# Start with NavMesh as it's generally more reliable
	current_movement = navmesh_movement
	print("HybridMovement: Initialized with NavMesh as primary")

func _process(delta: float) -> void:
	time_since_last_switch += delta
	
	# Check if NPC is stuck
	if is_active and current_movement and current_movement.is_moving():
		stuck_check_timer += delta
		if stuck_check_timer >= stuck_check_interval:
			stuck_check_timer = 0.0
			_check_if_stuck()

func move_to_position(position: Vector3) -> void:
	if not current_movement:
		movement_failed.emit("No movement system available")
		return
	
	is_active = true
	movement_start_position = character.global_position if character else Vector3.ZERO
	movement_target_position = position
	stuck_check_timer = 0.0
	
	current_movement.move_to_position(position)
	
	var system_name = "NavMesh" if current_movement == navmesh_movement else "Direct"
	print("HybridMovement: Moving to ", position, " using ", system_name, " movement")

func stop_movement() -> void:
	is_active = false
	if current_movement:
		current_movement.stop_movement()

func is_moving() -> bool:
	return is_active and current_movement and current_movement.is_moving()

func get_current_target() -> Vector3:
	if current_movement:
		return current_movement.get_current_target()
	return Vector3.ZERO

func get_current_system() -> String:
	if current_movement == navmesh_movement:
		return "navmesh"
	elif current_movement == direct_movement:
		return "direct"
	return "none"

func _switch_movement_system() -> void:
	if time_since_last_switch < min_time_between_switches:
		return  # Don't switch too rapidly
	
	# Stop current movement
	if current_movement:
		current_movement.stop_movement()
	
	# Switch to the other system
	if current_movement == navmesh_movement:
		current_movement = direct_movement
		print("HybridMovement: Switching to Direct movement due to failures")
	else:
		current_movement = navmesh_movement
		print("HybridMovement: Switching to NavMesh movement")
	
	consecutive_failures = 0
	time_since_last_switch = 0.0

func _check_if_stuck() -> void:
	if not character:
		return
	
	var current_pos = character.global_position
	var progress = current_pos.distance_to(movement_start_position)
	var distance_to_target = current_pos.distance_to(movement_target_position)
	
	# If we haven't made significant progress and we're not close to the target
	if progress < min_progress_distance and distance_to_target > 3.0:
		print("HybridMovement: Stuck detected! Progress: ", progress, ", Distance to target: ", distance_to_target)
		consecutive_failures += 1
		
		if consecutive_failures >= max_failures_before_switch:
			_switch_movement_system()
			# Retry with new system
			if movement_target_position != Vector3.ZERO:
				current_movement.move_to_position(movement_target_position)
		else:
			# Just emit failure but don't stop - let it keep trying
			movement_failed.emit("Stuck - no progress detected")
	else:
		# Update start position if we're making progress
		movement_start_position = current_pos

func _on_direct_completed() -> void:
	if current_movement == direct_movement:
		is_active = false
		consecutive_failures = 0
		system_performance["direct"]["successes"] += 1
		last_successful_system = "direct"
		movement_completed.emit()

func _on_direct_failed(reason: String) -> void:
	if current_movement == direct_movement:
		consecutive_failures += 1
		system_performance["direct"]["failures"] += 1
		print("HybridMovement: Direct movement failed (", consecutive_failures, "/", max_failures_before_switch, "): ", reason)
		
		if consecutive_failures >= max_failures_before_switch:
			_switch_movement_system()
			# Retry with new system if we have a target
			if current_movement and current_movement.get_current_target() != Vector3.ZERO:
				var target = current_movement.get_current_target()
				current_movement.move_to_position(target)
		else:
			is_active = false
			movement_failed.emit(reason)

func _on_navmesh_completed() -> void:
	if current_movement == navmesh_movement:
		is_active = false
		consecutive_failures = 0
		system_performance["navmesh"]["successes"] += 1
		last_successful_system = "navmesh"
		movement_completed.emit()

func _on_navmesh_failed(reason: String) -> void:
	if current_movement == navmesh_movement:
		consecutive_failures += 1
		system_performance["navmesh"]["failures"] += 1
		print("HybridMovement: NavMesh movement failed (", consecutive_failures, "/", max_failures_before_switch, "): ", reason)
		
		if consecutive_failures >= max_failures_before_switch:
			_switch_movement_system()
			# Retry with new system if we have a target
			if current_movement and current_movement.get_current_target() != Vector3.ZERO:
				var target = current_movement.get_current_target()
				current_movement.move_to_position(target)
		else:
			is_active = false
			movement_failed.emit(reason)

func get_performance_stats() -> Dictionary:
	return {
		"current_system": get_current_system(),
		"last_successful": last_successful_system,
		"stats": system_performance
	}

func force_switch_to(system: String) -> void:
	"""Manually switch to a specific movement system"""
	if system == "direct" and current_movement != direct_movement:
		current_movement = direct_movement
		consecutive_failures = 0
		time_since_last_switch = 0.0
		print("HybridMovement: Forced switch to Direct movement")
	elif system == "navmesh" and current_movement != navmesh_movement:
		current_movement = navmesh_movement
		consecutive_failures = 0
		time_since_last_switch = 0.0
		print("HybridMovement: Forced switch to NavMesh movement")