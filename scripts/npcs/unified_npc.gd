@tool
extends CharacterBody3D
class_name UnifiedNPC

# Unified NPC that combines all features into one reusable class

# Movement states
enum MovementState {
    PATROL,  # Move between waypoints
    IDLE,    # Stop at current position
    TALK,    # Face toward a target position
    WANDER,  # Random movement within radius (no waypoints)
    INVESTIGATE,  # Stop and look around when player detected
    RETURN_TO_PATROL  # Go back to waypoint route after investigation
}

@export_group("NPC Properties")
@export var npc_name: String = "Unknown"
@export var role: String = "Crew Member"
@export var initial_dialogue_id: String = "greeting"
@export var is_suspicious: bool = false
@export var has_alibi: bool = true
@export var can_be_saboteur: bool = false

@export_group("Saboteur Mode")
@export var enable_saboteur_behavior: bool = false
@export var detection_range: float = 10.0
@export var vision_angle: float = 60.0
@export var investigation_duration: float = 3.0
@export var return_to_patrol_speed: float = 3.0

@export_group("Movement System")
@export var use_navmesh: bool = false

@export_group("Movement")
@export var walk_speed: float = 2.0
@export var rotation_speed: float = 5.0
@export var smooth_rotation: bool = true
@export var current_state: MovementState = MovementState.PATROL

@export_group("Waypoint System")
@export var use_waypoints: bool = true
@export var waypoint_nodes: Array[Node3D] = []
@export var waypoint_reach_distance: float = 0.3
@export var pause_at_waypoints: bool = true
@export var pause_duration_min: float = 2.0
@export var pause_duration_max: float = 5.0

@export_group("Wander System")
@export var wander_radius: float = 5.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0

@export_group("Interaction")
@export var interaction_distance: float = 3.0
@export var face_player_when_talking: bool = true
@export var react_to_player_proximity: bool = false
@export var idle_trigger_distance: float = 5.0
@export var talk_trigger_distance: float = 2.0

@export_group("Visual")
@export var show_face_indicator: bool = true
@export var face_indicator_color: Color = Color.YELLOW
@export var face_indicator_size: float = 0.2
@export_enum("Cone", "Eyes", "Nose", "Arrow") var face_indicator_type: String = "Cone"
@export var show_state_label: bool = true
@export var debug_state_changes: bool = false

# State management
var previous_state: MovementState = MovementState.PATROL
var talk_target_position: Vector3
var state_label: Label3D
var face_indicator_mesh: MeshInstance3D

# Waypoint navigation
var current_waypoint_index: int = 0
var waypoint_target: Vector3
var pause_timer: float = 0.0
var is_paused: bool = false

# Wander behavior
var initial_position: Vector3
var current_target: Vector3
var idle_timer: float = 0.0
var is_idle: bool = true

# Dialogue system
var dialogue_state: Dictionary = {}
var has_been_interviewed: bool = false
var current_dialogue: String = ""
var is_talking: bool = false
var player_nearby: bool = false

# Movement tracking
var last_position: Vector3
var stuck_timer: float = 0.0
var stuck_threshold: float = 10.0

# Detection system
var player_detected: bool = false
var investigation_timer: float = 0.0
var investigation_position: Vector3
var last_patrol_waypoint_index: int = 0
var returning_to_patrol: bool = false

# Movement system
var movement_system: MovementInterface

# Signals
signal dialogue_started(npc)
signal dialogue_ended(npc)
signal suspicion_changed(npc, is_suspicious)
signal state_changed(old_state, new_state)

func _ready():
    if Engine.is_editor_hint():
        return
        
    # Setup collision
    collision_layer = 2  # Interactable layer
    collision_mask = 1   # Collide with environment
    
    # Initialize movement system
    if use_navmesh:
        movement_system = NavMeshMovement.new(self)
    else:
        movement_system = DirectMovement.new(self)
    
    add_child(movement_system)
    movement_system.movement_completed.connect(_on_movement_completed)
    movement_system.movement_failed.connect(_on_movement_failed)
    
    # Add to groups
    add_to_group("npcs")
    add_to_group("interactable")
    
    # Initialize position tracking
    initial_position = global_position
    current_target = global_position
    last_position = global_position
    
    # Setup visuals
    _create_face_indicator()
    _create_state_label()
    _setup_name_labels()
    
    # Initialize movement
    if use_waypoints and waypoint_nodes.size() > 0:
        _update_waypoint_target()
        print(npc_name + " initialized with ", waypoint_nodes.size(), " waypoints")
    else:
        print(npc_name + " initialized at position: ", global_position)

