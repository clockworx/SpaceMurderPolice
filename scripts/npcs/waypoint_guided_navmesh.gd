extends Node
class_name WaypointGuidedNavMesh

# This system uses waypoints as intermediate targets to guide NavMesh navigation
# ensuring NPCs follow center paths instead of hugging walls

signal navigation_completed()
signal waypoint_reached(waypoint_name: String)

var character: CharacterBody3D
var nav_agent: NavigationAgent3D
var waypoint_manager: WaypointNetworkManager

# Current navigation state
var current_path: Array[Vector3] = []  # Waypoint positions to navigate through
var current_path_names: Array[String] = []  # Waypoint names for debugging
var current_waypoint_index: int = 0
var final_destination: Vector3
var is_navigating: bool = false

# Movement settings
var movement_speed: float = 3.5
var waypoint_reach_distance: float = 2.0  # Distance to consider waypoint reached
var final_reach_distance: float = 1.0  # Distance to consider final destination reached
var rotation_speed: float = 10.0

# Debug
var debug_enabled: bool = true

func _init(body: CharacterBody3D, agent: NavigationAgent3D):
    character = body
    nav_agent = agent
    set_physics_process(false)

func _ready():
    print("WaypointGuidedNavMesh: Initializing for ", character.name if character else "Unknown")
    # Find waypoint manager
    waypoint_manager = get_tree().get_first_node_in_group("waypoint_network_manager")
    if not waypoint_manager:
        print("WaypointGuidedNavMesh: WARNING - No waypoint network manager found")
    else:
        print("WaypointGuidedNavMesh: Found waypoint network manager")

func navigate_to_room(room_waypoint_name: String) -> bool:
    print("WaypointGuidedNavMesh: navigate_to_room called with: ", room_waypoint_name)
    
    if not waypoint_manager:
        print("WaypointGuidedNavMesh: No waypoint manager available")
        return false
    
    print("WaypointGuidedNavMesh: Requesting path from ", character.global_position, " to ", room_waypoint_name)
    
    # Get waypoint path from manager (as names, not positions)
    var waypoint_names = waypoint_manager.get_waypoint_path_names(character.global_position, room_waypoint_name)
    if waypoint_names.is_empty():
        print("WaypointGuidedNavMesh: No path found to ", room_waypoint_name)
        # Debug: Check if the waypoint exists
        if waypoint_manager.waypoint_nodes.has(room_waypoint_name):
            print("  Waypoint exists in manager but no path found")
        else:
            print("  Waypoint NOT FOUND in manager. Available waypoints:")
            for wp_name in waypoint_manager.waypoint_nodes:
                print("    - ", wp_name)
        return false
    
    print("WaypointGuidedNavMesh: Path found with ", waypoint_names.size(), " waypoints: ", waypoint_names)
    
    # ALWAYS reposition to current room center first if we're against a wall
    var current_room_waypoint = _find_current_room_waypoint()
    if current_room_waypoint != "" and (waypoint_names.is_empty() or waypoint_names[0] != current_room_waypoint):
        print("WaypointGuidedNavMesh: NPC is in ", current_room_waypoint, ", repositioning to room center first")
        waypoint_names.insert(0, current_room_waypoint)
    
    # Convert waypoint names to positions and inject door centers
    current_path.clear()
    current_path_names.clear()
    
    # Build the path with proper ordering
    for i in range(waypoint_names.size()):
        var wp_name = waypoint_names[i]
        var wp_node = waypoint_manager.waypoint_nodes.get(wp_name)
        if not wp_node or not is_instance_valid(wp_node):
            print("WaypointGuidedNavMesh: WARNING - Waypoint not found: ", wp_name)
            continue
            
        # Add the waypoint
        current_path.append(wp_node.global_position)
        current_path_names.append(wp_name)
        print("  Added waypoint ", wp_name, " at ", wp_node.global_position)
        
        # After each waypoint (except the last), check if we need a door
        if i < waypoint_names.size() - 1:
            var next_wp_name = waypoint_names[i + 1]
            var next_wp_node = waypoint_manager.waypoint_nodes.get(next_wp_name)
            if not next_wp_node or not is_instance_valid(next_wp_node):
                continue
                
            # Special case: Laboratory to outside always uses the lab door
            if wp_name == "Laboratory_Waypoint" and not next_wp_name.contains("Laboratory"):
                # Force use of laboratory door at approximately (3.67, 0.18, 7.9)
                var lab_door_center = Vector3(3.67, character.global_position.y, 7.9)
                current_path.append(lab_door_center)
                current_path_names.append("LabDoorCenter")
                if debug_enabled:
                    print("  Injected LABORATORY door center at: ", lab_door_center)
            else:
                var door_center = _find_door_center_between(wp_node.global_position, next_wp_node.global_position)
                if door_center != Vector3.ZERO:
                    current_path.append(door_center)
                    current_path_names.append("DoorCenter")
                    if debug_enabled:
                        print("  Injected door center at: ", door_center)
    
    if current_path.is_empty():
        return false
    
    # Set final destination
    final_destination = current_path[-1]
    current_waypoint_index = 0
    is_navigating = true
    
    if debug_enabled:
        print("\nWaypointGuidedNavMesh: === STARTING NAVIGATION ===")
        print("  Destination: ", room_waypoint_name)
        print("  Path order: ", current_path_names)
        print("  Total waypoints: ", current_path.size())
        print("  Path details:")
        for i in range(current_path.size()):
            var name = current_path_names[i] if i < current_path_names.size() else "Unknown"
            print("    ", i+1, ". ", name, " at ", current_path[i])
    
    # Start navigation to first waypoint
    _navigate_to_next_waypoint()
    set_physics_process(true)
    return true

