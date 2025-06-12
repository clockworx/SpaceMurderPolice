@tool
extends CharacterBody3D
class_name NPCBase

# Movement states
enum MovementState {
    PATROL,  # Move between waypoints or wander
    IDLE,    # Stop at current position
    TALK,     # Face toward a target position
    INVESTIGATE,  # Stop and look around when player detected
    RETURN_TO_PATROL  # Go back to waypoint route after investigation
}

@export_group("NPC Properties")
@export var npc_name: String = "Unknown"
@export var role: String = "Crew Member"
@export var initial_dialogue_id: String = "greeting"
@export var is_suspicious: bool = false
@export var has_alibi: bool = true
@export var can_be_saboteur: bool = false:  # For NPCs that can switch modes
    set(value):
        can_be_saboteur = value
        if not value:
            # Disable all saboteur features when can_be_saboteur is turned off
            enable_saboteur_behavior = false
            enable_sound_detection = false
            if show_sound_detection_area and sound_detection_sphere:
                sound_detection_sphere.visible = false
        if Engine.is_editor_hint():
            notify_property_list_changed()

@export_group("Saboteur Mode")
@export var enable_saboteur_behavior: bool = false
@export var saboteur_detection_range: float = 10.0
@export var vision_angle: float = 60.0
@export var investigation_duration: float = 3.0
@export var return_to_patrol_speed: float = 3.0

@export_group("Sound Detection")
@export var enable_sound_detection: bool = false
@export var sound_detection_radius: float = 8.0
@export var crouched_sound_radius_multiplier: float = 0.4  # 40% of normal radius when crouched
@export var running_sound_radius_multiplier: float = 1.5  # 150% of normal radius when running
@export var sound_investigation_duration: float = 2.0
@export var show_sound_detection_area: bool = false:
    set(value):
        show_sound_detection_area = value
        if Engine.is_editor_hint():
            return
        if value and not sound_detection_sphere:
            _create_sound_detection_visualization()
        elif sound_detection_sphere:
            sound_detection_sphere.visible = value

@export_group("Movement")
@export var walk_speed: float = 2.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0
@export var wander_radius: float = 5.0
@export var assigned_room: String = ""  # Room assignment for NPC
@export var rotation_speed: float = 5.0  # How fast to rotate (radians/second)
@export var smooth_rotation: bool = true  # Enable smooth rotation

@export_group("Waypoint Settings")
@export var use_waypoints: bool = false
@export var waypoint_nodes: Array[Node3D] = []
@export var waypoint_reach_distance: float = 0.3  # Distance to consider waypoint reached
@export var pause_at_waypoints: bool = true
@export var pause_duration_min: float = 2.0
@export var pause_duration_max: float = 5.0

@export_group("State Settings")
@export var current_state: MovementState = MovementState.PATROL
@export var debug_state_changes: bool = false  # Print state changes
@export var show_state_label: bool = true  # Show state label above NPC
@export var react_to_player_proximity: bool = true  # Auto change states based on player distance
@export var idle_trigger_distance: float = 3.0  # Distance to stop and idle
@export var talk_trigger_distance: float = 2.0  # Distance to face player

@export_group("Movement System")
@export var use_navmesh: bool = false
@export var use_hybrid_movement: bool = false  # Use hybrid system that switches between Direct and NavMesh

@export_group("Interaction")
@export var interaction_distance: float = 3.0
@export var face_player_when_talking: bool = true

@export_group("Line of Sight Detection")
@export var enable_los_detection: bool = true
@export var detection_range: float = 10.0:  # Maximum detection distance
    set(value):
        detection_range = value
        if vision_cone_mesh:
            _update_vision_cone_mesh()
@export var detection_angle: float = 45.0:  # Half angle of vision cone (degrees)
    set(value):
        detection_angle = value
        if vision_cone_mesh:
            _update_vision_cone_mesh()
@export var show_detection_indicator: bool = true:
    set(value):
        show_detection_indicator = value
        if detection_indicator:
            detection_indicator.visible = value
@export var show_vision_cone: bool = false:  # Debug visualization of vision cone
    set(value):
        show_vision_cone = value
        if vision_cone_mesh:
            vision_cone_mesh.visible = value
        elif value:
            _create_vision_cone()
@export var detection_indicator_color: Color = Color.RED
@export var undetected_indicator_color: Color = Color.GREEN

@export_group("Visual")
@export var show_face_indicator: bool = true
@export var face_indicator_color: Color = Color.YELLOW
@export var face_indicator_size: float = 0.2
@export_enum("Cone", "Eyes", "Nose", "Arrow") var face_indicator_type: String = "Cone"

var dialogue_state: Dictionary = {}
var has_been_interviewed: bool = false
var current_dialogue: String = ""
var is_talking: bool = false
var player_nearby: bool = false

var initial_position: Vector3
var current_target: Vector3
var idle_timer: float = 0.0
var is_idle: bool = true

signal dialogue_started(npc)
signal dialogue_ended(npc)
signal suspicion_changed(npc, is_suspicious)