func _physics_process(delta):
    if Engine.is_editor_hint() or is_talking:
        return
    
    # Check for player detection if saboteur behavior is enabled
    if enable_saboteur_behavior and can_be_saboteur and current_state == MovementState.PATROL:
        _check_for_player_detection()
    
    # Handle movement based on state
    match current_state:
        MovementState.PATROL:
            _handle_patrol_state(delta)
        MovementState.IDLE:
            _handle_idle_state(delta)
        MovementState.TALK:
            _handle_talk_state(delta)
        MovementState.WANDER:
            _handle_wander_state(delta)
        MovementState.INVESTIGATE:
            _handle_investigate_state(delta)
        MovementState.RETURN_TO_PATROL:
            _handle_return_to_patrol_state(delta)

# State management
func set_state(new_state: MovementState, target_position: Vector3 = Vector3.ZERO):
    if current_state == new_state:
        return
    
    var old_state = current_state
    
    # Store previous state for resuming
    if current_state != MovementState.IDLE and current_state != MovementState.TALK:
        previous_state = current_state
    
    current_state = new_state
    
    if debug_state_changes:
        print(npc_name + " state: ", MovementState.keys()[old_state], " -> ", MovementState.keys()[new_state])
    
    # Handle state-specific setup
    match new_state:
        MovementState.PATROL:
            pass
        MovementState.IDLE:
            velocity = Vector3.ZERO
        MovementState.TALK:
            talk_target_position = target_position
            velocity = Vector3.ZERO
        MovementState.WANDER:
            _choose_new_target()
        MovementState.INVESTIGATE:
            investigation_position = target_position
            investigation_timer = 0.0
            velocity = Vector3.ZERO
            # Remember current waypoint
            if use_waypoints:
                last_patrol_waypoint_index = current_waypoint_index
        MovementState.RETURN_TO_PATROL:
            returning_to_patrol = true
    
    _update_state_label()
    emit_signal("state_changed", old_state, new_state)

func set_patrol_state():
    set_state(MovementState.PATROL)

func set_idle_state():
    set_state(MovementState.IDLE)

func set_talk_state(target_position: Vector3):
    set_state(MovementState.TALK, target_position)

func set_wander_state():
    set_state(MovementState.WANDER)

func resume_previous_state():
    set_state(previous_state)

# State handlers
func _handle_patrol_state(delta):
    if react_to_player_proximity:
        _check_player_proximity()
    
    if use_waypoints and waypoint_nodes.size() > 0:
        _follow_waypoints(delta)
    else:
        # No waypoints, switch to wander
        set_wander_state()

func _handle_idle_state(delta):
    if react_to_player_proximity:
        _check_player_proximity_idle()
    
    stop_movement()
    
    velocity.y = -10
    move_and_slide()

func _handle_talk_state(delta):
    if react_to_player_proximity and not is_talking:
        _check_player_proximity_talk()
    
    # Face target
    if talk_target_position != Vector3.ZERO:
        var direction = (talk_target_position - global_position).normalized()
        direction.y = 0
        if direction.length() > 0.1:
            _rotate_toward_direction(direction, delta)
    
    stop_movement()
    
    velocity.y = -10
    move_and_slide()

func _handle_wander_state(delta):
    if react_to_player_proximity:
        _check_player_proximity()
    
    if is_idle:
        idle_timer -= delta
        if idle_timer <= 0:
            _choose_new_target()
    else:
        _move_to_target(delta)

