extends StaticBody3D
class_name SlidingDoor

@export var slide_distance: float = 2.0
@export var slide_duration: float = 1.0
@export var auto_close_delay: float = 3.0
@export var door_name: String = "Door"
@export var slide_direction: Vector3 = Vector3.RIGHT  # Direction to slide in local space
@export var detection_range: float = 3.0  # Range for automatic detection
@export var requires_power: bool = true  # Whether this door needs power to auto-open

var door_mesh: MeshInstance3D
var collision_shape: CollisionShape3D
var detection_area: Area3D

var is_open: bool = false
var is_moving: bool = false
var is_powered: bool = true
var manual_mode: bool = false
var bodies_in_range: Array[Node3D] = []

var tween: Tween
var close_timer: Timer
var initial_position: Vector3
var last_auto_open_time: float = 0.0
var auto_open_cooldown: float = 2.0  # Seconds before door can auto-open again

signal door_opened
signal door_closed
signal power_status_changed(powered: bool)

func _ready():
    collision_layer = 3  # Both environment (1) and interactable (2) layers
    collision_mask = 1   # Collide with environment
    
    # Update interactability based on initial state
    _update_interactability()
    
    # Find nodes
    door_mesh = get_node_or_null("DoorMesh")
    collision_shape = get_node_or_null("CollisionShape3D")
    
    if not door_mesh:
        push_error("SlidingDoor: DoorMesh node not found!")
        return
        
    if not collision_shape:
        push_error("SlidingDoor: CollisionShape3D node not found!")
    
    # Store initial position
    initial_position = door_mesh.position
    
    # Create detection area for automatic opening
    _create_detection_area()
    
    # Create auto-close timer
    close_timer = Timer.new()
    close_timer.wait_time = auto_close_delay
    close_timer.one_shot = true
    close_timer.timeout.connect(_on_close_timer_timeout)
    add_child(close_timer)
    
    # Add to doors group for power management
    add_to_group("powered_doors")
    
    # Connect to sabotage system
    await get_tree().process_frame
    var sabotage_manager = get_tree().get_first_node_in_group("sabotage_manager")
    if sabotage_manager:
        sabotage_manager.system_status_changed.connect(_on_system_status_changed)
        print("Door ", door_name, " connected to sabotage system")
    else:
        print("Door ", door_name, " WARNING: No sabotage manager found!")
    
    # Clear any NPCs that might have spawned in detection range
    await get_tree().create_timer(0.5).timeout
    bodies_in_range.clear()
    if is_open:
        close_door()

func _create_detection_area():
    detection_area = Area3D.new()
    detection_area.name = "DetectionArea"
    detection_area.collision_layer = 0
    detection_area.collision_mask = 3  # Detect both environment (1) and interactable (2) layers
    
    var shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    # Make detection box wider in the door's slide direction for better NPC detection
    if abs(slide_direction.x) > abs(slide_direction.z):
        # Door slides horizontally
        box_shape.size = Vector3(detection_range * 1.5, 3.0, detection_range * 2.0)
    else:
        # Door slides vertically (in Z direction)
        box_shape.size = Vector3(detection_range * 2.0, 3.0, detection_range * 1.5)
    shape.shape = box_shape
    shape.position = Vector3(0, 1.5, 0)
    
    detection_area.add_child(shape)
    add_child(detection_area)
    
    # Connect signals
    detection_area.body_entered.connect(_on_body_entered)
    detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
    if body.is_in_group("player") or body.is_in_group("npcs"):
        if not body in bodies_in_range:
            bodies_in_range.append(body)
        
        # Check cooldown to prevent spam
        var current_time = Time.get_ticks_msec() / 1000.0
        if current_time - last_auto_open_time < auto_open_cooldown:
            return  # Still in cooldown
        
        # Additional check for NPCs - only open if they're actually moving towards door
        if body.is_in_group("npcs") and body is CharacterBody3D:
            if body.velocity.length() < 0.3:  # NPCs moving very slowly or standing still
                return
            # Check if NPC is moving towards the door
            var to_door = (global_position - body.global_position).normalized()
            var movement_dir = body.velocity.normalized()
            if to_door.dot(movement_dir) < 0.5:  # Not moving towards door
                return
        
        # Auto-open only if powered and not in manual mode
        if is_powered and not manual_mode and not is_open:
            # print("Door ", door_name, " auto-opening for ", body.name)
            last_auto_open_time = current_time
            open_door()
        # else:
            # print("Door ", door_name, " NOT auto-opening (powered: ", is_powered, ", manual: ", manual_mode, ")")

func _on_body_exited(body: Node3D):
    if body in bodies_in_range:
        bodies_in_range.erase(body)
        
        # Auto-close if no one nearby and powered
        if bodies_in_range.is_empty() and is_powered and not manual_mode and is_open:
            # Shorter timer for NPCs to prevent doors staying open
            close_timer.wait_time = 1.5
            close_timer.start()

func interact():
    if not door_mesh:
        push_error("Cannot interact - DoorMesh is null!")
        return
        
    if is_moving:
        return
    
    # Manual interaction always works
    if is_open:
        close_door()
    else:
        open_door()

