extends Node
class_name WaypointNetworkManager

# Dictionary to store waypoint connections
var waypoint_connections: Dictionary = {}
var waypoint_nodes: Dictionary = {}  # Name -> Node3D

# Room waypoint connections based on actual waypoints in scene and door NavigationLink3D positions
var room_connections: Dictionary = {
    # Room centers connect to their door red waypoints (inside the room)
    "Laboratory_Center": ["Lab_Door_Red"],
    "MedicalBay_Center": ["Medical_Door_Red"],
    "Security_Center": ["Security_Door_Red"],
    "Engineering_Center": ["Engineering_Door_Red"],
    "CrewQuarters_Center": ["Crew_Door_Red"],
    # Cafeteria is a special open area - connects directly to hallway for efficient pathing
    "Cafeteria_Center": ["Cafeteria_Door_Red", "Hallway_LabTurn"],
    
    # Door waypoints - Red (inside) connects to Green (outside)
    # When LEAVING a room: Room -> Red -> Green -> Hallway
    # When ENTERING a room: Hallway -> Green -> Red -> Room
    "Lab_Door_Red": ["Laboratory_Center", "Lab_Door_Green"],
    "Lab_Door_Green": ["Lab_Door_Red", "Hallway_LabTurn"],
    "Medical_Door_Red": ["MedicalBay_Center", "Medical_Door_Green"],
    "Medical_Door_Green": ["Medical_Door_Red", "Hallway_MedicalTurn"],
    "Security_Door_Red": ["Security_Center", "Security_Door_Green"],
    "Security_Door_Green": ["Security_Door_Red", "Hallway_SecurityTurn"],
    "Engineering_Door_Red": ["Engineering_Center", "Engineering_Door_Green"],
    "Engineering_Door_Green": ["Engineering_Door_Red", "Hallway_EngineeringTurn"],
    "Crew_Door_Red": ["CrewQuarters_Center", "Crew_Door_Green"],
    "Crew_Door_Green": ["Crew_Door_Red", "Hallway_CrewApproach"],
    "Cafeteria_Door_Red": ["Cafeteria_Center", "Cafeteria_Door_Green"],
    "Cafeteria_Door_Green": ["Cafeteria_Door_Red", "Hallway_CafeteriaTurn"],
    
    # Navigation helpers and clearance waypoints
    "Nav_LabClearance": ["Hallway_LabExit"],
    "Nav_PillarAvoid": ["Hallway_Central", "Corner_LabSecurity", "Lab_Door_Green"],
    
    # Main hallway connections
    "Hallway_Central": ["Hallway_West", "Hallway_LabTurn", "Hallway_CafeteriaTurn", "Hallway_East", "Hallway_SecurityTurn"],
    "Hallway_LabTurn": ["Lab_Door_Green", "Hallway_Central", "Hallway_South", "Hallway_East", "Cafeteria_Center"],
    "Hallway_South": ["Hallway_LabTurn", "Hallway_CrewCorner", "Hallway_CrewApproach"],
    "Hallway_CrewCorner": ["Hallway_CrewApproach", "Hallway_South", "Hallway_DirectToCafe"],
    "Hallway_CrewApproach": ["Crew_Door_Green", "Hallway_CrewCorner", "Hallway_South"],
    "Hallway_DirectToCafe": ["Hallway_CrewCorner", "Hallway_CafeteriaTurn"],
    "Hallway_CafeteriaTurn": ["Cafeteria_Door_Green", "Hallway_Central", "Hallway_DirectToCafe"],
    "Hallway_MedicalTurn": ["Medical_Door_Green", "Hallway_FarEast"],
    "Hallway_East": ["Hallway_LabTurn", "Hallway_FarEast", "Hallway_Central"],
    "Hallway_FarEast": ["Hallway_East", "Hallway_MedicalTurn"],
    "Hallway_West": ["Hallway_Central", "Hallway_SecurityTurn", "Hallway_EngineeringTurn"],
    "Hallway_SecurityTurn": ["Security_Door_Green", "Hallway_West", "Hallway_Central"],
    "Hallway_EngineeringTurn": ["Engineering_Door_Green", "Hallway_West"],
}

