@tool
extends NPCBase
class_name SmartWaypointNPC

# Smarter waypoint NPC that can detect when a path might go through walls

@export_group("Waypoint Settings")
@export var use_waypoints: bool = true
@export var waypoint_nodes: Array[Node3D] = []
@export var waypoint_reach_distance: float = 0.3
@export var pause_at_waypoints: bool = true
@export var pause_duration_min: float = 2.0
@export var pause_duration_max: float = 5.0
@export var check_wall_crossing: bool = true  # Enable smart wall detection

@export_group("Rotation Settings")
@export var rotation_speed: float = 5.0
@export var smooth_rotation: bool = true

var current_waypoint_index: int = 0
var waypoint_target: Vector3
var pause_timer: float = 0.0
var is_paused: bool = false

# Movement tracking
var last_position: Vector3
var stuck_timer: float = 0.0
var stuck_threshold: float = 10.0

func _ready():
    if not Engine.is_editor_hint():
        super._ready()
        last_position = global_position
        
        if use_waypoints and waypoint_nodes.size() > 0:
            _update_waypoint_target()
            print(npc_name + " initialized with ", waypoint_nodes.size(), " waypoints")

func _update_waypoint_target():
    if waypoint_nodes.size() == 0:
        return
        
    var current_waypoint = waypoint_nodes[current_waypoint_index]
    if is_instance_valid(current_waypoint):
        waypoint_target = current_waypoint.global_position
        waypoint_target.y = global_position.y  # Always ground level

func _get_next_waypoint_index() -> int:
    var next_index = (current_waypoint_index + 1) % waypoint_nodes.size()
    
    if check_wall_crossing and waypoint_nodes.size() > 2:
        # Check if direct path might cross walls (large distance usually means different rooms)
        var current_pos = global_position
        var next_pos = waypoint_nodes[next_index].global_position
        var distance = Vector2(current_pos.x, current_pos.z).distance_to(Vector2(next_pos.x, next_pos.z))
        
        # If distance is large, check if there's a door waypoint we should use
        if distance > 8.0:  # Threshold for "probably different rooms"
            # Look for a waypoint with "door" in the name
            for i in range(waypoint_nodes.size()):
                if is_instance_valid(waypoint_nodes[i]) and "door" in waypoint_nodes[i].name.to_lower():
                    # Check if this door waypoint is between current and target
                    var door_pos = waypoint_nodes[i].global_position
                    var to_door = Vector2(door_pos.x, door_pos.z).distance_to(Vector2(current_pos.x, current_pos.z))
                    var door_to_target = Vector2(door_pos.x, door_pos.z).distance_to(Vector2(next_pos.x, next_pos.z))
                    
                    # If door is closer than target and door-to-target is reasonable, go to door first
                    if to_door < distance and door_to_target < distance:
                        print(npc_name + " detected wall crossing, routing through door waypoint ", i)
                        return i
    
    return next_index

func _physics_process(delta):
    if Engine.is_editor_hint() or is_talking:
        return
    
    # Check if stuck
    if not is_paused:
        var movement = global_position.distance_to(last_position)
        if movement < 0.05:
            stuck_timer += delta
            if stuck_timer > stuck_threshold:
                print("[WARNING] " + npc_name + " stuck, advancing waypoint")
                current_waypoint_index = _get_next_waypoint_index()
                _update_waypoint_target()
                stuck_timer = 0.0
        else:
            stuck_timer = 0.0
        last_position = global_position
    
    if use_waypoints and waypoint_nodes.size() > 0:
        _follow_waypoints(delta)

func _follow_waypoints(delta):
    _update_waypoint_target()
    
    if is_paused:
        pause_timer -= delta
        if pause_timer <= 0:
            is_paused = false
            current_waypoint_index = _get_next_waypoint_index()
            _update_waypoint_target()
            print(npc_name + " continuing to waypoint ", current_waypoint_index)
        return
    
    # 2D distance check
    var pos_2d = Vector2(global_position.x, global_position.z)
    var target_2d = Vector2(waypoint_target.x, waypoint_target.z)
    var distance_to_target = pos_2d.distance_to(target_2d)
    
    if distance_to_target <= waypoint_reach_distance:
        var waypoint_name = waypoint_nodes[current_waypoint_index].name if is_instance_valid(waypoint_nodes[current_waypoint_index]) else "Unknown"
        print(npc_name + " reached waypoint ", current_waypoint_index, " (", waypoint_name, ")")
        
        stuck_timer = 0.0
        
        if pause_at_waypoints:
            is_paused = true
            pause_timer = randf_range(pause_duration_min, pause_duration_max)
        else:
            current_waypoint_index = _get_next_waypoint_index()
            _update_waypoint_target()
        return
    
    # Move towards waypoint
    var direction_2d = (target_2d - pos_2d).normalized()
    var direction = Vector3(direction_2d.x, 0, direction_2d.y)
    
    velocity = direction * walk_speed
    velocity.y = -10
    
    if direction.length() > 0.1 and smooth_rotation:
        var target_transform = transform.looking_at(global_position + direction, Vector3.UP)
        var current_quat = transform.basis.get_rotation_quaternion()
        var target_quat = target_transform.basis.get_rotation_quaternion()
        var new_quat = current_quat.slerp(target_quat, rotation_speed * delta)
        transform.basis = Basis(new_quat)
        rotation.x = 0
        rotation.z = 0
    
    move_and_slide()