func navigate_to_position(position: Vector3) -> bool:
    # Direct navigation without waypoints
    final_destination = position
    current_path.clear()
    current_path_names.clear()
    current_waypoint_index = 0
    is_navigating = true
    
    # Set NavMesh target directly
    nav_agent.target_position = position
    set_physics_process(true)
    return true

func stop_navigation():
    is_navigating = false
    set_physics_process(false)
    character.velocity = Vector3.ZERO
    current_path.clear()
    current_path_names.clear()

func _navigate_to_next_waypoint():
    if current_waypoint_index >= current_path.size():
        # Reached all waypoints
        if debug_enabled:
            print("WaypointGuidedNavMesh: All waypoints reached")
        _complete_navigation()
        return
    
    var target_pos = current_path[current_waypoint_index]
    var waypoint_name = current_path_names[current_waypoint_index] if current_waypoint_index < current_path_names.size() else "Unknown"
    
    if debug_enabled:
        print("\nWaypointGuidedNavMesh: === NAVIGATING TO WAYPOINT ", current_waypoint_index + 1, "/", current_path.size(), " ===")
        print("  Waypoint: ", waypoint_name)
        print("  Position: ", target_pos)
        print("  Current NPC position: ", character.global_position)
        print("  Distance: ", character.global_position.distance_to(target_pos))
    
    # Set NavMesh to navigate to this waypoint
    nav_agent.target_position = target_pos
    
    # Special handling for first waypoint if it's a room center
    if current_waypoint_index == 0 and waypoint_name.ends_with("_Waypoint"):
        print("WaypointGuidedNavMesh: First moving to room center to avoid wall-hugging")

func _physics_process(delta: float):
    if not is_navigating or not character or not nav_agent:
        return
    
    # Check if we're using waypoint path or direct navigation
    if current_path.size() > 0:
        _process_waypoint_navigation(delta)
    else:
        _process_direct_navigation(delta)

func _process_waypoint_navigation(delta: float):
    var current_target = current_path[current_waypoint_index]
    var distance_to_waypoint = character.global_position.distance_to(current_target)
    
    # Use tighter tolerance for door centers
    var reach_distance = waypoint_reach_distance
    if current_waypoint_index < current_path_names.size():
        var wp_name = current_path_names[current_waypoint_index]
        if wp_name == "DoorCenter" or wp_name == "LabDoorCenter":
            reach_distance = 0.5  # Much tighter for doors to ensure we go through center
            if debug_enabled:
                print("  Using tight tolerance (0.5) for door center")
    
    # Check if we reached current waypoint
    if distance_to_waypoint <= reach_distance:
        if debug_enabled:
            var wp_name = current_path_names[current_waypoint_index] if current_waypoint_index < current_path_names.size() else "Unknown"
            print("WaypointGuidedNavMesh: Reached waypoint ", wp_name)
        
        waypoint_reached.emit(current_path_names[current_waypoint_index] if current_waypoint_index < current_path_names.size() else "")
        
        # Move to next waypoint
        current_waypoint_index += 1
        _navigate_to_next_waypoint()
        return
    
    # Continue navigation using NavMesh
    _move_with_navmesh(delta)