var relationship_manager: RelationshipManager
var relationship_indicator: Label3D
var face_indicator_mesh: MeshInstance3D

# Waypoint system variables
var current_waypoint_index: int = 0
var waypoint_target: Vector3
var pause_timer: float = 0.0
var is_paused: bool = false

# State system variables
var talk_target_position: Vector3  # Position to face when in TALK state
var previous_state: MovementState = MovementState.PATROL  # For resuming after TALK/IDLE
var state_label: Label3D  # Debug label for showing current state

# Stuck detection
var last_position: Vector3
var stuck_timer: float = 0.0
var stuck_threshold: float = 10.0  # Give NPCs time to travel long distances
var min_movement_threshold: float = 0.05  # Minimum movement to not be considered stuck

# Line of sight detection
var detection_raycast: RayCast3D
var detection_indicator: MeshInstance3D
var vision_cone_mesh: MeshInstance3D
var player_detected: bool = false
var last_detection_state: bool = false

# Saboteur detection system
var investigation_timer: float = 0.0
var investigation_position: Vector3
var last_patrol_waypoint_index: int = 0
var returning_to_patrol: bool = false

# Sound detection system
var sound_detection_sphere: MeshInstance3D
var sound_detected: bool = false
var is_investigating_sound: bool = false
var sound_waypoint_debug: MeshInstance3D  # Debug sphere for sound investigation point

# Movement system
var movement_system: MovementInterface

func _ready():
    if Engine.is_editor_hint():
        return
        
    collision_layer = 2  # Interactable layer
    collision_mask = 1   # Collide with environment
    
    # Initialize movement system
    if use_hybrid_movement:
        movement_system = HybridMovement.new(self)
    elif use_navmesh:
        movement_system = NavMeshMovement.new(self)
    else:
        movement_system = DirectMovement.new(self)
    
    add_child(movement_system)
    movement_system.movement_completed.connect(_on_movement_completed)
    movement_system.movement_failed.connect(_on_movement_failed)
    
    # Ensure saboteur features are disabled if can_be_saboteur is false
    if not can_be_saboteur:
        enable_saboteur_behavior = false
        enable_sound_detection = false
    
    # Clean up any existing detection indicator if it shouldn't be shown
    if not show_detection_indicator:
        var existing_indicator = get_node_or_null("DetectionIndicator")
        if existing_indicator:
            existing_indicator.queue_free()
    
    # Ensure physics processing is enabled
    set_physics_process(true)
    
    initial_position = global_position
    current_target = global_position
    last_position = global_position
    
    # Start with a short idle
    idle_timer = 0.5
    is_idle = true
    
    # Add to NPC group
    add_to_group("npcs")
    
    # Update name and role labels to match exported properties
    var name_label = get_node_or_null("Head/NameLabel")
    if name_label:
        name_label.text = npc_name
    
    var role_label = get_node_or_null("Head/RoleLabel")
    if role_label:
        role_label.text = role
    
    # Get relationship manager
    relationship_manager = get_tree().get_first_node_in_group("relationship_manager")
    
    # Create face indicator
    _create_face_indicator()
    if not relationship_manager:
        relationship_manager = RelationshipManager.new()
        relationship_manager.add_to_group("relationship_manager")
        get_tree().root.add_child.call_deferred(relationship_manager)
    
    # Create relationship indicator
    _create_relationship_indicator()
    
    # Create state label for debugging
    _create_state_label()
    
    # Create line of sight detection system
    _create_detection_system()
    
    # Ensure detection indicator visibility matches the setting
    if detection_indicator:
        detection_indicator.visible = show_detection_indicator
    
    # Create sound detection visualization
    _create_sound_detection_visualization()
    
    # Initialize waypoint system if enabled
    if use_waypoints and waypoint_nodes.size() > 0:
        _update_waypoint_target()
        # Debug: NPC initialized with waypoints
        #print(npc_name + " initialized with ", waypoint_nodes.size(), " waypoint nodes")
    
    # Connect to relationship changes if manager exists
    if relationship_manager and relationship_manager.has_signal("relationship_changed"):
        relationship_manager.relationship_changed.connect(_on_relationship_changed)
    
    # Debug: NPC initialized
    #print(npc_name + " initialized at position: " + str(global_position))

func _physics_process(delta):
    if Engine.is_editor_hint():
        return
        
    if is_talking:
        # Face the player while talking
        if face_player_when_talking:
            var player = get_tree().get_first_node_in_group("player")
            if player:
                var look_position = player.global_position
                look_position.y = global_position.y  # Keep same height to avoid tilting
                look_at(look_position, Vector3.UP)
                rotation.x = 0
                rotation.z = 0
        return
    
    # Update line of sight detection
    if enable_los_detection:
        _update_detection()
    
    # Ensure detection indicator respects visibility setting
    if detection_indicator and not show_detection_indicator:
        detection_indicator.queue_free()
        detection_indicator = null
    
    # Check for saboteur detection if enabled
    if can_be_saboteur and enable_saboteur_behavior and current_state == MovementState.PATROL:
        _check_for_saboteur_detection()
    
    # Update sound detection visualization
    if can_be_saboteur and enable_sound_detection:
        _update_sound_detection_visualization()
    
    # Handle different states
    match current_state:
        MovementState.PATROL:
            _handle_patrol_state(delta)
        MovementState.IDLE:
            _handle_idle_state(delta)
        MovementState.TALK:
            _handle_talk_state(delta)
        MovementState.INVESTIGATE:
            _handle_investigate_state(delta)
        MovementState.RETURN_TO_PATROL:
            _handle_return_to_patrol_state(delta)