# Remove unused waypoints that are outside station bounds

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
                    # Skip unused waypoints that cause navigation issues
                    if child.name in ["Hallway_CrewMid", "Hallway_CrewTurn", "Hallway_SouthTurn"]:
                        continue
                    waypoint_nodes[child.name] = child
    else:
        for waypoint in waypoints:
            if waypoint is Node3D:
                # Skip unused waypoints that cause navigation issues
                if waypoint.name in ["Hallway_CrewMid", "Hallway_CrewTurn", "Hallway_SouthTurn"]:
                    continue
                waypoint_nodes[waypoint.name] = waypoint
    
    # Also find room center waypoints which have special groups
    var room_groups = {
        "Laboratory_Center": "Laboratory_Waypoint",
        "MedicalBay_Center": "MedicalBay_Waypoint",  # Fixed: was "Medical_Waypoint"
        "Security_Center": "Security_Waypoint",
        "Engineering_Center": "Engineering_Waypoint",
        "CrewQuarters_Center": "CrewQuarters_Waypoint",
        "Cafeteria_Center": "Cafeteria_Waypoint"
    }
    
    for room_name in room_groups:
        var group_name = room_groups[room_name]
        var room_nodes = get_tree().get_nodes_in_group(group_name)
        if not room_nodes.is_empty():
            var room_node = room_nodes[0]
            # Skip if this is one of the problematic waypoints
            if room_node.name in ["Hallway_CrewMid", "Hallway_CrewTurn", "Hallway_SouthTurn"]:
                continue
            waypoint_nodes[room_name] = room_node
            # print("Found room center waypoint: ", room_name, " at ", room_node.global_position)
            pass
        else:
            # print("WARNING: Could not find room center waypoint for ", room_name, " in group ", group_name)
            pass
    
    # Create virtual door waypoints based on NavigationLink3D positions
    _create_door_waypoints()
    
    # Create only the necessary corner waypoints for proper pathfinding
    # Main hallway turns
    _create_corner_waypoint("Hallway_LabTurn", Vector3(5.67, 0, 4))
    _create_debug_marker(Vector3(5.67, 0, 4), Color.YELLOW, "Hallway_LabTurn")
    
    # Don't create Hallway_South - it already exists in the scene at (5.49, 0, -2.8)
    # No intermediate waypoint needed - direct path works fine
    
    # Crew quarters corner - must be west of door to prevent backtracking
    _create_corner_waypoint("Hallway_CrewCorner", Vector3(3, 0, -20))
    _create_debug_marker(Vector3(3, 0, -20), Color.YELLOW, "Hallway_CrewCorner")
    
    # Add intermediate waypoint to prevent diagonal to crew door
    _create_corner_waypoint("Hallway_CrewApproach", Vector3(5.87, 0, -20))
    _create_debug_marker(Vector3(5.87, 0, -20), Color.YELLOW, "Hallway_CrewApproach")
    
    # Direct path from crew to cafeteria
    _create_corner_waypoint("Hallway_DirectToCafe", Vector3(5.9, 0, 5))
    _create_debug_marker(Vector3(5.9, 0, 5), Color.ORANGE, "Hallway_DirectToCafe")
    
    # Cafeteria turn - approach from south, aligned with door x-coordinate
    _create_corner_waypoint("Hallway_CafeteriaTurn", Vector3(6.01923, 0, 10))
    _create_debug_marker(Vector3(6.01923, 0, 10), Color.YELLOW, "Hallway_CafeteriaTurn")
    
    # Medical Bay turn - west of door, exactly aligned with door green z-coordinate
    _create_corner_waypoint("Hallway_MedicalTurn", Vector3(30, 0, 3.96215))
    _create_debug_marker(Vector3(30, 0, 3.96215), Color.YELLOW, "Hallway_MedicalTurn")
    
    # East hallway connections
    _create_corner_waypoint("Hallway_East", Vector3(15, 0, 4))
    _create_debug_marker(Vector3(15, 0, 4), Color.CYAN, "Hallway_East")
    
    # Additional east corridor waypoint
    _create_corner_waypoint("Hallway_FarEast", Vector3(25, 0, 4))
    _create_debug_marker(Vector3(25, 0, 4), Color.CYAN, "Hallway_FarEast")
    
    # Security turn - positioned to avoid backtracking issues
    _create_corner_waypoint("Hallway_SecurityTurn", Vector3(-7, 0, 4))
    _create_debug_marker(Vector3(-7, 0, 4), Color.YELLOW, "Hallway_SecurityTurn")
    
    # Engineering turn - closer to actual door position
    _create_corner_waypoint("Hallway_EngineeringTurn", Vector3(-33.79, 0, 4))
    _create_debug_marker(Vector3(-33.79, 0, 4), Color.YELLOW, "Hallway_EngineeringTurn")
    
    # West hallway
    _create_corner_waypoint("Hallway_West", Vector3(-20, 0, 4))
    _create_debug_marker(Vector3(-20, 0, 4), Color.CYAN, "Hallway_West")
    
    # Central hallway hub
    _create_corner_waypoint("Hallway_Central", Vector3(0, 0, 4))
    _create_debug_marker(Vector3(0, 0, 4), Color.CYAN, "Hallway_Central")
    
    # Clean up any invalid waypoint references
    _validate_waypoint_connections()
    
    # Check for potential backtracking issues
    _check_for_backtracking_issues()
    
    # Validate all rooms are reachable
    _validate_room_connectivity()
    
    # Validate all waypoints are within bounds
    _validate_waypoint_bounds()
    
    print("Waypoint Network Manager initialized with ", waypoint_nodes.size(), " waypoints")
    print("Available waypoints: ", waypoint_nodes.keys())
    print("Configured connections for: ", room_connections.keys())

