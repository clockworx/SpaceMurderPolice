extends Node
class_name CleanNavWithCylinders

# Clean, simple navigation with cylinder-based debug visualization

signal navigation_completed()
signal waypoint_reached(waypoint_name: String)

var character: CharacterBody3D
var current_path: Array = []
var current_index: int = 0
var is_active: bool = false

var movement_speed: float = 3.5
var reach_distance: float = 0.8  # Tighter for more precise path following
var door_reach_distance: float = 0.4  # Even tighter for precise door navigation
var lookahead_distance: float = 1.5  # Reduced lookahead for tighter path following
var path_smoothing: float = 0.15  # Lower blend factor for less deviation (0-1)

# Stuck detection
var stuck_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var stuck_threshold: float = 4.0  # Increased to prevent false positives

# Debug visualization
var debug_cylinders: Array = []
var debug_spheres: Array = []
var debug_parent: Node3D

# Door path memory - remember the exact path used through each door
var door_paths: Dictionary = {}  # Key: door_name, Value: Array of positions

func _init(body: CharacterBody3D):
    character = body
    set_physics_process(false)
    
    # Setup debug visualization
    _setup_debug_visualization()


func navigate_to_room(room_name: String) -> bool:
    print("\n[CLEAN NAV] Navigating to ", room_name)
    
    # Clear any existing navigation
    stop_navigation()
    
    # Build path based on room
    current_path.clear()
    
    # Get current position
    var start_pos = character.global_position
    print("  Starting from: ", start_pos)
    
    # Get door waypoints from the doors themselves
    var doors = get_tree().get_nodes_in_group("doors")
    var door_waypoints = {}
    
    # Check for NavigationLink3D nodes that might interfere
    var nav_links = get_tree().get_nodes_in_group("navigation_link_3d")
    if nav_links.size() > 0:
        print("  WARNING: Found ", nav_links.size(), " NavigationLink3D nodes that might interfere:")
        for link in nav_links:
            print("    - ", link.name, " at ", link.global_position)
    
    for door in doors:
        if door.has_node("EntryWaypoint") and door.has_node("ExitWaypoint"):
            var entry_node = door.get_node("EntryWaypoint")
            var exit_node = door.get_node("ExitWaypoint")
            
            # Get door name
            var door_name = ""
            if door.has_method("get_door_name"):
                door_name = door.get_door_name()
            elif "door_name" in door:
                door_name = door.door_name
            
            if door_name != "":
                # Clean door name for waypoint naming
                var clean_name = door_name.replace(" ", "")
                
                # Check which waypoint is actually in front based on global positions
                # This helps handle doors that are rotated differently
                var entry_pos = entry_node.global_position
                var exit_pos = exit_node.global_position
                
                door_waypoints["Door_" + clean_name + "Entry"] = entry_pos
                door_waypoints["Door_" + clean_name + "Exit"] = exit_pos
                print("  Found door waypoints for ", door_name, ":")
                print("    Entry: ", entry_pos)
                print("    Exit: ", exit_pos)
                print("    Distance between: ", entry_pos.distance_to(exit_pos))
    
    # Get waypoints from scene
    var waypoints_node = get_tree().get_nodes_in_group("waypoints")[0] if get_tree().has_group("waypoints") else null
    if not waypoints_node:
        # Try to find the Waypoints node directly
        var root_node = get_tree().root.get_child(0)
        waypoints_node = root_node.get_node_or_null("Waypoints")
    
    if not waypoints_node:
        print("  ERROR: No Waypoints node found in scene!")
        return false
    
    # Build paths using named waypoints
    var waypoints_dict = {}
    for child in waypoints_node.get_children():
        waypoints_dict[child.name] = child.global_position
    
    print("  Found ", waypoints_dict.size(), " waypoints in scene:")
    for wp_name in waypoints_dict:
        print("    - ", wp_name, " at ", waypoints_dict[wp_name])
    
    print("\n  Requested navigation to: ", room_name)
    
    # Build simple paths based on room
    match room_name:
        "MedicalBay_Waypoint":
            current_path = []
            
            # Exit laboratory through door if available
            var lab_door = _find_door_waypoints_by_name(door_waypoints, "Laboratory")
            if lab_door["found"]:
                current_path.append(lab_door["exit"])  # From inside lab
                current_path.append(lab_door["entry"]) # To outside lab
            
            # Navigate using waypoints
            if "Hallway_LabExit" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_LabExit"])
            if "Hallway_East" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_East"])
            if "Hallway_FarEast" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_FarEast"])
            if "Hallway_MedicalApproach" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_MedicalApproach"])
            
            # Enter medical bay through door - ALWAYS USE SAME PATH
            var med_door = _find_door_waypoints_by_name(door_waypoints, "Medical")
            if med_door["found"]:
                current_path.append(med_door["entry"])  # From hallway
                current_path.append(med_door["exit"])   # To inside room
            
            # Final destination
            if "MedicalBay_Center" in waypoints_dict:
                current_path.append(waypoints_dict["MedicalBay_Center"])
        
        "Security_Waypoint":
            current_path = []
            
            # Exit laboratory
            var lab_door = _find_door_waypoints_by_name(door_waypoints, "Laboratory")
            if lab_door["found"]:
                current_path.append(lab_door["exit"])
                current_path.append(lab_door["entry"])
            
            # Navigate using waypoints
            if "Hallway_LabExit" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_LabExit"])
            if "Hallway_Central" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_Central"])
            if "Hallway_West" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_West"])
            if "Hallway_SecurityApproach" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_SecurityApproach"])
            
            # Enter security through door
            var sec_door = _find_door_waypoints_by_name(door_waypoints, "Security")
            if sec_door["found"]:
                current_path.append(sec_door["entry"])
                current_path.append(sec_door["exit"])
            
            if "Security_Center" in waypoints_dict:
                current_path.append(waypoints_dict["Security_Center"])
        
        "Laboratory_Waypoint":
            current_path = []
            if "Laboratory_Center" in waypoints_dict:
                current_path.append(waypoints_dict["Laboratory_Center"])
        
        "Engineering_Waypoint":
            current_path = []
            
            # Exit laboratory
            var lab_door = _find_door_waypoints_by_name(door_waypoints, "Laboratory")
            if lab_door["found"]:
                current_path.append(lab_door["exit"])
                current_path.append(lab_door["entry"])
            
            # Navigate using waypoints
            if "Hallway_LabExit" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_LabExit"])
            if "Hallway_Central" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_Central"])
            if "Hallway_West" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_West"])
            if "Corner_SecurityEngineering" in waypoints_dict:
                current_path.append(waypoints_dict["Corner_SecurityEngineering"])
            
            # Engineering is shared door with security
            var eng_door = _find_door_waypoints_by_name(door_waypoints, "Security")
            if eng_door["found"]:
                current_path.append(eng_door["entry"])
                current_path.append(eng_door["exit"])
            
            if "Engineering_Center" in waypoints_dict:
                current_path.append(waypoints_dict["Engineering_Center"])
        
        "CrewQuarters_Waypoint":
            current_path = []
            
            # Exit laboratory
            var lab_door = _find_door_waypoints_by_name(door_waypoints, "Laboratory")
            if lab_door["found"]:
                current_path.append(lab_door["exit"])
                current_path.append(lab_door["entry"])
            
            # Navigate using waypoints
            if "Hallway_LabExit" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_LabExit"])
            if "Hallway_Central" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_Central"])
            if "Hallway_SouthTurn" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_SouthTurn"])
            if "Hallway_South" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_South"])
            if "Hallway_CrewTurn" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_CrewTurn"])
            if "Hallway_CrewApproach" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_CrewApproach"])
            
            # Enter crew quarters through door
            var crew_door = _find_door_waypoints_by_name(door_waypoints, "CrewQuarters")
            if crew_door["found"]:
                current_path.append(crew_door["entry"])
                current_path.append(crew_door["exit"])
            
            if "CrewQuarters_Center" in waypoints_dict:
                current_path.append(waypoints_dict["CrewQuarters_Center"])
        
        "Cafeteria_Waypoint":
            current_path = []
            
            # Exit laboratory
            var lab_door = _find_door_waypoints_by_name(door_waypoints, "Laboratory")
            if lab_door["found"]:
                current_path.append(lab_door["exit"])
                current_path.append(lab_door["entry"])
            
            # Navigate using waypoints
            if "Hallway_LabExit" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_LabExit"])
            if "Hallway_CafeteriaApproach" in waypoints_dict:
                current_path.append(waypoints_dict["Hallway_CafeteriaApproach"])
            
            # Enter cafeteria through door
            var caf_door = _find_door_waypoints_by_name(door_waypoints, "Cafeteria")
            if caf_door["found"]:
                current_path.append(caf_door["entry"])
                current_path.append(caf_door["exit"])
            
            if "Cafeteria_Center" in waypoints_dict:
                current_path.append(waypoints_dict["Cafeteria_Center"])
        
        "FullTour":
            print("\n  ===== BUILDING FULL STATION TOUR PATH =====")
            current_path = []
            
            # Build path directly with proper door transitions
            var tour_steps = []
            
            # Start in Laboratory
            tour_steps.append({"type": "waypoint", "name": "Laboratory_Center"})
            
            # Exit Laboratory
            tour_steps.append({"type": "exit_room", "room": "Laboratory"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_LabExit"})
            
            # Navigate to Medical Bay
            tour_steps.append({"type": "waypoint", "name": "Hallway_East"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_FarEast"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_MedicalApproach"})
            tour_steps.append({"type": "enter_room", "room": "Medical"})
            tour_steps.append({"type": "waypoint", "name": "MedicalBay_Center"})
            
            # Exit Medical Bay (reverse of entry)
            tour_steps.append({"type": "exit_room", "room": "Medical"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_MedicalApproach"})
            
            # Navigate to Security
            tour_steps.append({"type": "waypoint", "name": "Hallway_FarEast"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_East"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_Central"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_West"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_SecurityApproach"})
            tour_steps.append({"type": "enter_room", "room": "Security"})
            tour_steps.append({"type": "waypoint", "name": "Security_Center"})
            
            # Move to Engineering (same space)
            tour_steps.append({"type": "waypoint", "name": "Engineering_Center"})
            
            # Exit Security/Engineering
            tour_steps.append({"type": "exit_room", "room": "Security"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_West"})
            
            # Navigate to Crew Quarters
            tour_steps.append({"type": "waypoint", "name": "Hallway_Central"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_SouthTurn"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_South"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_CrewTurn"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_CrewApproach"})
            tour_steps.append({"type": "enter_room", "room": "CrewQuarters"})
            tour_steps.append({"type": "waypoint", "name": "CrewQuarters_Center"})
            
            # Exit Crew Quarters
            tour_steps.append({"type": "exit_room", "room": "CrewQuarters"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_CrewApproach"})
            
            # Navigate to Cafeteria
            tour_steps.append({"type": "waypoint", "name": "Hallway_CrewTurn"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_South"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_SouthTurn"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_Central"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_LabExit"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_CafeteriaApproach"})
            tour_steps.append({"type": "enter_room", "room": "Cafeteria"})
            tour_steps.append({"type": "waypoint", "name": "Cafeteria_Center"})
            
            # Exit Cafeteria
            tour_steps.append({"type": "exit_room", "room": "Cafeteria"})
            tour_steps.append({"type": "waypoint", "name": "Hallway_CafeteriaApproach"})
            
            # Return to Laboratory
            tour_steps.append({"type": "waypoint", "name": "Hallway_LabExit"})
            tour_steps.append({"type": "enter_room", "room": "Laboratory"})
            tour_steps.append({"type": "waypoint", "name": "Laboratory_Center"})
            
            # Build the actual path from steps
            for step in tour_steps:
                if step["type"] == "waypoint":
                    if step["name"] in waypoints_dict:
                        current_path.append(waypoints_dict[step["name"]])
                    else:
                        print("    WARNING: Waypoint '", step["name"], "' not found!")
                
                elif step["type"] == "enter_room":
                    var door = _find_door_waypoints_by_name(door_waypoints, step["room"])
                    if door["found"]:
                        print("    ENTER ", step["room"], ": entry→exit")
                        current_path.append(door["entry"])  # Hallway side
                        current_path.append(door["exit"])   # Room side
                
                elif step["type"] == "exit_room":
                    var door = _find_door_waypoints_by_name(door_waypoints, step["room"])
                    if door["found"]:
                        print("    EXIT ", step["room"], ": exit→entry")
                        current_path.append(door["exit"])   # Room side
                        current_path.append(door["entry"])  # Hallway side
            
            # Debug: Print the raw path before cleaning
            print("\n  DEBUG: Raw path before cleaning:")
            for i in range(current_path.size()):
                var wp_name = _get_waypoint_name(current_path[i])
                if wp_name != "":
                    print("    ", i, ": ", wp_name, " at ", current_path[i])
                else:
                    print("    ", i, ": Unknown at ", current_path[i])
            
            # Clean the path - remove only true duplicates
            var cleaned_path = []
            var last_pos = Vector3.INF
            
            for i in range(current_path.size()):
                var wp = current_path[i]
                
                # Skip only if it's the exact same position as the last one
                if wp.distance_to(last_pos) > 0.1:
                    cleaned_path.append(wp)
                    last_pos = wp
                else:
                    var wp_name = _get_waypoint_name(wp)
                    print("    Removed exact duplicate: ", wp_name if wp_name != "" else "Unknown")
            
            current_path = cleaned_path
            
            print("    Full tour path built with ", current_path.size(), " waypoints")
            
            # Print path summary with positions
            print("\n  ===== FULL TOUR PATH SUMMARY =====")
            var path_index = 1
            var prev_name = ""
            for wp in current_path:
                var wp_name = _get_waypoint_name(wp)
                if wp_name != "":
                    if wp_name == prev_name:
                        print("    ", path_index, ". ", wp_name, " [DUPLICATE!] at ", wp)
                    else:
                        print("    ", path_index, ". ", wp_name, " at ", wp)
                    prev_name = wp_name
                else:
                    print("    ", path_index, ". Unknown waypoint at ", wp)
                path_index += 1
            print("  ==================================")
        
        _:
            print("  Unknown destination: ", room_name)
            return false
    
    print("  Path has ", current_path.size(), " waypoints")
    
    # Start navigation
    current_index = 0
    is_active = true
    set_physics_process(true)
    
    # Create debug visualization after ensuring parent is ready
    if debug_parent and debug_parent.is_inside_tree():
        _create_debug_visualization()
    else:
        call_deferred("_create_debug_visualization")
    
    return true

func stop_navigation():
    is_active = false
    set_physics_process(false)
    character.velocity = Vector3.ZERO
    
    # Clear debug visualization
    _clear_debug_visualization()

func _physics_process(delta: float):
    if not is_active or not character:
        return
    
    # Check if we completed the path
    if current_index >= current_path.size():
        print("[CLEAN NAV] Navigation complete!")
        stop_navigation()
        navigation_completed.emit()
        return
    
    # Get current target
    var current_target = current_path[current_index]
    var distance = character.global_position.distance_to(current_target)
    
    # Check if this is a door waypoint (near specific Z coordinates of doors)
    var door_z_coords = [1.96, -0.04, 5.89, 7.9, -24.0, -26.0, 14.4, 16.4]
    var is_door_waypoint = false
    for z in door_z_coords:
        if abs(current_target.z - z) < 0.2:
            is_door_waypoint = true
            break
    
    # Use tighter tolerance for doors
    var current_reach_distance = door_reach_distance if is_door_waypoint else reach_distance
    
    # Check if reached waypoint
    if distance <= current_reach_distance:
        # Only print for key waypoints
        var waypoint_name = _get_waypoint_name(current_target)
        if waypoint_name != "":
            print("  [", current_index + 1, "/", current_path.size(), "] Reached: ", waypoint_name)
        current_index += 1
        stuck_timer = 0.0  # Reset stuck timer
        # Update debug visualization
        _update_debug_spheres()
        return
    
    # Check if stuck (not moving much)
    if character.global_position.distance_to(last_position) < 0.1:
        stuck_timer += delta
        if stuck_timer > stuck_threshold:
            print("[CLEAN NAV] Stuck detected at waypoint ", current_index + 1, "/", current_path.size())
            var waypoint_name = _get_waypoint_name(current_target)
            if waypoint_name != "":
                print("  Stuck at: ", waypoint_name)
            else:
                print("  Stuck at position: ", current_target)
            
            # If stuck at a door waypoint, skip ahead more aggressively
            if waypoint_name.contains("Entry") or waypoint_name.contains("Exit"):
                print("  Stuck at door - skipping next 2 waypoints")
                current_index = min(current_index + 2, current_path.size() - 1)
            else:
                current_index += 1
            
            stuck_timer = 0.0
            _update_debug_spheres()
            return
    else:
        stuck_timer = 0.0
    last_position = character.global_position
    
    # Debug: Print movement info occasionally for important waypoints
    if Engine.get_physics_frames() % 120 == 0:  # Every 2 seconds
        var waypoint_name = _get_waypoint_name(current_target)
        if waypoint_name != "":
            print("  → [", current_index + 1, "/", current_path.size(), "] Going to: ", waypoint_name)
    
    # Calculate smooth direction with lookahead
    var desired_direction = _calculate_smooth_direction()
    
    # Apply movement
    character.velocity = desired_direction * movement_speed
    if not character.is_on_floor():
        character.velocity.y -= 9.8 * delta
    
    character.move_and_slide()
    
    # Smooth rotation to face movement
    if desired_direction.length() > 0.1:
        var target_rotation = character.transform.looking_at(character.global_position + desired_direction, Vector3.UP)
        character.transform = character.transform.interpolate_with(target_rotation, 5.0 * delta)
        character.rotation.x = 0

func is_navigating_active() -> bool:
    return is_active

func _calculate_smooth_direction() -> Vector3:
    # Get basic direction to current waypoint
    var current_target = current_path[current_index]
    var base_direction = (current_target - character.global_position).normalized()
    base_direction.y = 0
    
    # Check if approaching a door or door waypoint
    var door_z_coords = [1.96, -0.04, 5.89, 7.9, -24.0, -26.0, 14.4, 16.4]
    var approaching_door = false
    
    # Check if current or next waypoints are door-related
    for i in range(current_index, min(current_index + 4, current_path.size())):
        var waypoint = current_path[i]
        
        # Check Z coordinates
        for z in door_z_coords:
            if abs(waypoint.z - z) < 0.5:
                approaching_door = true
                break
        
        # Also check if near known door positions (medical bay area)
        if waypoint.x > 36.0 and waypoint.x < 39.0 and waypoint.z < 4.0:
            approaching_door = true
            break
            
        if approaching_door:
            break
    
    # If approaching door, use very limited lookahead for smoother door transitions
    if approaching_door:
        # Only look 1 waypoint ahead with reduced smoothing
        if current_index < current_path.size() - 1:
            var next_waypoint = current_path[current_index + 1]
            var next_direction = (next_waypoint - character.global_position).normalized()
            next_direction.y = 0
            
            # Blend with very low weight to maintain forward momentum
            var blended = base_direction * 0.9 + next_direction * 0.1
            return blended.normalized()
        return base_direction
    
    # If last waypoint, use precise movement
    if current_index >= current_path.size() - 1:
        return base_direction
    
    # If close to current target, also use base direction
    if character.global_position.distance_to(current_target) < lookahead_distance:
        return base_direction
    
    # Check for sharp turns (corners)
    var is_sharp_turn = false
    if current_index < current_path.size() - 1:
        var next_waypoint = current_path[current_index + 1]
        var to_next = (next_waypoint - current_target).normalized()
        var angle = base_direction.angle_to(to_next)
        if abs(angle) > PI/3:  # More than 60 degrees
            is_sharp_turn = true
    
    # If sharp turn detected, use more precise movement
    if is_sharp_turn:
        return base_direction
    
    # Look ahead to next waypoints for smoother pathing
    var lookahead_direction = base_direction
    var total_weight = 1.0
    
    # Check up to 2 waypoints ahead
    for i in range(1, min(3, current_path.size() - current_index)):
        var next_waypoint = current_path[current_index + i]
        var dist_to_next = character.global_position.distance_to(next_waypoint)
        
        # Only consider waypoints within lookahead distance
        if dist_to_next <= lookahead_distance * (i + 1):
            var weight = 1.0 / (i + 1.0) * path_smoothing
            var next_direction = (next_waypoint - character.global_position).normalized()
            next_direction.y = 0
            
            lookahead_direction += next_direction * weight
            total_weight += weight
    
    # Normalize the blended direction
    lookahead_direction = lookahead_direction / total_weight
    return lookahead_direction.normalized()

func _find_door_waypoints_by_name(door_waypoints: Dictionary, door_name: String) -> Dictionary:
    # Helper to find entry/exit waypoints for a specific door
    var result = {"entry": Vector3(), "exit": Vector3(), "found": false}
    
    for key in door_waypoints:
        if key.contains(door_name):
            if key.contains("Entry"):
                result["entry"] = door_waypoints[key]
                result["found"] = true
            elif key.contains("Exit"):
                result["exit"] = door_waypoints[key]
    
    if result["found"]:
        print("    Found door waypoints for '", door_name, "':")
        print("      Entry: ", result["entry"])
        print("      Exit: ", result["exit"])
    
    return result

func _get_waypoint_name_from_dict(position: Vector3, waypoints_dict: Dictionary) -> String:
    # Find waypoint name by position
    for wp_name in waypoints_dict:
        if waypoints_dict[wp_name].distance_to(position) < 0.1:
            return wp_name
    return ""

func _get_waypoint_name(position: Vector3) -> String:
    # Try to find a meaningful name for this waypoint position
    var waypoints_node = get_tree().get_nodes_in_group("waypoints")[0] if get_tree().has_group("waypoints") else null
    if waypoints_node:
        var root_node = get_tree().root.get_child(0)
        waypoints_node = root_node.get_node_or_null("Waypoints")
        
        if waypoints_node:
            for child in waypoints_node.get_children():
                if child.global_position.distance_to(position) < 0.5:
                    return child.name
    
    # Check for door waypoints - but be more precise about position matching
    var doors = get_tree().get_nodes_in_group("doors")
    for door in doors:
        if door.has_node("EntryWaypoint"):
            var entry = door.get_node("EntryWaypoint")
            if entry.global_position.distance_to(position) < 0.1:  # Tighter tolerance
                var door_name = door.get("door_name") if door.get("door_name") else door.name
                return door_name + " Entry"
        if door.has_node("ExitWaypoint"):
            var exit = door.get_node("ExitWaypoint")
            if exit.global_position.distance_to(position) < 0.1:  # Tighter tolerance
                var door_name = door.get("door_name") if door.get("door_name") else door.name
                return door_name + " Exit"
    
    return ""

func _setup_debug_visualization():
    # Create parent node for debug visuals at scene root
    debug_parent = Node3D.new()
    debug_parent.name = "NavigationDebugCylinders"
    # Wait until we're in the scene tree
    call_deferred("_add_debug_parent")

func _add_debug_parent():
    if character.get_tree():
        character.get_tree().root.get_child(0).add_child(debug_parent)
        print("[DEBUG VIS] Parent added to scene")

func _create_debug_visualization():
    # Clear any existing
    _clear_debug_visualization()
    
    if current_path.is_empty():
        return
    
    # Create cylinders between waypoints
    for i in range(current_path.size() - 1):
        var start = current_path[i]
        var end = current_path[i + 1]
        _create_cylinder_between(start, end)
    
    # Create spheres at waypoints
    for i in range(current_path.size()):
        _create_debug_sphere(i)
    
    print("[DEBUG VIS] Created ", debug_cylinders.size(), " cylinders and ", debug_spheres.size(), " spheres")

func _create_cylinder_between(start: Vector3, end: Vector3):
    var cylinder = MeshInstance3D.new()
    var cylinder_mesh = CylinderMesh.new()
    
    # Calculate cylinder properties
    var distance = start.distance_to(end)
    var midpoint = (start + end) / 2.0
    var direction = (end - start).normalized()
    
    # Set cylinder dimensions
    cylinder_mesh.height = distance
    cylinder_mesh.top_radius = 0.05
    cylinder_mesh.bottom_radius = 0.05
    cylinder_mesh.radial_segments = 6
    
    # Create material
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(1, 0, 0, 0.8)  # Red
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.no_depth_test = true
    
    cylinder.mesh = cylinder_mesh
    cylinder.material_override = mat
    
    debug_parent.add_child(cylinder)
    
    # Set position and rotation after adding to tree
    cylinder.position = midpoint
    
    # Rotate cylinder to point from start to end
    if direction != Vector3.UP and direction != Vector3.DOWN:
        cylinder.look_at(midpoint + direction, Vector3.UP)
        cylinder.rotate_object_local(Vector3.RIGHT, PI/2)
    
    debug_cylinders.append(cylinder)

func _create_debug_sphere(index: int):
    var sphere = MeshInstance3D.new()
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 8
    sphere_mesh.rings = 4
    
    var mat = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.no_depth_test = true
    
    # Different sizes/colors for current waypoint
    if index == current_index:
        sphere_mesh.radius = 0.3
        sphere_mesh.height = 0.6
        mat.albedo_color = Color(0, 1, 0, 1)  # Green for current
    elif index < current_index:
        sphere_mesh.radius = 0.15
        sphere_mesh.height = 0.3
        mat.albedo_color = Color(0.5, 0.5, 0.5, 0.5)  # Gray for visited
    else:
        sphere_mesh.radius = 0.2
        sphere_mesh.height = 0.4
        mat.albedo_color = Color(1, 1, 0, 1)  # Yellow for future
    
    sphere.mesh = sphere_mesh
    sphere.material_override = mat
    
    debug_parent.add_child(sphere)
    # Set position after adding to tree
    sphere.position = current_path[index]
    debug_spheres.append(sphere)

func _update_debug_spheres():
    # Update sphere colors based on current progress
    for i in range(debug_spheres.size()):
        if not is_instance_valid(debug_spheres[i]):
            continue
            
        var mat = debug_spheres[i].material_override as StandardMaterial3D
        if i == current_index:
            mat.albedo_color = Color(0, 1, 0, 1)  # Green for current
        elif i < current_index:
            mat.albedo_color = Color(0.5, 0.5, 0.5, 0.5)  # Gray for visited
        else:
            mat.albedo_color = Color(1, 1, 0, 1)  # Yellow for future

func _clear_debug_visualization():
    for cylinder in debug_cylinders:
        if is_instance_valid(cylinder):
            cylinder.queue_free()
    debug_cylinders.clear()
    
    for sphere in debug_spheres:
        if is_instance_valid(sphere):
            sphere.queue_free()
    debug_spheres.clear()