func _move_to_target(delta):
    # Delegate to movement system
    if movement_system and not movement_system.is_moving():
        movement_system.move_to_position(current_target)

func _start_idle():
    is_idle = true
    idle_timer = randf_range(idle_time_min, idle_time_max)
    velocity = Vector3.ZERO

func _choose_new_target():
    # Simple random wandering within radius
    var random_offset = Vector3(
        randf_range(-wander_radius, wander_radius),
        0,
        randf_range(-wander_radius, wander_radius)
    )
    
    current_target = initial_position + random_offset
    current_target.y = global_position.y  # Keep same height
    
    is_idle = false

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
                var waypoint_name = waypoint_nodes[current_waypoint_index].name if is_instance_valid(waypoint_nodes[current_waypoint_index]) else "Unknown"
                
                # Reset stuck timer since we successfully reached a waypoint
                stuck_timer = 0.0
                
                if pause_at_waypoints:
                    is_paused = true
                    pause_timer = randf_range(pause_duration_min, pause_duration_max)
                else:
                    if waypoint_nodes.size() > 0:
                        current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
                        _update_waypoint_target()
            else:
                _start_idle()
        MovementState.INVESTIGATE:
            # Movement completed, we're at investigation point
            pass  # Investigation logic handled in _handle_investigate_state
        MovementState.RETURN_TO_PATROL:
            # Resume normal patrol from this waypoint
            current_waypoint_index = last_patrol_waypoint_index
            returning_to_patrol = false
            set_state(MovementState.PATROL)
            print(npc_name + ": Back on patrol route.")
        _:
            _start_idle()

func _on_movement_failed(reason: String) -> void:
    print(npc_name + " movement failed: " + reason)
    
    match current_state:
        MovementState.PATROL:
            if use_waypoints and waypoint_nodes.size() > 0:
                # Skip to next waypoint if movement failed
                current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
                _update_waypoint_target()
        _:
            _start_idle()

func _create_relationship_indicator():
    if relationship_indicator:
        return
        
    relationship_indicator = Label3D.new()
    relationship_indicator.name = "RelationshipIndicator"
    relationship_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    relationship_indicator.no_depth_test = true
    relationship_indicator.modulate = Color.WHITE
    relationship_indicator.outline_modulate = Color.BLACK
    relationship_indicator.outline_size = 2
    relationship_indicator.font_size = 16
    relationship_indicator.visible = false
    
    var head = get_node_or_null("Head")
    if head:
        head.add_child(relationship_indicator)
        relationship_indicator.position.y = 0.3
    else:
        add_child(relationship_indicator)
        relationship_indicator.position.y = 2.3

func _on_relationship_changed(character_name: String, new_level: int):
    if character_name != npc_name:
        return
        
    if not relationship_indicator:
        return
    
    # Update indicator based on relationship level
    match new_level:
        -2:
            relationship_indicator.text = "⚔️ Hostile"
            relationship_indicator.modulate = Color.RED
        -1:
            relationship_indicator.text = "😠 Unfriendly"
            relationship_indicator.modulate = Color.ORANGE
        0:
            relationship_indicator.text = "😐 Neutral"
            relationship_indicator.modulate = Color.YELLOW
        1:
            relationship_indicator.text = "🙂 Friendly"
            relationship_indicator.modulate = Color.LIGHT_GREEN
        2:
            relationship_indicator.text = "😊 Trusted"
            relationship_indicator.modulate = Color.GREEN
    
    # Show indicator briefly
    relationship_indicator.visible = true
    await get_tree().create_timer(3.0).timeout
    relationship_indicator.visible = false

func _handle_patrol_state(delta):
    # Check if stuck
    _check_if_stuck(delta)
    
    # Check player proximity if enabled
    if react_to_player_proximity:
        _check_player_proximity()
    
    # Update state label with current waypoint info
    _update_state_label()
    
    if use_waypoints and waypoint_nodes.size() > 0:
        _follow_waypoints(delta)
    else:
        # Original wander behavior
        if is_idle:
            idle_timer -= delta
            if idle_timer <= 0:
                _choose_new_target()
        else:
            _move_to_target(delta)

func _handle_idle_state(delta):
    # Check if player moved away
    if react_to_player_proximity:
        var player = get_tree().get_first_node_in_group("player")
        if player:
            var distance = global_position.distance_to(player.global_position)
            if distance > idle_trigger_distance:
                set_patrol_state()  # Resume patrol
            elif distance <= talk_trigger_distance:
                set_talk_state(player.global_position)  # Face player if very close
    
    # Ensure NPC stays in place
    stop_movement()
    
    # Apply gravity
    velocity.y = -10
    move_and_slide()