func _process_direct_navigation(delta: float):
    var distance_to_target = character.global_position.distance_to(final_destination)
    
    if distance_to_target <= final_reach_distance or nav_agent.is_navigation_finished():
        _complete_navigation()
        return
    
    _move_with_navmesh(delta)

func _move_with_navmesh(delta: float):
    if nav_agent.is_navigation_finished():
        return
    
    var next_position = nav_agent.get_next_path_position()
    var direction = (next_position - character.global_position).normalized()
    direction.y = 0  # Keep movement horizontal
    
    # Set velocity
    var desired_velocity = direction * movement_speed
    
    if nav_agent.avoidance_enabled:
        nav_agent.velocity = desired_velocity
    else:
        character.velocity.x = desired_velocity.x
        character.velocity.z = desired_velocity.z
        
        # Apply gravity
        if not character.is_on_floor():
            character.velocity.y -= 9.8 * delta
        else:
            character.velocity.y = 0
        
        character.move_and_slide()
        
        # Rotate to face movement direction
        if direction.length() > 0.1:
            var target_transform = character.transform.looking_at(character.global_position + direction, Vector3.UP)
            character.transform = character.transform.interpolate_with(target_transform, rotation_speed * delta)

func _complete_navigation():
    if debug_enabled:
        print("WaypointGuidedNavMesh: Navigation completed")
    
    stop_navigation()
    navigation_completed.emit()

func is_navigating_active() -> bool:
    return is_navigating

func get_current_target() -> Vector3:
    if current_path.size() > 0 and current_waypoint_index < current_path.size():
        return current_path[current_waypoint_index]
    return final_destination

func _find_door_center_between(from: Vector3, to: Vector3) -> Vector3:
    # Find navigation links between two positions
    var nav_links = get_tree().get_nodes_in_group("navigation_links")
    var best_door_center = Vector3.ZERO
    var best_distance = INF
    
    for link in nav_links:
        if not (link is NavigationLink3D) or not link.enabled:
            continue
        
        # Get the center of the navigation link in global space
        var link_start = link.global_transform * link.start_position
        var link_end = link.global_transform * link.end_position
        var link_center = (link_start + link_end) / 2.0
        
        # Check if this link is between our two positions
        var dist_from_start = link_center.distance_to(from)
        var dist_to_end = link_center.distance_to(to)
        var total_dist = dist_from_start + dist_to_end
        var direct_dist = from.distance_to(to)
        
        # If the link is roughly on the path between the two waypoints
        # Use a more generous threshold for laboratory door (it's at approx y=7.9)
        var threshold = 1.5
        if from.z > 9.0 or to.z > 9.0:  # One endpoint is in laboratory
            threshold = 2.0
        
        if total_dist < direct_dist * threshold and total_dist < best_distance:
            best_distance = total_dist
            best_door_center = link_center
            if debug_enabled:
                print("  Found potential door at ", link_center, " (distance: ", total_dist, ")")
    
    if best_door_center != Vector3.ZERO and debug_enabled:
        print("  Selected door center at: ", best_door_center)
    
    return best_door_center

func _find_current_room_waypoint() -> String:
    # Find which room the NPC is currently in based on proximity to room waypoints
    var closest_room = ""
    var closest_distance = 20.0  # Maximum room size threshold
    
    for wp_name in waypoint_manager.waypoint_nodes:
        if not wp_name.ends_with("_Waypoint"):
            continue  # Skip non-room waypoints
            
        var wp_node = waypoint_manager.waypoint_nodes[wp_name]
        if wp_node and is_instance_valid(wp_node):
            var distance = character.global_position.distance_to(wp_node.global_position)
            if distance < closest_distance:
                closest_distance = distance
                closest_room = wp_name
    
    if closest_room != "":
        print("WaypointGuidedNavMesh: NPC is in room: ", closest_room, " (distance: ", closest_distance, ")")
    
    return closest_room