func get_path_to_room(from_position: Vector3, to_room_waypoint: String) -> Array[Vector3]:
    # Find nearest waypoint to start position
    var nearest_waypoint = _find_nearest_waypoint(from_position)
    if not nearest_waypoint:
        # print("No nearest waypoint found")
        return []
    
    # print("Planning path from '", nearest_waypoint, "' to '", to_room_waypoint, "'")
    
    # If we're already at the destination
    if nearest_waypoint == to_room_waypoint:
        var target_node = waypoint_nodes.get(to_room_waypoint)
        if target_node:
            var target_pos = target_node.global_position if target_node.is_inside_tree() else target_node.position
            return [target_pos]
        return []
    
    # Use A* pathfinding to find route through waypoints
    var path = _find_waypoint_path(nearest_waypoint, to_room_waypoint)
    if path.is_empty():
        # print("No path found from ", nearest_waypoint, " to ", to_room_waypoint)
        # Fallback to direct path
        var target_node = waypoint_nodes.get(to_room_waypoint)
        if target_node:
            # print("Using fallback direct path to target")
            var target_pos = target_node.global_position if target_node.is_inside_tree() else target_node.position
            return [target_pos]
        return []
    
    # Convert waypoint names to positions and fix diagonal movements
    var position_path: Array[Vector3] = []
    var previous_pos: Vector3 = from_position
    
    # Debug path for Zara
    if from_position.distance_to(Vector3(-5, 0, -28)) < 2.0:
        print("  Path waypoint names: ", path)
    
    # print("Converting path to positions with diagonal fixes:")
    for i in range(path.size()):
        var waypoint_name = path[i]
        var waypoint_node = waypoint_nodes.get(waypoint_name)
        if waypoint_node:
            var waypoint_pos = waypoint_node.global_position if waypoint_node.is_inside_tree() else waypoint_node.position
            
            # Skip processing if points are too close (less than 1 unit apart)
            if i > 0 and previous_pos.distance_to(waypoint_pos) < 1.0:
                # print("  Skipping waypoint ", waypoint_name, " - too close to previous point")
                previous_pos = waypoint_pos
                continue
                
            # Check if this would create a diagonal movement
            if i > 0 and _check_diagonal_movement(previous_pos, waypoint_pos, 3.0):
                # Skip adding intermediate if transitioning to/from door waypoints
                var prev_is_door = "Door" in path[i-1]
                var curr_is_door = "Door" in waypoint_name
                var is_room_center = waypoint_name.ends_with("_Center")
                
                # Don't add intermediate for:
                # - Transitions between door waypoints (Green to Red)
                # - Transitions from door to room center
                # - Transitions from regular waypoint to door
                if prev_is_door or curr_is_door or is_room_center:
                    # print("  Diagonal detected but skipping intermediate - door/room transition")
                    pass
                else:
                    # print("  Diagonal detected from ", previous_pos, " to ", waypoint_pos)
                    # Insert intermediate position
                    var intermediate = _get_intermediate_position(previous_pos, waypoint_pos)
                    position_path.append(intermediate)
                    # print("  Added intermediate at ", intermediate)
            
            position_path.append(waypoint_pos)
            # print("  [", i + 1, "] ", waypoint_name, " at ", waypoint_pos)
            previous_pos = waypoint_pos
        else:
            # print("WARNING: Waypoint '", waypoint_name, "' in path but not found in scene")
            pass
    
    # print("Final path has ", position_path.size(), " positions")
    return position_path