func _handle_talk_state(delta):
    # Check if player moved away
    if react_to_player_proximity and not is_talking:
        var player = get_tree().get_first_node_in_group("player")
        if player:
            var distance = global_position.distance_to(player.global_position)
            if distance > talk_trigger_distance:
                set_idle_state()  # Go to idle if player backs away
    
    # Face the talk target
    if talk_target_position != Vector3.ZERO:
        var direction = (talk_target_position - global_position).normalized()
        direction.y = 0  # Keep horizontal
        
        if direction.length() > 0.1:
            _rotate_toward_direction(direction, delta)
    
    # Stay in place
    stop_movement()
    
    # Apply gravity
    velocity.y = -10
    move_and_slide()

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
        var duration = sound_investigation_duration if is_investigating_sound else investigation_duration
        if investigation_timer >= duration:
            if is_investigating_sound:
                print(npc_name + ": Must have been nothing...")
            else:
                print(npc_name + ": Nothing here... returning to patrol.")
            is_investigating_sound = false
            sound_detected = false
            set_state(MovementState.RETURN_TO_PATROL)
            
            # Clean up debug sphere
            if sound_waypoint_debug:
                sound_waypoint_debug.queue_free()
                sound_waypoint_debug = null
        
        # Apply gravity while investigating
        velocity.y = -10
        move_and_slide()

func _handle_return_to_patrol_state(delta):
    if not use_waypoints or waypoint_nodes.size() == 0:
        # No waypoints, just go back to wandering
        set_state(MovementState.PATROL)
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

func _follow_waypoints(delta):
    # Ensure we have waypoints
    if waypoint_nodes.is_empty():
        return
    
    # Update target position from current waypoint node
    _update_waypoint_target()
    
    if is_paused:
        pause_timer -= delta
        
        # Stop movement while paused
        stop_movement()
        
        # Optional: Slowly look around while paused
        if smooth_rotation and pause_timer > 0:
            var look_offset = sin(pause_timer * 2.0) * 0.5
            rotation.y += look_offset * delta
        
        if pause_timer <= 0:
            is_paused = false
            if waypoint_nodes.size() > 0:
                current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
                _update_waypoint_target()
                # Debug: Continuing to next waypoint
                #print(npc_name + " continuing to waypoint ", current_waypoint_index)
        
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

func interact():
    # This is called when the player interacts with the NPC
    if is_talking:
        return
    
    # Switch to TALK state and face the player
    var player = get_tree().get_first_node_in_group("player")
    if player:
        set_talk_state(player.global_position)
    
    is_talking = true
    emit_signal("dialogue_started", self)
    
    # Open dialogue UI
    var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
    if dialogue_ui:
        dialogue_ui.start_dialogue(self, initial_dialogue_id)

func end_dialogue():
    is_talking = false
    has_been_interviewed = true
    emit_signal("dialogue_ended", self)
    
    # Return to previous state
    resume_previous_state()

func get_interaction_prompt() -> String:
    return "Talk to " + npc_name

func set_suspicious(suspicious: bool):
    if is_suspicious != suspicious:
        is_suspicious = suspicious
        emit_signal("suspicion_changed", self, is_suspicious)

func get_current_relationship_level() -> int:
    if relationship_manager:
        return relationship_manager.get_relationship(npc_name)
    return 0

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
    # Create the face indicator mesh
    face_indicator_mesh = MeshInstance3D.new()
    face_indicator_mesh.name = "FaceIndicator"
    
    # Create a cone mesh to show direction
    var cone = CylinderMesh.new()
    cone.top_radius = 0.0  # Makes it a cone
    cone.bottom_radius = face_indicator_size
    cone.height = face_indicator_size * 2
    cone.radial_segments = 8
    cone.rings = 1
    
    face_indicator_mesh.mesh = cone
    
    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = face_indicator_color
    material.emission_enabled = true
    material.emission = face_indicator_color
    material.emission_energy = 0.3
    material.no_depth_test = false  # Ensure it's occluded by geometry
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    face_indicator_mesh.material_override = material
    
    # Position it in front of the character at head height (forward is -Z in Godot)
    face_indicator_mesh.position = Vector3(0, 1.6, -0.5)
    face_indicator_mesh.rotation_degrees = Vector3(90, 0, 0)  # Point forward
    
    add_child(face_indicator_mesh)

func _create_eye_indicators():
    # Create two small spheres for eyes
    var eye_distance = 0.1
    var eye_size = 0.05
    var eye_height = 1.7
    var eye_forward = -0.4  # Forward is -Z in Godot
    
    for i in range(2):
        var eye = MeshInstance3D.new()
        eye.name = "Eye" + str(i + 1)
        
        var sphere = SphereMesh.new()
        sphere.radial_segments = 8
        sphere.rings = 4
        sphere.radius = eye_size
        sphere.height = eye_size * 2
        
        eye.mesh = sphere
        
        # Create glowing material
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color.WHITE
        mat.emission_enabled = true
        mat.emission = Color.WHITE
        mat.emission_energy = 1.0
        mat.no_depth_test = false  # Ensure it's occluded by geometry
        eye.material_override = mat
        
        # Position eyes
        var x_offset = eye_distance if i == 0 else -eye_distance
        eye.position = Vector3(x_offset, eye_height, eye_forward)
        
        add_child(eye)

