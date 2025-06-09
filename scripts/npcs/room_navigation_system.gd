extends Node
class_name RoomNavigationSystem

# Room-based navigation system that keeps NPCs in appropriate areas
# and away from doors

# Room waypoints - positions NPCs should prefer to stay around
var room_waypoints = {
	"laboratory": [
		Vector3(-8.5, 0.1, 8.0),    # Back corner away from bench
		Vector3(-9.0, 0.1, 11.0),   # Far back corner
		Vector3(-5.0, 0.1, 11.5),   # Side area away from door
		Vector3(-8.0, 0.1, 12.0),   # Back area
		Vector3(-6.5, 0.1, 7.0),    # Front area
	],
	"medical": [
		Vector3(5.5, 0.1, 2.0),     # Front area away from table
		Vector3(9.0, 0.1, 3.0),     # Right side
		Vector3(9.0, 0.1, -3.0),    # Back right
		Vector3(5.0, 0.1, -2.0),    # Back left
	],
	"security": [
		Vector3(-9.0, 0.1, -3.0),   # Back area away from desk
		Vector3(-9.5, 0.1, -7.0),   # Far corner
		Vector3(-5.0, 0.1, -7.0),   # Side area
		Vector3(-8.0, 0.1, -2.0),   # Front area
	],
	"engineering": [
		Vector3(5.0, 0.1, -7.0),    # Front left away from console
		Vector3(9.0, 0.1, -13.0),   # Back right corner
		Vector3(5.5, 0.1, -13.0),   # Back left area
		Vector3(8.5, 0.1, -7.5),    # Front right area
	],
	"quarters": [
		Vector3(-7.0, 0.1, -15.0),  # Center of room
		Vector3(-8.0, 0.1, -16.0),  # Back area
		Vector3(-6.0, 0.1, -14.0),  # Near beds
		Vector3(-9.0, 0.1, -15.0),  # Far corner
	],
	"cafeteria": [
		Vector3(7.0, 0.1, -20.0),   # Center of room
		Vector3(8.0, 0.1, -21.0),   # Back area
		Vector3(6.0, 0.1, -19.0),   # Near tables
		Vector3(9.0, 0.1, -20.0),   # Kitchen area
	],
	"hallway": [
		Vector3(0.0, 0.1, 10.0),    # North hallway
		Vector3(0.0, 0.1, 0.0),     # Central area
		Vector3(0.0, 0.1, -10.0),   # South hallway
		Vector3(0.0, 0.1, -20.0),   # Far south
	]
}

# Room activity zones - areas where NPCs perform specific activities
var activity_zones = {
	"laboratory": {
		"workstation": Vector3(-7.0, 0.1, 9.0),
		"equipment": Vector3(-8.0, 0.1, 10.5),
		"research": Vector3(-6.0, 0.1, 8.0),
	},
	"medical": {
		"examination": Vector3(7.0, 0.1, 5.0),
		"supplies": Vector3(8.0, 0.1, 4.5),
		"desk": Vector3(6.0, 0.1, 6.0),
	},
	"security": {
		"monitors": Vector3(-7.0, 0.1, -5.0),
		"weapons": Vector3(-8.0, 0.1, -5.5),
		"desk": Vector3(-6.0, 0.1, -6.0),
	},
	"engineering": {
		"console": Vector3(7.0, 0.1, -12.0),
		"repairs": Vector3(8.0, 0.1, -11.0),
		"storage": Vector3(6.0, 0.1, -13.0),
	},
	"cafeteria": {
		"kitchen": Vector3(8.0, 0.1, -20.0),
		"tables": Vector3(6.0, 0.1, -20.5),
		"storage": Vector3(7.5, 0.1, -21.0),
	}
}

# Get next waypoint for an NPC in a room
func get_next_waypoint(room: String, current_pos: Vector3) -> Vector3:
	if not room_waypoints.has(room):
		return current_pos
	
	var waypoints = room_waypoints[room]
	if waypoints.is_empty():
		return current_pos
	
	# Pick a random waypoint that's not too close to current position
	var valid_waypoints = []
	for wp in waypoints:
		if current_pos.distance_to(wp) > 2.0:
			valid_waypoints.append(wp)
	
	if valid_waypoints.is_empty():
		# All waypoints are close, pick any
		return waypoints[randi() % waypoints.size()]
	
	return valid_waypoints[randi() % valid_waypoints.size()]

# Get activity position for specific behavior
func get_activity_position(room: String, activity: String) -> Vector3:
	if not activity_zones.has(room):
		return Vector3.ZERO
	
	var zones = activity_zones[room]
	if zones.has(activity):
		return zones[activity]
	
	# Return random activity zone if specific one not found
	var keys = zones.keys()
	if not keys.is_empty():
		return zones[keys[randi() % keys.size()]]
	
	return Vector3.ZERO

# Check if position is near a door (should be avoided)
func is_near_door(pos: Vector3) -> bool:
	# Door positions are typically at x = -3 or 3
	var x = abs(pos.x)
	return x > 2.5 and x < 3.5

# Get a safe position away from doors
func get_safe_room_position(room: String, npc_name: String = "") -> Vector3:
	if room == "hallway":
		# Hallway is special case
		return Vector3(0.0, 0.1, randf_range(-20.0, 10.0))
	
	var waypoints = room_waypoints.get(room, [])
	if waypoints.is_empty():
		return Vector3.ZERO
	
	# Try to give each NPC a unique starting position
	var index = 0
	match npc_name:
		"Dr. Emily Carter":
			index = 0
		"Dr. Marcus Webb":
			index = min(1, waypoints.size() - 1)
		"Dr. Sarah Chen":
			index = 0
		"Riley Kim":
			index = min(2, waypoints.size() - 1)
		"Jake Torres":
			index = 0
		"Dr. Zara Okafor":
			index = 0
		"Officer Marcus Johnson":
			index = 0
		_:
			index = randi() % waypoints.size()
	
	return waypoints[index]

# Schedule for NPCs - what they should be doing at different times
func get_npc_schedule(npc_name: String, time_of_day: String) -> Dictionary:
	var schedules = {
		"Dr. Sarah Chen": {
			"morning": {"location": "medical", "activity": "examination"},
			"afternoon": {"location": "medical", "activity": "desk"},
			"evening": {"location": "cafeteria", "activity": "tables"},
			"night": {"location": "quarters", "activity": "rest"}
		},
		"Dr. Marcus Webb": {
			"morning": {"location": "laboratory", "activity": "research"},
			"afternoon": {"location": "laboratory", "activity": "workstation"},
			"evening": {"location": "laboratory", "activity": "equipment"},
			"night": {"location": "quarters", "activity": "rest"}
		},
		"Riley Kim": {
			"morning": {"location": "engineering", "activity": "console"},
			"afternoon": {"location": "engineering", "activity": "repairs"},
			"evening": {"location": "cafeteria", "activity": "tables"},
			"night": {"location": "patrol", "activity": "security"}
		},
		"Jake Torres": {
			"morning": {"location": "security", "activity": "monitors"},
			"afternoon": {"location": "security", "activity": "desk"},
			"evening": {"location": "security", "activity": "monitors"},
			"night": {"location": "security", "activity": "patrol"}
		}
	}
	
	if schedules.has(npc_name) and schedules[npc_name].has(time_of_day):
		return schedules[npc_name][time_of_day]
	
	# Default schedule
	return {"location": "hallway", "activity": "wander"}