func _handle_investigate_state(delta):
    # First, move to investigation position if not there yet
    var distance_to_target = global_position.distance_to(investigation_position)
    
    if distance_to_target > 1.0:  # Not at investigation point yet
        # Use movement system to move to investigation position
        if not movement_system.is_moving():
            move_to_position(investigation_position)
    else:
        # At investigation point, look around
        stop_movement()  # Ensure we're stopped
        investigation_timer += delta
        
        # Look around by rotating
        rotate_y(delta * 2.0)
        
        # Check if investigation time is up
        if investigation_timer >= investigation_duration:
            print(npc_name + ": Nothing here... returning to patrol.")
            set_state(MovementState.RETURN_TO_PATROL)
        
        velocity.y = -10
        move_and_slide()

func _handle_return_to_patrol_state(delta):
    if not use_waypoints or waypoint_nodes.size() == 0:
        set_state(MovementState.WANDER)
        return
    
    # Get the waypoint we need to return to
    var target_waypoint = waypoint_nodes[last_patrol_waypoint_index]
    if not is_instance_valid(target_waypoint):
        set_state(MovementState.PATROL)
        return
    
    var target_pos = target_waypoint.global_position
    target_pos.y = global_position.y
    
    # Use movement system to return to patrol waypoint
    if not movement_system.is_moving():
        move_to_position(target_pos)

# Waypoint navigation
func _follow_waypoints(delta):
    _update_waypoint_target()
    
    if is_paused:
        pause_timer -= delta
        stop_movement()
        
        if pause_timer <= 0:
            is_paused = false
            current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
            _update_waypoint_target()
        
        # Apply gravity while paused
        velocity.y = -10
        move_and_slide()
        return
    
    # Use movement system to move to waypoint
    if not movement_system.is_moving():
        move_to_position(waypoint_target)
    
    # Handle rotation towards movement direction if movement system is active
    if movement_system and movement_system.is_moving():
        var target = movement_system.get_current_target()
        if target != Vector3.ZERO:
            var direction = (target - global_position).normalized()
            direction.y = 0
            if direction.length() > 0.1:
                _rotate_toward_direction(direction, delta)

func _update_waypoint_target():
    if waypoint_nodes.size() == 0:
        return
    
    var current_waypoint = waypoint_nodes[current_waypoint_index]
    if is_instance_valid(current_waypoint):
        waypoint_target = current_waypoint.global_position
        waypoint_target.y = global_position.y

# Wander behavior
func _move_to_target(delta):
    # Delegate to movement system
    if movement_system and not movement_system.is_moving():
        movement_system.move_to_position(current_target)

func _choose_new_target():
    var random_offset = Vector3(
        randf_range(-wander_radius, wander_radius),
        0,
        randf_range(-wander_radius, wander_radius)
    )
    current_target = initial_position + random_offset
    is_idle = false

# Rotation
func _rotate_toward_direction(direction: Vector3, delta: float):
    var target_transform = transform.looking_at(global_position + direction, Vector3.UP)
    
    if smooth_rotation:
        var current_quat = transform.basis.get_rotation_quaternion()
        var target_quat = target_transform.basis.get_rotation_quaternion()
        var new_quat = current_quat.slerp(target_quat, rotation_speed * delta)
        transform.basis = Basis(new_quat)
        rotation.x = 0
        rotation.z = 0
    else:
        look_at(global_position + direction, Vector3.UP)
        rotation.x = 0
        rotation.z = 0

# Proximity detection
func _check_player_proximity():
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return
    
    var distance = global_position.distance_to(player.global_position)
    
    if distance <= talk_trigger_distance:
        set_talk_state(player.global_position)
    elif distance <= idle_trigger_distance:
        set_idle_state()

func _check_player_proximity_idle():
    var player = get_tree().get_first_node_in_group("player")
    if player:
        var distance = global_position.distance_to(player.global_position)
        if distance > idle_trigger_distance:
            resume_previous_state()
        elif distance <= talk_trigger_distance:
            set_talk_state(player.global_position)

func _check_player_proximity_talk():
    var player = get_tree().get_first_node_in_group("player")
    if player:
        var distance = global_position.distance_to(player.global_position)
        if distance > talk_trigger_distance:
            set_idle_state()

