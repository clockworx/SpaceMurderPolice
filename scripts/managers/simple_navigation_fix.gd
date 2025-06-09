extends Node

# Simple navigation fix for NPCs to prevent getting stuck
# This manager provides basic navigation helpers

static func get_valid_hallway_position(from: Vector3) -> Vector3:
	# Hallway is roughly x: -2 to 2
	var result = from
	result.x = clamp(result.x, -1.5, 1.5)
	result.y = 0.1  # Ground level
	return result

static func get_valid_room_position(from: Vector3, room_side: int) -> Vector3:
	# Rooms are x: -7 to -3 (left) or 3 to 7 (right)
	var result = from
	if room_side < 0:  # Left side rooms
		result.x = clamp(result.x, -6.5, -3.5)
	else:  # Right side rooms
		result.x = clamp(result.x, 3.5, 6.5)
	result.y = 0.1  # Ground level
	return result

static func is_position_in_hallway(pos: Vector3) -> bool:
	return abs(pos.x) <= 2.0

static func is_position_in_room(pos: Vector3) -> bool:
	return abs(pos.x) > 3.0 and abs(pos.x) < 7.5

static func is_position_in_wall(pos: Vector3) -> bool:
	# Wall areas are roughly x: 2-3 and -3 to -2
	var x = abs(pos.x)
	return x > 2.0 and x < 3.0

static func get_nearest_valid_position(from: Vector3) -> Vector3:
	if is_position_in_wall(from):
		# Push out of wall
		if abs(from.x) < 2.5:
			# Closer to hallway
			return get_valid_hallway_position(from)
		else:
			# Closer to room
			return get_valid_room_position(from, sign(from.x))
	elif is_position_in_hallway(from):
		return get_valid_hallway_position(from)
	elif is_position_in_room(from):
		return get_valid_room_position(from, sign(from.x))
	else:
		# Unknown position, default to hallway
		return get_valid_hallway_position(from)

static func get_door_positions() -> Dictionary:
	# Approximate door positions
	return {
		"lab3_door": Vector3(-3, 0.1, 10),
		"medical_door": Vector3(3, 0.1, 5),
		"security_door": Vector3(-3, 0.1, -5),
		"engineering_door": Vector3(3, 0.1, -10),
		"quarters_door": Vector3(-3, 0.1, -15),
		"cafeteria_door": Vector3(3, 0.1, -20)
	}

static func get_nearest_door(from: Vector3) -> Vector3:
	var doors = get_door_positions()
	var nearest_pos = Vector3.ZERO
	var min_distance = 999999.0
	
	for door_name in doors:
		var door_pos = doors[door_name]
		var dist = from.distance_to(door_pos)
		if dist < min_distance:
			min_distance = dist
			nearest_pos = door_pos
	
	return nearest_pos