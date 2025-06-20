extends Node
class_name WaypointNetworkManager

# Dictionary to store waypoint connections
var waypoint_connections: Dictionary = {}
var waypoint_nodes: Dictionary = {}  # Name -> Node3D

# Room waypoint connections
var room_connections: Dictionary = {
	"Laboratory_Waypoint": ["Hallway_Central", "Hallway_LabMedical", "Hallway_LabSecurity"],
	"MedicalBay_Waypoint": ["Door_MedicalBayEntry"],
	"Security_Waypoint": ["Hallway_LabSecurity", "Hallway_SecurityEngineering"],
	"Engineering_Waypoint": ["Hallway_SecurityEngineering", "Hallway_EngineeringCrew", "Hallway_Central"],
	"CrewQuarters_Waypoint": ["Hallway_EngineeringCrew", "Hallway_CentralCrew"],
	"Cafeteria_Waypoint": ["Hallway_CentralCafeteria", "Hallway_Central"],
	
	# Hallway connections
	"Hallway_Central": ["Laboratory_Waypoint", "Hallway_LabMedical", "Hallway_CentralCafeteria", "Hallway_CentralCrew", "Engineering_Waypoint"],
	"Hallway_LabMedical": ["Laboratory_Waypoint", "Door_MedicalBayExit", "Hallway_Central"],
	"Door_MedicalBayExit": ["Hallway_LabMedical", "Door_MedicalBayEntry"],
	"Door_MedicalBayEntry": ["Door_MedicalBayExit", "MedicalBay_Waypoint"],
	"Hallway_LabSecurity": ["Laboratory_Waypoint", "Security_Waypoint", "Hallway_SecurityEngineering"],
	"Hallway_SecurityEngineering": ["Security_Waypoint", "Engineering_Waypoint", "Hallway_LabSecurity"],
	"Hallway_EngineeringCrew": ["Engineering_Waypoint", "CrewQuarters_Waypoint", "Hallway_CentralCrew"],
	"Hallway_CentralCrew": ["Hallway_Central", "CrewQuarters_Waypoint", "Hallway_EngineeringCrew"],
	"Hallway_CentralCafeteria": ["Hallway_Central", "Cafeteria_Waypoint"]
}

func _ready():
	add_to_group("waypoint_network_manager")
	call_deferred("_initialize_waypoints")

func _initialize_waypoints():
	# Find all waypoint nodes
	var waypoints = get_tree().get_nodes_in_group("Waypoints")
	if waypoints.is_empty():
		# Try to find waypoints by parent node
		var waypoint_parent = get_node_or_null("/root/" + get_tree().current_scene.name + "/Waypoints")
		if waypoint_parent:
			for child in waypoint_parent.get_children():
				if child is Node3D:
					waypoint_nodes[child.name] = child
	else:
		for waypoint in waypoints:
			if waypoint is Node3D:
				waypoint_nodes[waypoint.name] = waypoint
	
	print("Waypoint Network Manager initialized with ", waypoint_nodes.size(), " waypoints")

func get_path_to_room(from_position: Vector3, to_room_waypoint: String) -> Array[Vector3]:
	# Find nearest waypoint to start position
	var nearest_waypoint = _find_nearest_waypoint(from_position)
	if not nearest_waypoint:
		print("No nearest waypoint found")
		return []
	
	# If we're already at the destination
	if nearest_waypoint == to_room_waypoint:
		var target_node = waypoint_nodes.get(to_room_waypoint)
		if target_node:
			return [target_node.global_position]
		return []
	
	# Use A* pathfinding to find route through waypoints
	var path = _find_waypoint_path(nearest_waypoint, to_room_waypoint)
	if path.is_empty():
		print("No path found from ", nearest_waypoint, " to ", to_room_waypoint)
		# Fallback to direct path
		var target_node = waypoint_nodes.get(to_room_waypoint)
		if target_node:
			return [target_node.global_position]
		return []
	
	# Convert waypoint names to positions
	var position_path: Array[Vector3] = []
	for waypoint_name in path:
		var waypoint_node = waypoint_nodes.get(waypoint_name)
		if waypoint_node:
			position_path.append(waypoint_node.global_position)
	
	return position_path

func _find_nearest_waypoint(position: Vector3) -> String:
	var nearest_name: String = ""
	var nearest_distance: float = INF
	
	for waypoint_name in waypoint_nodes:
		var waypoint = waypoint_nodes[waypoint_name]
		var distance = position.distance_to(waypoint.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_name = waypoint_name
	
	return nearest_name

func _find_waypoint_path(from: String, to: String) -> Array:
	# Simple A* pathfinding through waypoint network
	var open_set = [from]
	var came_from = {}
	var g_score = {from: 0}
	var f_score = {from: _heuristic_cost(from, to)}
	
	while not open_set.is_empty():
		# Find node with lowest f_score
		var current = open_set[0]
		var lowest_f = f_score.get(current, INF)
		for node in open_set:
			var f = f_score.get(node, INF)
			if f < lowest_f:
				current = node
				lowest_f = f
		
		if current == to:
			# Reconstruct path
			var path = [current]
			while current in came_from:
				current = came_from[current]
				path.push_front(current)
			return path
		
		open_set.erase(current)
		
		# Check neighbors
		var neighbors = room_connections.get(current, [])
		for neighbor in neighbors:
			var tentative_g_score = g_score.get(current, INF) + _distance_between(current, neighbor)
			
			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic_cost(neighbor, to)
				
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	return []  # No path found

func _heuristic_cost(from: String, to: String) -> float:
	var from_node = waypoint_nodes.get(from)
	var to_node = waypoint_nodes.get(to)
	if from_node and to_node:
		return from_node.global_position.distance_to(to_node.global_position)
	return INF

func _distance_between(from: String, to: String) -> float:
	return _heuristic_cost(from, to)