func _create_nose_indicator():
    # Create a simple box for nose
    var nose = MeshInstance3D.new()
    nose.name = "NoseIndicator"
    
    var box = BoxMesh.new()
    box.size = Vector3(face_indicator_size * 0.5, face_indicator_size * 0.8, face_indicator_size * 1.5)
    
    nose.mesh = box
    
    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = face_indicator_color
    material.emission_enabled = true
    material.emission = face_indicator_color
    material.emission_energy = 0.5
    material.no_depth_test = false  # Ensure it's occluded by geometry
    nose.material_override = material
    
    # Position at face level (forward is -Z)
    nose.position = Vector3(0, 1.65, -0.45)
    
    add_child(nose)

func _create_arrow_indicator():
    # Create an arrow using a cone
    var arrow = MeshInstance3D.new()
    arrow.name = "ArrowIndicator"
    
    # Create arrow shape
    var cone = CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = face_indicator_size * 1.5
    cone.height = face_indicator_size * 3
    cone.radial_segments = 3  # Triangle shape
    
    arrow.mesh = cone
    
    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = face_indicator_color
    material.emission_enabled = true
    material.emission = face_indicator_color
    material.emission_energy = 0.8
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.8
    material.no_depth_test = false  # Ensure it's occluded by geometry
    arrow.material_override = material
    
    # Position above head pointing forward (forward is -Z)
    arrow.position = Vector3(0, 2.2, -0.3)
    arrow.rotation_degrees = Vector3(-90, 0, 0)
    
    add_child(arrow)

# State management functions
func set_state(new_state: MovementState, target_position: Vector3 = Vector3.ZERO):
    if current_state == new_state:
        return
    
    # Store previous state for resuming
    if current_state != MovementState.IDLE and current_state != MovementState.TALK:
        previous_state = current_state
    
    current_state = new_state
    
    if debug_state_changes:
        print(npc_name + " state changed to: ", MovementState.keys()[new_state])
    
    # Update state label
    _update_state_label()
    
    # Handle state-specific setup
    match new_state:
        MovementState.PATROL:
            # Resume patrol, no special setup needed
            pass
        MovementState.IDLE:
            # Stop movement
            velocity = Vector3.ZERO
        MovementState.TALK:
            # Set target to face
            talk_target_position = target_position
            velocity = Vector3.ZERO
        MovementState.INVESTIGATE:
            investigation_position = target_position
            investigation_position.y = global_position.y  # Keep at same height
            investigation_timer = 0.0
            velocity = Vector3.ZERO
            # Remember current waypoint
            if use_waypoints:
                last_patrol_waypoint_index = current_waypoint_index
        MovementState.RETURN_TO_PATROL:
            returning_to_patrol = true

func resume_previous_state():
    set_state(previous_state)

func set_patrol_state():
    set_state(MovementState.PATROL)

func set_idle_state():
    set_state(MovementState.IDLE)

func set_talk_state(target_position: Vector3):
    set_state(MovementState.TALK, target_position)

# Helper function to get current state as string
func get_state_name() -> String:
    return MovementState.keys()[current_state]

# State label functions
func _create_state_label():
    if not show_state_label:
        return
        
    state_label = Label3D.new()
    state_label.name = "StateLabel"
    
    # Configure label appearance
    state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    state_label.no_depth_test = false  # Allow geometry to occlude
    state_label.fixed_size = true
    state_label.pixel_size = 0.001  # Much smaller
    
    # Position above head (closer to name)
    state_label.position = Vector3(0, 2.2, 0)
    
    # Set initial text
    state_label.text = "[" + get_state_name() + "]"
    
    # Style the label (smaller font)
    state_label.modulate = Color.WHITE
    state_label.outline_modulate = Color.BLACK
    state_label.outline_size = 4
    state_label.font_size = 16  # Smaller than name label
    
    add_child(state_label)
    
    # Set initial color
    _update_state_label()

func _update_state_label():
    if not state_label:
        return
    
    var state_name = get_state_name()
    state_label.text = "[" + state_name + "]"
    
    # Color code by state
    match current_state:
        MovementState.PATROL:
            state_label.modulate = Color.GREEN
        MovementState.IDLE:
            state_label.modulate = Color.YELLOW
        MovementState.TALK:
            state_label.modulate = Color.CYAN
        MovementState.INVESTIGATE:
            state_label.modulate = Color.RED
        MovementState.RETURN_TO_PATROL:
            state_label.modulate = Color.ORANGE
    
    # Add additional info for certain states
    if current_state == MovementState.PATROL and use_waypoints and waypoint_nodes.size() > 0:
        state_label.text += "\nWP: " + str(current_waypoint_index + 1) + "/" + str(waypoint_nodes.size())
        if is_paused:
            state_label.text += " (Paused)"
    elif current_state == MovementState.INVESTIGATE:
        state_label.text += "\n[!]"
    elif current_state == MovementState.RETURN_TO_PATROL:
        state_label.text += "\n→WP" + str(last_patrol_waypoint_index + 1)