func open_door():
    if is_open or is_moving or not door_mesh:
        return
        
    is_moving = true
    close_timer.stop()
    
    # Kill any existing tween
    if tween and tween.is_valid():
        tween.kill()
    
    # Create new tween for opening
    tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    
    var target_pos = initial_position + (slide_direction.normalized() * slide_distance)
    
    # Slower opening in manual mode
    var duration = slide_duration if is_powered else slide_duration * 1.5
    
    tween.tween_property(door_mesh, "position", target_pos, duration)
    tween.tween_callback(_on_door_opened)

func close_door():
    if not is_open or is_moving or not door_mesh:
        return
        
    is_moving = true
    close_timer.stop()
    
    # Kill any existing tween
    if tween and tween.is_valid():
        tween.kill()
    
    # Create new tween for closing
    tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    
    # Slower closing in manual mode
    var duration = slide_duration if is_powered else slide_duration * 1.5
    
    tween.tween_property(door_mesh, "position", initial_position, duration)
    tween.tween_callback(_on_door_closed)

func _on_door_opened():
    is_open = true
    is_moving = false
    if collision_shape:
        collision_shape.disabled = true
    door_opened.emit()
    
    # Update interactability
    _update_interactability()
    
    # Start auto-close timer if powered and no one nearby
    if is_powered and not manual_mode and bodies_in_range.is_empty():
        close_timer.wait_time = auto_close_delay
        close_timer.start()

func _on_door_closed():
    is_open = false
    is_moving = false
    if collision_shape:
        collision_shape.disabled = false
    door_closed.emit()
    
    # Update interactability
    _update_interactability()

func _on_close_timer_timeout():
    if bodies_in_range.is_empty():
        close_door()

func set_powered(powered: bool):
    is_powered = powered
    manual_mode = not powered
    
    # Update visual indicator if available
    _update_power_indicator()
    
    # Update interactability
    _update_interactability()
    
    # If power lost while open, keep it open but stop auto-close
    if not is_powered:
        close_timer.stop()
    
    power_status_changed.emit(is_powered)
    
    print("Door ", door_name, " power status: ", "ON" if is_powered else "OFF (Manual Mode)")

func _update_power_indicator():
    # Look for a power indicator light child node
    var indicator = get_node_or_null("PowerIndicator")
    if indicator and indicator is Light3D:
        if is_powered:
            indicator.light_color = Color(0, 1, 0)
            indicator.light_energy = 0.5
        else:
            indicator.light_color = Color(1, 0, 0)
            indicator.light_energy = 1.0

func get_interaction_prompt() -> String:
    if not is_powered or manual_mode:
        return "Press [E] to manually " + ("close" if is_open else "open") + " " + door_name
    elif is_open:
        return "Press [E] to close " + door_name
    else:
        return ""  # No prompt when closed and automatic

func _update_interactability():
    # Only be interactable if:
    # 1. Door is in manual mode (no power)
    # 2. Door is open (can be manually closed)
    if not is_powered or manual_mode or is_open:
        collision_layer = 3  # Both environment (1) and interactable (2) layers
    else:
        collision_layer = 1  # Only environment layer (physical collision)

func _on_system_status_changed(system: String, status: int):
    # Check if this affects door power
    if system == "power" and requires_power:
        # Status values from SabotageSystemManager.SystemStatus enum
        var is_normal = (status == 0)  # NORMAL = 0
        print("Door ", door_name, " received power status change: ", system, " = ", status, " (normal = ", is_normal, ")")
        set_powered(is_normal)

func get_room_name() -> String:
    # Determine which room this door belongs to based on position
    # This helps the sabotage system affect specific doors
    var pos = global_position
    
    # You'll need to adjust these based on your actual door positions
    if abs(pos.x - 7) < 5 and abs(pos.z + 10) < 10:
        return "Laboratory 3"
    elif abs(pos.x) < 5 and pos.z > 25:
        return "Engineering"
    elif abs(pos.x + 6) < 5 and abs(pos.z + 11) < 5:
        return "Crew Quarters"
    
    return ""

func force_open():
    # Emergency override - opens door regardless of power
    if not is_open:
        open_door()

func force_close():
    # Emergency override - closes door regardless of power
    if is_open:
        close_door()

func _physics_process(_delta):
    # Clean up invalid bodies and check for stationary NPCs
    if is_open and not is_moving:
        # Remove any invalid bodies
        bodies_in_range = bodies_in_range.filter(func(body): return is_instance_valid(body))
        
        # Check if all NPCs in range are stationary
        var has_moving_entity = false
        for body in bodies_in_range:
            if body.is_in_group("player"):
                has_moving_entity = true
                break
            elif body.is_in_group("npcs") and body is CharacterBody3D:
                if body.velocity.length() > 0.3:
                    has_moving_entity = true
                    break
        
        # If door is open but nobody is moving, start close timer
        if not has_moving_entity and bodies_in_range.size() > 0 and close_timer.is_stopped():
            close_timer.wait_time = 1.0  # Quick close for stationary NPCs
            close_timer.start()
        elif has_moving_entity and not close_timer.is_stopped():
            close_timer.stop()  # Keep door open if someone is moving