# Interaction
func interact():
    var player = get_tree().get_first_node_in_group("player")
    if player:
        set_talk_state(player.global_position)
    
    is_talking = true
    emit_signal("dialogue_started", self)
    
    var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
    if dialogue_ui:
        dialogue_ui.start_dialogue(self, initial_dialogue_id)

func end_dialogue():
    is_talking = false
    has_been_interviewed = true
    emit_signal("dialogue_ended", self)
    resume_previous_state()

func get_interaction_prompt() -> String:
    return "Talk to " + npc_name

# Visual setup
func _setup_name_labels():
    var name_label = get_node_or_null("Head/NameLabel")
    if name_label:
        name_label.text = npc_name
    
    var role_label = get_node_or_null("Head/RoleLabel")
    if role_label:
        role_label.text = role

func _create_face_indicator():
    if not show_face_indicator:
        return
    
    match face_indicator_type:
        "Cone":
            _create_cone_indicator()
        "Eyes":
            _create_eye_indicators()
        "Nose":
            _create_nose_indicator()
        "Arrow":
            _create_arrow_indicator()

func _create_cone_indicator():
    face_indicator_mesh = MeshInstance3D.new()
    face_indicator_mesh.name = "FaceIndicator"
    
    var cone = CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = face_indicator_size
    cone.height = face_indicator_size * 2
    cone.radial_segments = 8
    cone.rings = 1
    
    face_indicator_mesh.mesh = cone
    
    var material = StandardMaterial3D.new()
    material.albedo_color = face_indicator_color
    material.emission_enabled = true
    material.emission = face_indicator_color
    material.emission_energy = 0.3
    face_indicator_mesh.material_override = material
    
    face_indicator_mesh.position = Vector3(0, 1.6, -0.5)
    face_indicator_mesh.rotation_degrees = Vector3(90, 0, 0)
    
    add_child(face_indicator_mesh)

func _create_eye_indicators():
    var eye_distance = 0.1
    var eye_size = 0.05
    var eye_height = 1.7
    var eye_forward = -0.4
    
    for i in range(2):
        var eye = MeshInstance3D.new()
        eye.name = "Eye" + str(i + 1)
        
        var sphere = SphereMesh.new()
        sphere.radial_segments = 8
        sphere.rings = 4
        sphere.radius = eye_size
        sphere.height = eye_size * 2
        
        eye.mesh = sphere
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color.WHITE
        mat.emission_enabled = true
        mat.emission = Color.WHITE
        mat.emission_energy = 1.0
        eye.material_override = mat
        
        var x_offset = eye_distance if i == 0 else -eye_distance
        eye.position = Vector3(x_offset, eye_height, eye_forward)
        
        add_child(eye)

func _create_nose_indicator():
    var nose = MeshInstance3D.new()
    nose.name = "NoseIndicator"
    
    var box = BoxMesh.new()
    box.size = Vector3(face_indicator_size * 0.5, face_indicator_size * 0.8, face_indicator_size * 1.5)
    
    nose.mesh = box
    
    var material = StandardMaterial3D.new()
    material.albedo_color = face_indicator_color
    material.emission_enabled = true
    material.emission = face_indicator_color
    material.emission_energy = 0.5
    nose.material_override = material
    
    nose.position = Vector3(0, 1.65, -0.45)
    
    add_child(nose)

func _create_arrow_indicator():
    var arrow = MeshInstance3D.new()
    arrow.name = "ArrowIndicator"
    
    var cone = CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = face_indicator_size * 1.5
    cone.height = face_indicator_size * 3
    cone.radial_segments = 3
    
    arrow.mesh = cone
    
    var material = StandardMaterial3D.new()
    material.albedo_color = face_indicator_color
    material.emission_enabled = true
    material.emission = face_indicator_color
    material.emission_energy = 0.8
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.8
    arrow.material_override = material
    
    arrow.position = Vector3(0, 2.2, -0.3)
    arrow.rotation_degrees = Vector3(-90, 0, 0)
    
    add_child(arrow)