func _check_player_proximity():
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return
    
    var distance = global_position.distance_to(player.global_position)
    
    if distance <= talk_trigger_distance:
        set_talk_state(player.global_position)
    elif distance <= idle_trigger_distance:
        set_idle_state()

# Waypoint functions
func _update_waypoint_target():
    if waypoint_nodes.size() == 0:
        return
        
    var current_waypoint = waypoint_nodes[current_waypoint_index]
    if is_instance_valid(current_waypoint):
        waypoint_target = current_waypoint.global_position
        # Always ignore Y - NPCs stay at ground level
        waypoint_target.y = global_position.y

func _check_if_stuck(delta):
    # Don't check for stuck if we're intentionally paused at a waypoint
    if is_paused:
        stuck_timer = 0.0
        last_position = global_position
        return
    
    # Don't check if movement system isn't active
    if not movement_system or not movement_system.is_moving():
        stuck_timer = 0.0
        last_position = global_position
        return
    
    var movement = global_position.distance_to(last_position)
    
    if movement < min_movement_threshold:
        stuck_timer += delta
        if stuck_timer > stuck_threshold:
            # Only skip if truly stuck (not making progress)
            var waypoint_name = waypoint_nodes[current_waypoint_index].name if current_waypoint_index < waypoint_nodes.size() and is_instance_valid(waypoint_nodes[current_waypoint_index]) else "Unknown"
            print("[WARNING] " + npc_name + " appears stuck! Skipping waypoint ", current_waypoint_index, " (", waypoint_name, ")")
            
            # Stop current movement
            stop_movement()
            
            # Skip to next waypoint
            if waypoint_nodes.size() > 0:
                current_waypoint_index = (current_waypoint_index + 1) % waypoint_nodes.size()
                _update_waypoint_target()
            stuck_timer = 0.0
            is_paused = false
    else:
        stuck_timer = 0.0
    
    last_position = global_position

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
        # Instant rotation (original behavior)
        look_at(global_position + direction, Vector3.UP)
        rotation.x = 0
        rotation.z = 0

# Line of sight detection functions
func _create_detection_system():
    if not enable_los_detection:
        return
    
    # Creating detection system...
    
    # Create RayCast3D for line of sight
    detection_raycast = RayCast3D.new()
    detection_raycast.name = "DetectionRayCast"
    detection_raycast.enabled = true
    detection_raycast.exclude_parent = true
    detection_raycast.collision_mask = 2  # Detect only layer 2 (player)
    
    # Set raycast direction and length
    detection_raycast.target_position = Vector3(0, 0, -detection_range)  # Forward is -Z
    
    # Position at eye level
    detection_raycast.position = Vector3(0, 1.6, 0)
    
    add_child(detection_raycast)
    
    # Create detection indicator ONLY if explicitly enabled
    if show_detection_indicator and enable_los_detection:
        _create_detection_indicator()
    else:
        # Make sure no indicator exists
        if detection_indicator:
            detection_indicator.queue_free()
            detection_indicator = null
    
    # Create vision cone visualization if enabled
    if show_vision_cone:
        _create_vision_cone()

func _create_detection_indicator():
    detection_indicator = MeshInstance3D.new()
    detection_indicator.name = "DetectionIndicator"
    
    # Create a sphere mesh for the indicator
    var sphere = SphereMesh.new()
    sphere.radius = 0.1
    sphere.height = 0.2
    sphere.radial_segments = 8
    sphere.rings = 4
    
    detection_indicator.mesh = sphere
    
    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = undetected_indicator_color
    material.emission_enabled = true
    material.emission = undetected_indicator_color
    material.emission_energy = 0.5
    detection_indicator.material_override = material
    
    # Position above head
    detection_indicator.position = Vector3(0, 2.5, 0)
    
    # Set visibility based on the flag
    detection_indicator.visible = show_detection_indicator
    
    add_child(detection_indicator)

func _create_vision_cone():
    vision_cone_mesh = MeshInstance3D.new()
    vision_cone_mesh.name = "VisionCone"
    
    _update_vision_cone_mesh()
    
    add_child(vision_cone_mesh)