func get_waypoint_path_names(from_position: Vector3, to_room_waypoint: String) -> Array[String]:
    # Find nearest waypoint to current position
    var nearest_waypoint = _find_nearest_waypoint(from_position)
    if not nearest_waypoint:
        # print("No nearest waypoint found")
        return []
    
    if nearest_waypoint == to_room_waypoint:
        # Already at destination
        return [to_room_waypoint]
    
    # Use A* pathfinding to find route through waypoints
    var path = _find_waypoint_path(nearest_waypoint, to_room_waypoint)
    if path.is_empty():
        # print("No path found from ", nearest_waypoint, " to ", to_room_waypoint)
        # Fallback to direct path
        if waypoint_nodes.has(to_room_waypoint):
            return [to_room_waypoint]
        return []
    
    # Return the waypoint names as strings
    var string_path: Array[String] = []
    for wp_name in path:
        string_path.append(wp_name)
    return string_path

func _find_nearest_waypoint(position: Vector3) -> String:
    var nearest_name: String = ""
    var nearest_distance: float = INF
    var room_center: String = ""
    var room_center_distance: float = INF
    
    # Check all waypoints
    for waypoint_name in waypoint_nodes:
        var waypoint = waypoint_nodes[waypoint_name]
        var waypoint_pos = waypoint.global_position if waypoint.is_inside_tree() else waypoint.position
        var distance = position.distance_to(waypoint_pos)
        
        # Check if this is a room center waypoint
        if waypoint_name.ends_with("_Center"):
            # For room centers, check if we're within the room (5 units)
            if distance < 5.0 and distance < room_center_distance:
                room_center_distance = distance
                room_center = waypoint_name
        
        # Track overall nearest
        if distance < nearest_distance:
            nearest_distance = distance
            nearest_name = waypoint_name
    
    # If we're very close to a room center, we're inside that room
    if room_center != "" and room_center_distance < 5.0:
        # print("Inside room: ", room_center, " at distance: ", room_center_distance)
        return room_center
    
    # Otherwise return the nearest waypoint
    # print("Using nearest waypoint: ", nearest_name, " at distance: ", nearest_distance)
    return nearest_name

func _find_waypoint_path(from: String, to: String) -> Array:
    # print("Pathfinding from '", from, "' to '", to, "'")
    
    # Check if both waypoints exist
    if not room_connections.has(from):
        # print("  ERROR: Starting waypoint '", from, "' not found in connections")
        return []
    if not room_connections.has(to):
        # print("  ERROR: Target waypoint '", to, "' not found in connections")
        return []
    
    # Simple A* pathfinding through waypoint network
    var open_set = [from]
    var came_from = {}
    var g_score = {from: 0}
    var f_score = {from: _heuristic_cost(from, to)}
    var visited_from_direction = {}  # Track which waypoint we came from to prevent backtracking
    
    # print("  Starting A* pathfinding...")
    var iterations = 0
    
    while not open_set.is_empty() and iterations < 100:  # Safety limit
        iterations += 1
        
        # Find node with lowest f_score
        var current = open_set[0]
        var lowest_f = f_score.get(current, INF)
        for node in open_set:
            var f = f_score.get(node, INF)
            if f < lowest_f:
                current = node
                lowest_f = f
        
        # print("  Iteration ", iterations, ": Processing '", current, "'")
        
        if current == to:
            # Reconstruct path
            var path = [current]
            while current in came_from:
                current = came_from[current]
                path.push_front(current)
            # print("  SUCCESS: Found path with ", path.size(), " waypoints: ", path)
            return path
        
        open_set.erase(current)
        
        # Check neighbors
        var neighbors = room_connections.get(current, [])
        # print("    Neighbors of '", current, "': ", neighbors)
        
        for neighbor in neighbors:
            # Skip if this would create backtracking
            if current in came_from and neighbor == came_from[current]:
                continue  # Don't go back where we came from
                
            # Check if neighbor would create backtracking based on positions
            if current in came_from and _would_create_backtrack(came_from[current], current, neighbor):
                # print("    Skipping '", neighbor, "' - would create backtracking (", came_from[current], " -> ", current, " -> ", neighbor, ")")
                continue
                
            var tentative_g_score = g_score.get(current, INF) + _distance_between(current, neighbor)
            
            if tentative_g_score < g_score.get(neighbor, INF):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g_score
                f_score[neighbor] = tentative_g_score + _heuristic_cost(neighbor, to)
                
                if neighbor not in open_set:
                    open_set.append(neighbor)
                    # print("    Added '", neighbor, "' to open set")
    
    # print("  FAILED: No path found after ", iterations, " iterations")
    return []  # No path found