func _create_state_label():
    if not show_state_label:
        return
    
    state_label = Label3D.new()
    state_label.name = "StateLabel"
    
    state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    state_label.no_depth_test = false
    state_label.fixed_size = true
    state_label.pixel_size = 0.001
    
    state_label.position = Vector3(0, 2.2, 0)
    
    state_label.text = "[" + get_state_name() + "]"
    
    state_label.modulate = Color.WHITE
    state_label.outline_modulate = Color.BLACK
    state_label.outline_size = 4
    state_label.font_size = 16
    
    add_child(state_label)
    
    _update_state_label()

func _update_state_label():
    if not state_label:
        return
    
    var state_name = get_state_name()
    state_label.text = "[" + state_name + "]"
    
    match current_state:
        MovementState.PATROL:
            state_label.modulate = Color.GREEN
            if use_waypoints and waypoint_nodes.size() > 0:
                state_label.text += "\nWP: " + str(current_waypoint_index + 1) + "/" + str(waypoint_nodes.size())
                if is_paused:
                    state_label.text += " (Paused)"
        MovementState.IDLE:
            state_label.modulate = Color.YELLOW
        MovementState.TALK:
            state_label.modulate = Color.CYAN
        MovementState.WANDER:
            state_label.modulate = Color.ORANGE
        MovementState.INVESTIGATE:
            state_label.modulate = Color.RED
            state_label.text += "\n[!]"
        MovementState.RETURN_TO_PATROL:
            state_label.modulate = Color.ORANGE
            state_label.text += "\n→WP" + str(last_patrol_waypoint_index + 1)

func get_state_name() -> String:
    return MovementState.keys()[current_state]

# Utility
func set_suspicious(suspicious: bool):
    if is_suspicious != suspicious:
        is_suspicious = suspicious
        emit_signal("suspicion_changed", self, is_suspicious)

# Detection system for saboteur behavior
func _check_for_player_detection():
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return
    
    var distance = global_position.distance_to(player.global_position)
    
    # Check if in detection range
    if distance > detection_range:
        return
    
    # Check line of sight
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        global_position + Vector3.UP * 1.5,
        player.global_position + Vector3.UP * 1.0
    )
    query.exclude = [self]
    query.collision_mask = 1  # Environment layer
    
    var result = space_state.intersect_ray(query)
    if result:
        # Something blocking view
        return
    
    # Check vision angle
    var to_player = (player.global_position - global_position).normalized()
    var forward = -global_transform.basis.z
    var angle = rad_to_deg(forward.angle_to(to_player))
    
    if angle <= vision_angle / 2.0:
        # Player detected!
        print(npc_name + ": Who's there? I see you!")
        player_detected = true
        set_state(MovementState.INVESTIGATE, player.global_position)

# Movement system wrapper methods
func move_to_position(position: Vector3) -> void:
    if movement_system:
        movement_system.move_to_position(position)

func stop_movement() -> void:
    if movement_system:
        movement_system.stop_movement()
    velocity = Vector3.ZERO

# Movement system signal handlers
func _on_movement_completed() -> void:
    match current_state:
        MovementState.PATROL:
            if use_waypoints and waypoint_nodes.size() > 0:
                # Handle waypoint reaching
                if pause_at_waypoints:
                    is_paused = true
                    pause_timer = randf_range(pause_duration_min, pause_duration_max)
                else:
                    current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
                    _update_waypoint_target()
            else:
                is_idle = true
                idle_timer = randf_range(idle_time_min, idle_time_max)
        MovementState.WANDER:
            is_idle = true
            idle_timer = randf_range(idle_time_min, idle_time_max)
        MovementState.INVESTIGATE:
            # Movement completed, we're at investigation point
            pass  # Investigation logic handled in _handle_investigate_state
        MovementState.RETURN_TO_PATROL:
            # Resume normal patrol from this waypoint
            current_waypoint_index = last_patrol_waypoint_index
            returning_to_patrol = false
            set_state(MovementState.PATROL)
            print(npc_name + ": Back on patrol route.")

func _on_movement_failed(reason: String) -> void:
    print(npc_name + " movement failed: " + reason)
    
    match current_state:
        MovementState.PATROL:
            if use_waypoints and waypoint_nodes.size() > 0:
                # Skip to next waypoint if movement failed
                current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
                _update_waypoint_target()
        MovementState.WANDER:
            # Choose a new target
            _choose_new_target()
