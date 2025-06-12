@tool
extends NPCBase
class_name WaypointNPCFixed

# Fixed version of waypoint NPC that properly handles pausing without stuck detection

# Additional settings for fixed waypoint behavior
@export_group("Fixed Waypoint Settings")
@export var waypoint_min_movement_threshold: float = 0.05

func _ready():
    if not Engine.is_editor_hint():
        super._ready()
        last_position = global_position
        
        # Force reasonable reach distance
        if waypoint_reach_distance > 1.0:
            print("[WARNING] ", npc_name, " has reach distance ", waypoint_reach_distance, " - reducing to 0.3")
            waypoint_reach_distance = 0.3
        
        if use_waypoints and waypoint_nodes.size() > 0:
            _update_waypoint_target()
            print(npc_name + " initialized with ", waypoint_nodes.size(), " waypoint nodes, reach distance: ", waypoint_reach_distance)

func set_waypoint_nodes(value: Array[Node3D]):
    waypoint_nodes = value
    if Engine.is_editor_hint():
        notify_property_list_changed()

func _update_waypoint_target():
    if waypoint_nodes.size() == 0:
        return
        
    var current_waypoint = waypoint_nodes[current_waypoint_index]
    if is_instance_valid(current_waypoint):
        waypoint_target = current_waypoint.global_position
        # Always use NPC's Y position to avoid height issues
        waypoint_target.y = global_position.y

func _check_if_stuck(delta):
    # Don't check for stuck if we're paused at a waypoint
    if is_paused:
        stuck_timer = 0.0
        last_position = global_position
        return
        
    var movement = global_position.distance_to(last_position)
    
    if movement < min_movement_threshold:
        stuck_timer += delta
        if stuck_timer > stuck_threshold:
            print("[WARNING] " + npc_name + " stuck, advancing to next waypoint")
            _advance_waypoint()
            stuck_timer = 0.0
    else:
        stuck_timer = 0.0
    
    last_position = global_position

func _advance_waypoint():
    current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
    _update_waypoint_target()
    is_paused = false
    pause_timer = 0.0

func _physics_process(delta):
    if Engine.is_editor_hint():
        return
        
    if is_talking:
        super._physics_process(delta)
        return
    
    # Check if stuck (but not when paused)
    _check_if_stuck(delta)
    
    if use_waypoints and waypoint_nodes.size() > 0:
        _follow_waypoints(delta)
    else:
        super._physics_process(delta)

func _follow_waypoints(delta):
    # Update target position from current waypoint node
    _update_waypoint_target()
    
    # Handle pause state
    if is_paused:
        pause_timer -= delta
        
        if pause_timer <= 0:
            print(npc_name + " finished pausing, moving to next waypoint")
            _advance_waypoint()
        return
    
    # Calculate 2D distance (ignore Y completely)
    var pos_2d = Vector2(global_position.x, global_position.z)
    var target_2d = Vector2(waypoint_target.x, waypoint_target.z)
    var distance_to_target = pos_2d.distance_to(target_2d)
    
    # Check if reached waypoint
    if distance_to_target <= waypoint_reach_distance:
        var waypoint_name = waypoint_nodes[current_waypoint_index].name if is_instance_valid(waypoint_nodes[current_waypoint_index]) else "Unknown"
        print(npc_name + " reached waypoint ", current_waypoint_index, " (", waypoint_name, ") at distance: ", distance_to_target)
        
        # Reset movement tracking
        stuck_timer = 0.0
        last_position = global_position
        
        if pause_at_waypoints:
            is_paused = true
            pause_timer = randf_range(pause_duration_min, pause_duration_max)
            print(npc_name + " pausing for ", pause_timer, " seconds")
        else:
            _advance_waypoint()
        return
    
    # Move towards waypoint
    var direction_3d = (waypoint_target - global_position).normalized()
    direction_3d.y = 0  # Keep movement horizontal
    
    velocity = direction_3d * walk_speed
    velocity.y = -10  # Gravity
    
    # Handle rotation
    if direction_3d.length() > 0.1:
        _rotate_toward_direction(direction_3d, delta)
    
    move_and_slide()

func _rotate_toward_direction(direction: Vector3, delta: float):
    # Calculate target rotation
    var target_transform = transform.looking_at(global_position + direction, Vector3.UP)
    
    if smooth_rotation:
        # Smooth rotation using quaternion slerp
        var current_quat = transform.basis.get_rotation_quaternion()
        var target_quat = target_transform.basis.get_rotation_quaternion()
        
        # Interpolate rotation
        var new_quat = current_quat.slerp(target_quat, rotation_speed * delta)
        transform.basis = Basis(new_quat)
        
        # Keep upright
        rotation.x = 0
        rotation.z = 0
    else:
        # Instant rotation
        look_at(global_position + direction, Vector3.UP)
        rotation.x = 0
        rotation.z = 0

func _get_configuration_warnings():
    var warnings = []
    
    if use_waypoints and waypoint_nodes.size() == 0:
        warnings.append("No waypoint nodes assigned. Add waypoint nodes to the array.")
    
    return warnings