func _heuristic_cost(from: String, to: String) -> float:
    var from_node = waypoint_nodes.get(from)
    var to_node = waypoint_nodes.get(to)
    if from_node and to_node:
        var from_pos = from_node.global_position if from_node.is_inside_tree() else from_node.position
        var to_pos = to_node.global_position if to_node.is_inside_tree() else to_node.position
        return from_pos.distance_to(to_pos)
    return INF

func _distance_between(from: String, to: String) -> float:
    return _heuristic_cost(from, to)

func _create_corner_waypoint(name: String, position: Vector3):
    # Create a virtual waypoint for corner navigation
    # Validate position is within station bounds
    var station_bounds = {
        "min_x": -50.0,
        "max_x": 45.0,
        "min_z": -30.0,
        "max_z": 15.0
    }
    
    if position.x < station_bounds.min_x or position.x > station_bounds.max_x or \
       position.z < station_bounds.min_z or position.z > station_bounds.max_z:
        # print("WARNING: Corner waypoint '", name, "' at ", position, " is outside station bounds!")
        # Clamp to bounds
        position.x = clamp(position.x, station_bounds.min_x, station_bounds.max_x)
        position.z = clamp(position.z, station_bounds.min_z, station_bounds.max_z)
        # print("  Clamped to: ", position)
    
    var corner_node = Node3D.new()
    corner_node.name = name
    corner_node.position = position
    waypoint_nodes[name] = corner_node
    # print("Created corner waypoint '", name, "' at ", position)

func _check_diagonal_movement(from_pos: Vector3, to_pos: Vector3, threshold: float = 2.0) -> bool:
    # Check if movement would be diagonal (both X and Z change significantly)
    var delta_x = abs(to_pos.x - from_pos.x)
    var delta_z = abs(to_pos.z - from_pos.z)
    return delta_x > threshold and delta_z > threshold

func _get_intermediate_position(from_pos: Vector3, to_pos: Vector3) -> Vector3:
    # Create an L-shaped path by aligning one axis first
    # Choose to align the axis with smaller delta to minimize distance
    var delta_x = abs(to_pos.x - from_pos.x)
    var delta_z = abs(to_pos.z - from_pos.z)
    
    var intermediate: Vector3
    if delta_x < delta_z:
        # Align X first, then Z
        intermediate = Vector3(to_pos.x, from_pos.y, from_pos.z)
    else:
        # Align Z first, then X
        intermediate = Vector3(from_pos.x, from_pos.y, to_pos.z)
    
    # Ensure intermediate position stays within bounds
    var station_bounds = {
        "min_x": -50.0,
        "max_x": 45.0,
        "min_z": -30.0,
        "max_z": 15.0
    }
    
    intermediate.x = clamp(intermediate.x, station_bounds.min_x, station_bounds.max_x)
    intermediate.z = clamp(intermediate.z, station_bounds.min_z, station_bounds.max_z)
    
    return intermediate

func _would_create_backtrack(previous: String, current: String, next: String) -> bool:
    # Special cases - don't consider backtracking for:
    # 1. Door transitions (Red <-> Green)
    # 2. Room center to door transitions
    # 3. Very short distances (< 2 units)
    
    if ("Door_Red" in previous and "Door_Green" in current) or ("Door_Green" in previous and "Door_Red" in current):
        return false
    if ("Door_Red" in current and "Door_Green" in next) or ("Door_Green" in current and "Door_Red" in next):
        return false
    if ("_Center" in previous and "Door" in current) or ("Door" in current and "_Center" in next):
        return false
    
    # Check if going from current to next would backtrack past previous
    var prev_node = waypoint_nodes.get(previous)
    var curr_node = waypoint_nodes.get(current)
    var next_node = waypoint_nodes.get(next)
    
    if not prev_node or not curr_node or not next_node:
        return false
    
    var prev_pos = prev_node.position if not prev_node.is_inside_tree() else prev_node.global_position
    var curr_pos = curr_node.position if not curr_node.is_inside_tree() else curr_node.global_position
    var next_pos = next_node.position if not next_node.is_inside_tree() else next_node.global_position
    
    # Skip if waypoints are very close together
    if curr_pos.distance_to(next_pos) < 2.0:
        return false
    
    # Calculate direction vectors
    var dir_to_current = (curr_pos - prev_pos).normalized()
    var dir_to_next = (next_pos - curr_pos).normalized()
    
    # If the dot product is strongly negative, we're going backward
    var dot = dir_to_current.dot(dir_to_next)
    
    # Also check if next is closer to previous than current is (definite backtrack)
    var dist_prev_to_curr = prev_pos.distance_to(curr_pos)
    var dist_prev_to_next = prev_pos.distance_to(next_pos)
    
    # Only consider it backtracking if:
    # 1. We're going in nearly opposite direction (dot < -0.7)
    # 2. AND we're getting significantly closer to where we came from
    var is_backtrack = dot < -0.7 and (dist_prev_to_next < dist_prev_to_curr * 0.7)
    
    if is_backtrack:
        # print("      Backtrack detected: dot=", dot, " dist_ratio=", dist_prev_to_next / dist_prev_to_curr)
        pass
    
    return is_backtrack

