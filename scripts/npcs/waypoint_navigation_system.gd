extends Node
class_name WaypointNavigationSystem

# Waypoint-based navigation system that uses editor-placed waypoints
# instead of hardcoded positions

var room_waypoints: Dictionary = {}  # room_name -> Array of waypoints
var activity_waypoints: Dictionary = {}  # room_name -> activity_type -> Array of waypoints

func _ready():
	# Collect all waypoints in the scene
	_collect_waypoints()
	
	# If no waypoints found, use default positions
	if room_waypoints.is_empty():
		_setup_default_waypoints()

func _collect_waypoints():
	# Clear existing data
	room_waypoints.clear()
	activity_waypoints.clear()
	
	# Find all waypoints in the scene
	var waypoints = get_tree().get_nodes_in_group("waypoints")
	
	for waypoint in waypoints:
		# Skip if not a valid waypoint node
		if not is_instance_valid(waypoint):
			continue
			
		# Get properties with defaults
		var room = ""
		var activity = ""
		
		# Get properties safely
		room = waypoint.get("room_name") if waypoint.get("room_name") else ""
		activity = waypoint.get("waypoint_type") if waypoint.get("waypoint_type") else ""
		
		# Skip invalid waypoints
		if room.is_empty():
			continue
		
		# Add to room waypoints
		if not room_waypoints.has(room):
			room_waypoints[room] = []
		room_waypoints[room].append(waypoint)
		
		# Add to activity waypoints if activity is specified
		if not activity.is_empty():
			if not activity_waypoints.has(room):
				activity_waypoints[room] = {}
			if not activity_waypoints[room].has(activity):
				activity_waypoints[room][activity] = []
			activity_waypoints[room][activity].append(waypoint)
	
	print("WaypointNavigation: Collected waypoints for rooms: ", room_waypoints.keys())
	for room in room_waypoints:
		print("  ", room, ": ", room_waypoints[room].size(), " waypoints")

func _setup_default_waypoints():
	# Create virtual waypoints when none exist in scene
	print("WaypointNavigation: No waypoints found, using default positions")
	
	# Store default positions that NPCs can use
	_default_positions = {
		"laboratory": [
			Vector3(-8.0, 0.1, 10.0),
			Vector3(-10.0, 0.1, 8.0),
			Vector3(-6.0, 0.1, 11.0),
			Vector3(-7.0, 0.1, 9.0)
		],
		"medical": [
			Vector3(7.0, 0.1, 5.0),
			Vector3(9.0, 0.1, 3.0),
			Vector3(6.0, 0.1, 4.0),
			Vector3(8.0, 0.1, 6.0)
		],
		"security": [
			Vector3(-8.0, 0.1, -5.0),
			Vector3(-10.0, 0.1, -7.0),
			Vector3(-7.0, 0.1, -3.0),
			Vector3(-9.0, 0.1, -6.0)
		],
		"engineering": [
			Vector3(7.0, 0.1, -10.0),
			Vector3(9.0, 0.1, -12.0),
			Vector3(6.0, 0.1, -11.0),
			Vector3(8.0, 0.1, -9.0)
		],
		"quarters": [
			Vector3(-8.0, 0.1, -15.0),
			Vector3(-10.0, 0.1, -16.0),
			Vector3(-6.0, 0.1, -14.0),
			Vector3(-9.0, 0.1, -17.0)
		],
		"cafeteria": [
			Vector3(8.0, 0.1, -20.0),
			Vector3(9.0, 0.1, -22.0),
			Vector3(6.0, 0.1, -19.0),
			Vector3(7.0, 0.1, -21.0)
		],
		"hallway": [
			Vector3(0.0, 0.1, 10.0),
			Vector3(0.0, 0.1, 0.0),
			Vector3(0.0, 0.1, -10.0),
			Vector3(0.0, 0.1, -20.0)
		]
	}

var _default_positions: Dictionary = {}

