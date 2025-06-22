extends Node
class_name SimpleWaypointNav

# Simple waypoint navigation that actually works

signal navigation_completed()
signal waypoint_reached(waypoint_name: String)

var character: CharacterBody3D
var nav_agent: NavigationAgent3D

var current_path: Array = []  # Array of positions to navigate through
var current_index: int = 0
var is_active: bool = false

var movement_speed: float = 3.5
var reach_distance: float = 1.0
var door_reach_distance: float = 0.5

func _init(body: CharacterBody3D, agent: NavigationAgent3D):
	character = body
	nav_agent = agent
	set_physics_process(false)

func navigate_to_room(room_name: String) -> bool:
	print("\nSimpleWaypointNav: Navigating to ", room_name)
	
	# Clear any existing navigation
	stop_navigation()
	
	# Build path based on room
	current_path.clear()
	
	# Get current position
	var start_pos = character.global_position
	print("  Starting from: ", start_pos)
	
	# Determine current room based on position
	var current_room = _determine_current_room(start_pos)
	print("  Current room: ", current_room)
	
	# Build path based on current location and destination
	match room_name:
		"Security_Waypoint":
			if current_room == "Laboratory":
				# From lab: Lab door → Hallway → Security door → Security
				current_path = [
					Vector3(0, start_pos.y, 7.0),      # Move away from center first
					Vector3(3.67, start_pos.y, 7.9),  # Lab door center
					Vector3(3.67, start_pos.y, 5.0),  # Just outside lab door
					Vector3(0.0, start_pos.y, 5.0),   # Hallway center
					Vector3(-12.0, start_pos.y, 5.0), # Near security door
					Vector3(-12.95, start_pos.y, 5.9), # Security door center
					Vector3(-12.95, start_pos.y, 7.5), # Just inside security door
					Vector3(-12.3, start_pos.y, 8.0)  # Security office center
				]
			else:
				# Generic path to security
				current_path = [
					Vector3(0.0, start_pos.y, 5.0),   # Hallway center
					Vector3(-12.95, start_pos.y, 5.9), # Security door
					Vector3(-12.3, start_pos.y, 8.0)  # Security office
				]
		"MedicalBay_Waypoint":
			if current_room == "Laboratory":
				# From lab: Lab door → Hallway → Medical door → Medical
				current_path = [
					Vector3(0, start_pos.y, 7.0),      # Move away from center first
					Vector3(3.67, start_pos.y, 7.9),   # Lab door center
					Vector3(3.67, start_pos.y, 5.0),   # Just outside lab door
					Vector3(15.0, start_pos.y, 5.0),   # Hallway center (east)
					Vector3(38.0, start_pos.y, 2.0),   # Medical door center
					Vector3(40.2, start_pos.y, -2.3)   # Medical bay center
				]
			else:
				# Generic path to medical
				current_path = [
					Vector3(15.0, start_pos.y, 5.0),   # Hallway center
					Vector3(38.0, start_pos.y, 2.0),   # Medical door
					Vector3(40.2, start_pos.y, -2.3)   # Medical bay
				]
		"Laboratory_Waypoint":
			if current_room != "Laboratory":
				# From outside: Hallway → Lab door → Lab
				current_path = [
					Vector3(3.67, start_pos.y, 5.0),   # Outside lab door
					Vector3(3.67, start_pos.y, 7.9),   # Lab door center
					Vector3(0.0, start_pos.y, 10.0)    # Lab center
				]
			else:
				# Already in lab
				current_path = [
					Vector3(0.0, start_pos.y, 10.0)    # Lab center
				]
		"Engineering_Waypoint":
			current_path = [
				Vector3(3.67, start_pos.y, 7.9),   # Lab door (if in lab)
				Vector3(0.0, start_pos.y, 5.0),    # Hallway center
				Vector3(-20.0, start_pos.y, 5.0),  # West hallway
				Vector3(-25.0, start_pos.y, 10.0)  # Engineering (estimated)
			]
		"CrewQuarters_Waypoint":
			current_path = [
				Vector3(3.67, start_pos.y, 7.9),   # Lab door (if in lab)
				Vector3(15.0, start_pos.y, 5.0),   # East hallway
				Vector3(25.0, start_pos.y, 15.0)   # Crew quarters (estimated)
			]
		"Cafeteria_Waypoint":
			current_path = [
				Vector3(3.67, start_pos.y, 7.9),   # Lab door (if in lab)
				Vector3(15.0, start_pos.y, 5.0),   # East hallway
				Vector3(30.0, start_pos.y, -10.0)  # Cafeteria (estimated)
			]
		_:
			print("  Unknown destination: ", room_name)
			return false
	
	print("  Path has ", current_path.size(), " waypoints")
	for i in range(current_path.size()):
		print("    ", i+1, ": ", current_path[i])
	
	# Start navigation
	current_index = 0
	is_active = true
	set_physics_process(true)
	
	# Navigate to first waypoint
	_navigate_to_current_waypoint()
	return true

func stop_navigation():
	is_active = false
	set_physics_process(false)
	character.velocity = Vector3.ZERO
	if nav_agent:
		nav_agent.set_velocity(Vector3.ZERO)

func _navigate_to_current_waypoint():
	if current_index >= current_path.size():
		print("SimpleWaypointNav: Navigation complete!")
		stop_navigation()
		navigation_completed.emit()
		return
	
	var target = current_path[current_index]
	print("\nSimpleWaypointNav: Moving to waypoint ", current_index + 1, "/", current_path.size(), " at ", target)

func _physics_process(delta: float):
	if not is_active or not character:
		return
	
	# Check if we reached current waypoint
	var current_target = current_path[current_index]
	var distance = character.global_position.distance_to(current_target)
	
	# Use tighter tolerance for doors
	var tolerance = reach_distance
	# Check if this waypoint looks like a door (narrow passages)
	if current_index > 0 and current_index < current_path.size() - 1:
		var prev = current_path[current_index - 1]
		var next = current_path[current_index + 1]
		# If significant direction change, probably a door
		if abs(prev.x - next.x) > 5.0 or abs(prev.z - next.z) > 5.0:
			tolerance = door_reach_distance
	
	if distance <= tolerance:
		print("  Reached waypoint ", current_index + 1, " at distance ", distance)
		current_index += 1
		_navigate_to_current_waypoint()
		return
	
	# Always use direct movement for simple navigation
	var direction = (current_target - character.global_position).normalized()
	direction.y = 0
	
	# Apply movement
	character.velocity = direction * movement_speed
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	
	character.move_and_slide()
	
	# Rotate to face movement
	if direction.length() > 0.1:
		var look_at_pos = character.global_position + direction
		character.look_at(look_at_pos, Vector3.UP)
		character.rotation.x = 0  # Prevent tilting

func _determine_current_room(pos: Vector3) -> String:
	# Simple room detection based on position
	if pos.z > 7.0 and abs(pos.x) < 5.0:
		return "Laboratory"
	elif pos.x < -10.0:
		return "Security"
	elif pos.x > 35.0:
		return "Medical"
	else:
		return "Hallway"

func is_navigating_active() -> bool:
	return is_active