func _create_door_waypoints():
    # Create virtual waypoint nodes for door red/green positions
    # Based on NavigationLink3D start_position (red) and end_position (green)
    # IMPORTANT: These positions are FIXED based on the door orientations in the scene
    # DO NOT change these during runtime - they match the actual NavigationLink3D positions
    
    # Define station bounds to ensure waypoints stay within mesh
    var station_bounds = {
        "min_x": -50.0,
        "max_x": 45.0,
        "min_z": -30.0,
        "max_z": 17.0  # Extended to accommodate Cafeteria interior
    }
    
    var door_definitions = {
        "Laboratory": {
            "door_transform": Transform3D(
                Vector3(0.0472109, 0, 0.998885),
                Vector3(0, 1, 0),
                Vector3(-0.998885, 0, 0.0472109),
                Vector3(3.66979, 0.182029, 7.90597)
            ),
            "red_name": "Lab_Door_Red",
            "green_name": "Lab_Door_Green"
        },
        "Medical Bay": {
            "door_transform": Transform3D(
                Vector3(-1, 0, -8.74228e-08),
                Vector3(0, 1, 0),
                Vector3(8.74228e-08, 0, -1),
                Vector3(37.8912, 0, 1.96215)
            ),
            "red_name": "Medical_Door_Red",
            "green_name": "Medical_Door_Green"
        },
        "Security Office": {
            "door_transform": Transform3D(
                Vector3(-1, 0, -8.74226e-08),
                Vector3(0, 1, 0),
                Vector3(8.74226e-08, 0, -1),
                Vector3(-13.025, 0.165187, 6.01374)
            ),
            "red_name": "Security_Door_Red",
            "green_name": "Security_Door_Green"
        },
        "Engineering": {
            "door_transform": Transform3D(
                Vector3(-4.37114e-08, 0, 1),
                Vector3(0, 1, 0),
                Vector3(-1, 0, -4.37114e-08),
                Vector3(-35.7895, 0.137131, 4.008)
            ),
            "red_name": "Engineering_Door_Red",
            "green_name": "Engineering_Door_Green"
        },
        "Crew Quarters": {
            "door_transform": Transform3D(
                Vector3(-4.37114e-08, 0, 1),
                Vector3(0, 1, 0),
                Vector3(-1, 0, -4.37114e-08),
                Vector3(3.87026, 0, -24.0289)
            ),
            "red_name": "Crew_Door_Red",
            "green_name": "Crew_Door_Green"
        },
        "Cafeteria": {
            "door_transform": Transform3D(
                Vector3(-1, 0, -8.74228e-08),
                Vector3(0, 1, 0),
                Vector3(8.74228e-08, 0, -1),
                Vector3(6.01923, 0, 14.4016)
            ),
            "red_name": "Cafeteria_Door_Red",
            "green_name": "Cafeteria_Door_Green"
        }
    }
    
    for door_name in door_definitions:
        var door_def = door_definitions[door_name]
        var door_transform = door_def.door_transform
        
        # NavigationLink3D positions: start_position = Vector3(0, 0, -2), end_position = Vector3(0, 0, 2)
        # Due to different door rotations, we need to handle each door's orientation
        var red_local_pos: Vector3   # Red waypoint (inside room)
        var green_local_pos: Vector3  # Green waypoint (outside in hallway)
        
        # Configure based on door orientation and which side faces the hallway
        match door_name:
            "Laboratory":
                # Door faces west into hallway, room is east
                green_local_pos = Vector3(0, 0, -2)  # West side (hallway)
                red_local_pos = Vector3(0, 0, 2)     # East side (inside lab)
            "Medical Bay":
                # Door faces east into hallway, room is west
                # Medical Bay door needs to be flipped - red should be north (inside), green south (hallway)
                red_local_pos = Vector3(0, 0, 2)     # North side (inside medical)
                green_local_pos = Vector3(0, 0, -2)  # South side (hallway)
            "Security Office":
                # Door is rotated 180 degrees - local Z maps to world -Z
                # Green should be south (4.01) in hallway, Red should be north (8.01) inside room
                red_local_pos = Vector3(0, 0, -2)    # Maps to north (inside security)
                green_local_pos = Vector3(0, 0, 2)   # Maps to south (hallway)
            "Engineering":
                # Door is rotated 90 degrees - local Z maps to world -X
                # Green should be west (-37.79) in hallway, Red should be east (-33.79) inside room
                green_local_pos = Vector3(0, 0, -2)  # Maps to west (hallway)
                red_local_pos = Vector3(0, 0, 2)     # Maps to east (inside engineering)
            "Crew Quarters":
                # Door is rotated 90 degrees - local Z maps to world -X
                # Room center is at (-5.39, 0, -28.52), door is at (3.87, 0, -24.03)
                # Room is WEST of door, so red should be west, green should be east
                red_local_pos = Vector3(0, 0, 2)     # Maps to west (inside room)
                green_local_pos = Vector3(0, 0, -2)  # Maps to east (hallway)
            "Cafeteria":
                # Door is rotated 180 degrees - local Z maps to world -Z
                # Green should be south (12.4) in hallway, Red should be north (16.4) inside room
                red_local_pos = Vector3(0, 0, -2)    # Maps to north (inside cafeteria)
                green_local_pos = Vector3(0, 0, 2)   # Maps to south (hallway)
            _:
                # Default fallback
                red_local_pos = Vector3(0, 0, -2)
                green_local_pos = Vector3(0, 0, 2)
        
        # Transform to world coordinates
        var red_world_pos = door_transform * red_local_pos
        var green_world_pos = door_transform * green_local_pos
        
        # Create virtual Node3D objects for these positions
        var red_node = Node3D.new()
        red_node.name = door_def.red_name
        red_node.position = red_world_pos  # Use position instead of global_position
        
        var green_node = Node3D.new()
        green_node.name = door_def.green_name
        green_node.position = green_world_pos  # Use position instead of global_position
        
        # Validate waypoints are within station bounds
        if red_world_pos.x < station_bounds.min_x or red_world_pos.x > station_bounds.max_x or \
           red_world_pos.z < station_bounds.min_z or red_world_pos.z > station_bounds.max_z:
            # print("WARNING: Red waypoint for ", door_name, " is outside station bounds: ", red_world_pos)
            pass
        
        if green_world_pos.x < station_bounds.min_x or green_world_pos.x > station_bounds.max_x or \
           green_world_pos.z < station_bounds.min_z or green_world_pos.z > station_bounds.max_z:
            # print("WARNING: Green waypoint for ", door_name, " is outside station bounds: ", green_world_pos)
            pass
        
        # Add to waypoint_nodes dictionary
        waypoint_nodes[door_def.red_name] = red_node
        waypoint_nodes[door_def.green_name] = green_node
        
        # print("Created door waypoints for ", door_name, ":")
        # print("  Red (", door_def.red_name, "): ", red_world_pos)
        # print("  Green (", door_def.green_name, "): ", green_world_pos)
        
        # Create visual debug markers for door waypoints
        _create_debug_marker(red_world_pos, Color.RED, door_def.red_name)
        _create_debug_marker(green_world_pos, Color.GREEN, door_def.green_name)