# Get next waypoint for an NPC in a room
func get_next_waypoint(room: String, current_pos: Vector3) -> Vector3:
	# Try waypoints first
	if room_waypoints.has(room) and not room_waypoints[room].is_empty():
		var waypoints = room_waypoints[room]
		
		# Filter out waypoints that are too close
		var valid_waypoints = []
		for wp in waypoints:
			if is_instance_valid(wp) and current_pos.distance_to(wp.global_position) > 2.0:
				valid_waypoints.append(wp)
		
		if valid_waypoints.is_empty():
			# All waypoints are close, pick any
			var wp = waypoints[randi() % waypoints.size()]
			return wp.global_position if is_instance_valid(wp) else current_pos
		
		# Pick a random valid waypoint
		var chosen_wp = valid_waypoints[randi() % valid_waypoints.size()]
		return chosen_wp.global_position
	
	# Use default positions if no waypoints
	if _default_positions.has(room) and not _default_positions[room].is_empty():
		var positions = _default_positions[room]
		
		# Filter out positions that are too close
		var valid_positions = []
		for pos in positions:
			if current_pos.distance_to(pos) > 2.0:
				valid_positions.append(pos)
		
		if valid_positions.is_empty():
			# All positions are close, pick any
			return positions[randi() % positions.size()]
		
		# Pick a random valid position
		return valid_positions[randi() % valid_positions.size()]
	
	print("WaypointNavigation: No waypoints or defaults found for room: ", room)
	return current_pos

# Get activity position for specific behavior
func get_activity_position(room: String, activity: String) -> Vector3:
	if not activity_waypoints.has(room) or not activity_waypoints[room].has(activity):
		# Try generic wander if specific activity not found
		if activity_waypoints.has(room) and activity_waypoints[room].has("wander"):
			var wander_wps = activity_waypoints[room]["wander"]
			if not wander_wps.is_empty():
				var wp = wander_wps[randi() % wander_wps.size()]
				return wp.global_position if is_instance_valid(wp) else Vector3.ZERO
		return Vector3.ZERO
		
	var activity_wps = activity_waypoints[room][activity]
	if activity_wps.is_empty():
		return Vector3.ZERO
		
	# Pick a random waypoint for this activity
	var wp = activity_wps[randi() % activity_wps.size()]
	return wp.global_position if is_instance_valid(wp) else Vector3.ZERO

# Get a safe starting position in a room
func get_safe_room_position(room: String, npc_name: String = "") -> Vector3:
	if not room_waypoints.has(room) or room_waypoints[room].is_empty():
		return Vector3.ZERO
		
	var waypoints = room_waypoints[room]
	
	# Try to give each NPC a different starting position
	var index = 0
	match npc_name:
		"Dr. Emily Carter":
			index = 0
		"Dr. Marcus Webb":
			index = min(1, waypoints.size() - 1)
		"Dr. Sarah Chen":
			index = min(2, waypoints.size() - 1)
		"Riley Kim":
			index = min(3, waypoints.size() - 1)
		"Jake Torres":
			index = min(1, waypoints.size() - 1)
		"Dr. Zara Okafor":
			index = min(2, waypoints.size() - 1)
		"Officer Marcus Johnson":
			index = 0
		_:
			index = randi() % waypoints.size()
	
	var wp = waypoints[index]
	return wp.global_position if is_instance_valid(wp) else Vector3.ZERO

# Check if a position is near any waypoint
func is_near_waypoint(pos: Vector3, distance_threshold: float = 1.0) -> bool:
	var all_waypoints = get_tree().get_nodes_in_group("waypoints")
	for wp in all_waypoints:
		if is_instance_valid(wp) and pos.distance_to(wp.global_position) < distance_threshold:
			return true
	return false

# Get the closest waypoint to a position
func get_closest_waypoint(pos: Vector3, room: String = "") -> Node3D:
	var waypoints = []
	
	if not room.is_empty() and room_waypoints.has(room):
		waypoints = room_waypoints[room]
	else:
		waypoints = get_tree().get_nodes_in_group("waypoints")
	
	var closest_wp = null
	var min_distance = INF
	
	for wp in waypoints:
		if is_instance_valid(wp):
			var dist = pos.distance_to(wp.global_position)
			if dist < min_distance:
				min_distance = dist
				closest_wp = wp
	
	return closest_wp