func _update_vision_cone_mesh():
    if not vision_cone_mesh:
        return
    
    # Remove old range line if it exists
    var old_line = vision_cone_mesh.get_node_or_null("RangeLine")
    if old_line:
        old_line.queue_free()
    
    # Create a custom cone mesh for the vision area
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    
    var vertices = PackedVector3Array()
    var uvs = PackedVector2Array()
    var normals = PackedVector3Array()
    
    # Create cone vertices
    var segments = 16
    var cone_height = detection_range
    var cone_radius = tan(deg_to_rad(detection_angle)) * cone_height
    
    # Apex of cone (at NPC position)
    vertices.push_back(Vector3.ZERO)
    uvs.push_back(Vector2(0.5, 0.5))
    normals.push_back(Vector3.UP)
    
    # Base of cone vertices
    for i in range(segments + 1):
        var angle = 2.0 * PI * i / segments
        var x = cos(angle) * cone_radius
        var y = sin(angle) * cone_radius
        vertices.push_back(Vector3(x, y, -cone_height))  # -Z is forward
        uvs.push_back(Vector2(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))
        normals.push_back(Vector3.UP)
    
    # Create faces
    var faces = PackedInt32Array()
    for i in range(segments):
        # Triangle from apex to base edge
        faces.push_back(0)  # Apex
        faces.push_back(i + 1)
        faces.push_back(i + 2)
    
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_INDEX] = faces
    
    # Create the mesh
    var array_mesh = ArrayMesh.new()
    array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    
    vision_cone_mesh.mesh = array_mesh
    
    # Create material for filled cone
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.5, 0.5, 1.0, 0.3)  # Semi-transparent blue
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.no_depth_test = false  # Ensure it's occluded by geometry
    vision_cone_mesh.material_override = material
    
    # Add thick red line on ground showing range
    var range_line = MeshInstance3D.new()
    range_line.name = "RangeLine"
    
    # Create cylinder for thick line
    var cylinder = CylinderMesh.new()
    cylinder.height = detection_range
    cylinder.top_radius = 0.1  # Thick line
    cylinder.bottom_radius = 0.1
    cylinder.radial_segments = 8
    
    range_line.mesh = cylinder
    range_line.position = Vector3(0, -1.6, -detection_range / 2.0)  # Center the cylinder
    range_line.rotation_degrees = Vector3(90, 0, 0)  # Rotate to lie flat
    
    # Bright red material
    var line_material = StandardMaterial3D.new()
    line_material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)  # Pure red
    line_material.emission_enabled = true
    line_material.emission = Color(1.0, 0.0, 0.0)
    line_material.emission_energy = 1.0
    line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    range_line.material_override = line_material
    
    vision_cone_mesh.add_child(range_line)
    
    # Position at eye level
    vision_cone_mesh.position = Vector3(0, 1.6, 0)

func _update_detection():
    if not detection_raycast:
        if enable_los_detection:
            _create_detection_system()
        else:
            return
    
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        _set_detection_state(false)
        return
    
    # Check if player is within detection range
    var distance_to_player = global_position.distance_to(player.global_position)
    if distance_to_player > detection_range:
        _set_detection_state(false)
        return
    
    # Player is within range, continue checking angle
    
    # Check if player is within vision cone angle
    var to_player = (player.global_position - global_position).normalized()
    to_player.y = 0  # Ignore vertical component
    
    var forward = -transform.basis.z.normalized()
    forward.y = 0
    
    var angle = rad_to_deg(forward.angle_to(to_player))
    if angle > detection_angle:
        _set_detection_state(false)
        return
    
    # Player is within angle, continue to raycast
    
    # Point raycast at player
    var local_player_pos = to_local(player.global_position)
    # Don't override the Y, use actual relative position
    detection_raycast.target_position = local_player_pos
    
    # Aim raycast at player
    
    # Force raycast update
    detection_raycast.force_raycast_update()
    
    # Check if raycast hit the player
    if detection_raycast.is_colliding():
        var collider = detection_raycast.get_collider()
        # Raycast hit something
        if collider and collider.is_in_group("player"):
            _set_detection_state(true)
        else:
            # Something is blocking line of sight
            _set_detection_state(false)
    else:
        # Raycast not hitting anything
        _set_detection_state(false)

func _set_detection_state(detected: bool):
    # Only update if state changed
    if player_detected != detected:
        player_detected = detected
    
    last_detection_state = detected
    
    # Create indicator if it doesn't exist but should be shown
    if show_detection_indicator and not detection_indicator:
        _create_detection_indicator()
    
    # Update indicator color only if it should be visible
    if detection_indicator and detection_indicator.material_override and show_detection_indicator:
        detection_indicator.visible = true
        var material = detection_indicator.material_override
        if detected:
            material.albedo_color = detection_indicator_color
            material.emission = detection_indicator_color
        else:
            material.albedo_color = undetected_indicator_color
            material.emission = undetected_indicator_color
    elif detection_indicator and not show_detection_indicator:
        detection_indicator.visible = false

func is_player_detected() -> bool:
    return player_detected

func get_detection_info() -> Dictionary:
    return {
        "detected": player_detected,
        "range": detection_range,
        "angle": detection_angle,
        "last_known_position": detection_raycast.get_collision_point() if player_detected and detection_raycast else Vector3.ZERO
    }

# Debug visibility toggle functions
func set_detection_indicator_visible(visible: bool):
    show_detection_indicator = visible
    if detection_indicator:
        detection_indicator.visible = visible