func _create_debug_marker(position: Vector3, color: Color, label: String):
    var marker = MeshInstance3D.new()
    marker.mesh = SphereMesh.new()
    marker.mesh.radius = 0.3
    marker.mesh.height = 0.6
    
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy = 2.0
    marker.material_override = material
    
    get_tree().current_scene.add_child(marker)
    marker.global_position = position
    
    # Add label
    var label_3d = Label3D.new()
    label_3d.text = label
    label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label_3d.no_depth_test = true
    label_3d.font_size = 16
    label_3d.position.y = 0.5
    marker.add_child(label_3d)

func _validate_waypoint_connections():
    # Remove any connections to waypoints that don't exist
    for waypoint_name in room_connections:
        var connections = room_connections[waypoint_name]
        var valid_connections = []
        for connection in connections:
            if waypoint_nodes.has(connection) or room_connections.has(connection):
                valid_connections.append(connection)
            else:
                # print("Removing invalid connection: ", waypoint_name, " -> ", connection)
                pass
        room_connections[waypoint_name] = valid_connections

func _check_for_backtracking_issues():
    # Check for potential backtracking in waypoint positions
    # print("Checking for potential backtracking issues...")
    
    # Check door approach waypoints
    var door_checks = [
        {"approach": "Hallway_MedicalTurn", "door": "Medical_Door_Green", "direction": "east"},
        {"approach": "Hallway_CafeteriaTurn", "door": "Cafeteria_Door_Green", "direction": "north"},
        {"approach": "Hallway_SecurityTurn", "door": "Security_Door_Green", "direction": "north"},
        {"approach": "Hallway_EngineeringTurn", "door": "Engineering_Door_Green", "direction": "east"},
        {"approach": "Hallway_CrewCorner", "door": "Crew_Door_Green", "direction": "east"}
    ]
    
    for check in door_checks:
        if waypoint_nodes.has(check.approach) and waypoint_nodes.has(check.door):
            var approach_pos = waypoint_nodes[check.approach].position
            var door_pos = waypoint_nodes[check.door].position
            
            var issue = false
            match check.direction:
                "east":
                    if approach_pos.x > door_pos.x:
                        # print("WARNING: ", check.approach, " is east of ", check.door, " - will cause backtracking")
                        issue = true
                "west":
                    if approach_pos.x < door_pos.x:
                        # print("WARNING: ", check.approach, " is west of ", check.door, " - will cause backtracking")
                        issue = true
                "north":
                    if approach_pos.z > door_pos.z:
                        # print("WARNING: ", check.approach, " is north of ", check.door, " - will cause backtracking")
                        issue = true
                "south":
                    if approach_pos.z < door_pos.z:
                        # print("WARNING: ", check.approach, " is south of ", check.door, " - will cause backtracking")
                        issue = true