func set_vision_cone_visible(visible: bool):
    show_vision_cone = visible
    if vision_cone_mesh:
        vision_cone_mesh.visible = visible
    elif visible:
        # Create it if it doesn't exist and we want to show it
        _create_vision_cone()

func toggle_detection_debug():
    set_detection_indicator_visible(!show_detection_indicator)
    set_vision_cone_visible(!show_vision_cone)

# Sound detection visualization
func _create_sound_detection_visualization():
    if not show_sound_detection_area:
        return
    
    sound_detection_sphere = MeshInstance3D.new()
    sound_detection_sphere.name = "SoundDetectionArea"
    
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 32
    sphere_mesh.rings = 16
    sphere_mesh.radius = sound_detection_radius
    sphere_mesh.height = sound_detection_radius * 2
    
    sound_detection_sphere.mesh = sphere_mesh
    
    # Create transparent material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0, 1, 1, 0.1)  # Cyan color for sound
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.no_depth_test = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    
    sound_detection_sphere.material_override = material
    sound_detection_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    
    add_child(sound_detection_sphere)

func _update_sound_detection_visualization():
    if not sound_detection_sphere:
        return
    
    sound_detection_sphere.visible = show_sound_detection_area and enable_sound_detection
    
    if sound_detection_sphere.visible:
        # Update size based on current detection radius
        var mesh = sound_detection_sphere.mesh as SphereMesh
        if mesh:
            mesh.radius = sound_detection_radius
            mesh.height = sound_detection_radius * 2
        
        # Update color based on detection state
        var mat = sound_detection_sphere.material_override as StandardMaterial3D
        if mat:
            if sound_detected:
                mat.albedo_color = Color(1, 1, 0, 0.2)  # Yellow when sound detected
            else:
                mat.albedo_color = Color(0, 1, 1, 0.1)  # Cyan normally

func _create_sound_waypoint_debug(position: Vector3):
    # Remove old debug sphere if it exists
    if sound_waypoint_debug:
        sound_waypoint_debug.queue_free()
    
    # Create new debug sphere
    sound_waypoint_debug = MeshInstance3D.new()
    sound_waypoint_debug.name = "SoundWaypointDebug"
    
    # Create sphere mesh
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 16
    sphere_mesh.rings = 8
    sphere_mesh.radius = 0.3
    sphere_mesh.height = 0.6
    
    sound_waypoint_debug.mesh = sphere_mesh
    
    # Create bright red material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0, 0, 1)  # Bright red
    material.emission_enabled = true
    material.emission = Color(1, 0, 0)
    material.emission_energy = 0.5
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    
    sound_waypoint_debug.material_override = material
    sound_waypoint_debug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    
    # Add to scene at investigation position
    get_tree().current_scene.add_child(sound_waypoint_debug)
    sound_waypoint_debug.global_position = position
    
    # Add a timer to remove it after investigation is done
    await get_tree().create_timer(sound_investigation_duration + 2.0).timeout
    if sound_waypoint_debug:
        sound_waypoint_debug.queue_free()

# Hide Saboteur Mode properties when can_be_saboteur is false
func _validate_property(property: Dictionary):
    # List of properties to hide when can_be_saboteur is false
    var saboteur_properties = [
        "enable_saboteur_behavior",
        "saboteur_detection_range",
        "vision_angle",
        "investigation_duration",
        "return_to_patrol_speed",
        "enable_sound_detection",
        "sound_detection_radius",
        "crouched_sound_radius_multiplier",
        "running_sound_radius_multiplier",
        "sound_investigation_duration",
        "show_sound_detection_area"
    ]
    
    # Hide saboteur properties if can_be_saboteur is false
    if property.name in saboteur_properties and not can_be_saboteur:
        property.usage = PROPERTY_USAGE_NO_EDITOR

# Saboteur detection system
func _check_for_saboteur_detection():
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return
    
    var distance = global_position.distance_to(player.global_position)
    
    # Check if in detection range
    if distance > saboteur_detection_range:
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

# Sound detection methods
func hear_sound(sound_position: Vector3, sound_radius: float):
    if not can_be_saboteur or not enable_sound_detection:
        return
    
    # Don't react to sounds if already investigating or in wrong state
    if current_state != MovementState.PATROL:
        return
    
    var distance = global_position.distance_to(sound_position)
    
    # Check if within hearing range
    if distance <= sound_radius:
        # Check line of sight to determine if it's a direct sound or muffled
        var space_state = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(
            global_position + Vector3.UP * 1.5,
            sound_position + Vector3.UP * 0.5
        )
        query.exclude = [self]
        query.collision_mask = 1  # Environment layer
        
        var result = space_state.intersect_ray(query)
        
        if result:
            # Sound is muffled by walls, slightly randomize investigation point
            var offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
            sound_position += offset
            print(npc_name + ": What was that noise?")
        else:
            print(npc_name + ": I heard something!")
        
        sound_detected = true
        is_investigating_sound = true
        set_state(MovementState.INVESTIGATE, sound_position)
        
        # Create debug sphere at investigation point
        _create_sound_waypoint_debug(sound_position)