func _validate_room_connectivity():
    # print("Validating room connectivity...")
    
    var rooms = [
        "Laboratory_Center",
        "MedicalBay_Center",
        "Security_Center", 
        "Engineering_Center",
        "CrewQuarters_Center",
        "Cafeteria_Center"
    ]
    
    var unreachable_pairs = []
    
    for from_room in rooms:
        for to_room in rooms:
            if from_room == to_room:
                continue
            
            # Test if path exists
            var test_pos = waypoint_nodes[from_room].position if waypoint_nodes.has(from_room) else Vector3.ZERO
            var path = _find_waypoint_path(from_room, to_room)
            
            if path.is_empty():
                unreachable_pairs.append([from_room, to_room])
                # print("  WARNING: No path from ", from_room, " to ", to_room)
    
    if unreachable_pairs.size() > 0:
        # print("  CRITICAL: Found ", unreachable_pairs.size(), " unreachable room pairs!")
        pass
    else:
        # print("  All rooms are connected!")
        pass

func _validate_waypoint_bounds():
    # print("Validating waypoint bounds...")
    
    var station_bounds = {
        "min_x": -50.0,
        "max_x": 45.0,
        "min_z": -30.0,
        "max_z": 17.0  # Extended to accommodate Cafeteria interior
    }
    
    var out_of_bounds = []
    
    for waypoint_name in waypoint_nodes:
        var waypoint = waypoint_nodes[waypoint_name]
        var pos = waypoint.position
        
        if pos.x < station_bounds.min_x or pos.x > station_bounds.max_x or \
           pos.z < station_bounds.min_z or pos.z > station_bounds.max_z:
            out_of_bounds.append({
                "name": waypoint_name,
                "position": pos,
                "issue": "Outside bounds"
            })
            # print("  WARNING: '", waypoint_name, "' at ", pos, " is outside station bounds!")
    
    if out_of_bounds.size() > 0:
        # print("  Found ", out_of_bounds.size(), " waypoints outside bounds:")
        for wp in out_of_bounds:
            # print("    - ", wp.name, " at ", wp.position)
            pass
        # print("  Station bounds: X=[", station_bounds.min_x, ", ", station_bounds.max_x, "], Z=[", station_bounds.min_z, ", ", station_bounds.max_z, "])
    else:
        # print("  All waypoints are within station bounds")
        pass
