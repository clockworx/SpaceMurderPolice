@tool
extends CharacterBody3D
class_name NPCBase

# Movement systems disabled for now

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

@export_group("Schedule")
@export var use_schedule: bool = true  # Enable schedule-based movement by default
@export var current_scheduled_room: String = "":  # Display current scheduled room
    get:
        if schedule_manager:
            var room = schedule_manager.get_npc_scheduled_room(npc_name)
            return schedule_manager.get_room_name(room)
        return ""
    set(value):
        pass  # Read-only

@export_group("Waypoint Settings")
@export var use_waypoints: bool = false
@export var waypoint_nodes: Array[Node3D] = []
@export var waypoint_reach_distance: float = 0.3  # Distance to consider waypoint reached
@export var pause_at_waypoints: bool = true
@export var pause_duration_min: float = 2.0
@export var pause_duration_max: float = 5.0
@export var show_current_waypoint_index: int = -1:  # Read-only display of current waypoint
    get:
        return current_waypoint_index
    set(value):
        pass  # Read-only

@export_group("State Settings")
@export var current_state: MovementState = MovementState.PATROL
@export var debug_state_changes: bool = false  # Print state changes
@export var show_state_label: bool = true  # Show state label above NPC
@export var react_to_player_proximity: bool = true  # Auto change states based on player distance
@export var idle_trigger_distance: float = 3.0  # Distance to stop and idle
@export var talk_trigger_distance: float = 2.0  # Distance to face player

@export_group("Movement System")
@export var use_waypoint_movement: bool = true  # Use pure waypoint-based movement

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
var schedule_manager: ScheduleManager
var waypoint_network_manager: WaypointNetworkManager
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

# Simple waypoint movement system
var is_moving: bool = false
var movement_speed: float = 3.0
var target_position: Vector3

# Movement tracking for visualization
var current_target_indicator: MeshInstance3D
var current_path_line: MeshInstance3D
var last_visualized_target: Vector3 = Vector3.ZERO

# Path visualization
var path_line: Node3D
var path_spheres: Array[MeshInstance3D] = []

# Waypoint navigation variables
var waypoint_path: Array[Vector3] = []
var waypoint_path_index: int = 0
var was_navigating_before_interrupt: bool = false

func _ready():
    if Engine.is_editor_hint():
        return
        
    collision_layer = 2  # Interactable layer
    collision_mask = 1   # Collide with environment
    
    # Add to npcs group for easy finding
    add_to_group("npcs")
    
    # Initialize waypoint movement system
    _setup_waypoint_movement()
    
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
    
    # Get waypoint network manager
    waypoint_network_manager = get_tree().get_first_node_in_group("waypoint_network_manager")
    
    # Defer schedule manager lookup to ensure it exists
    call_deferred("_setup_schedule_manager")
    
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
    
    # Setup keyboard navigation test
    if npc_name == "Dr. Marcus Webb":
        # print("=== NAVIGATION TEST READY FOR ", npc_name, " ===")
        set_process_input(true)

func _input(event):
    # Test navigation with keyboard
    if npc_name == "Dr. Marcus Webb" and event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                navigate_to_room("Laboratory_Center")
            KEY_2:
                navigate_to_room("MedicalBay_Center")
            KEY_3:
                navigate_to_room("Security_Center")
            KEY_4:
                navigate_to_room("Engineering_Center")
            KEY_5:
                navigate_to_room("CrewQuarters_Center")
            KEY_6:
                navigate_to_room("Cafeteria_Center")
            KEY_P:
                # Toggle waypoint path visualization
                _visualize_waypoint_path()
                # print("Waypoint path visualization updated")

func _physics_process(delta):
    if Engine.is_editor_hint():
        return
    
    # Handle dialogue facing
    if is_talking:
        if face_player_when_talking:
            var player = get_tree().get_first_node_in_group("player")
            if player:
                var look_position = player.global_position
                look_position.y = global_position.y
                look_at(look_position, Vector3.UP)
                rotation.x = 0
                rotation.z = 0
        return
    
    # Check player proximity for state changes
    if react_to_player_proximity:
        _check_player_proximity()
    
    # Handle state-specific behavior
    match current_state:
        MovementState.TALK:
            # Face the talk target position
            if talk_target_position != Vector3.ZERO:
                var look_pos = talk_target_position
                look_pos.y = global_position.y
                var direction = (look_pos - global_position).normalized()
                if direction.length() > 0.1:
                    var target_rotation = atan2(-direction.x, -direction.z)
                    rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)
    
    # Handle movement
    if is_moving:
        _handle_waypoint_movement(delta)
    else:
        # Apply gravity when not moving
        if not is_on_floor():
            velocity.y -= 9.8 * delta
        else:
            velocity.y = 0
        velocity.x = 0
        velocity.z = 0
        move_and_slide()

# Simple waypoint movement system
func _setup_waypoint_movement():
    # print(npc_name, ": Waypoint movement system ready - Use keys 1-6 to test movement")
    pass

func navigate_to_room(room_waypoint_name: String):
    # print(npc_name, ": navigate_to_room called with ", room_waypoint_name)
    
    # Use waypoint network manager to get path
    if not waypoint_network_manager:
        waypoint_network_manager = get_tree().get_first_node_in_group("waypoint_network_manager")
    
    if not waypoint_network_manager:
        # print("  ERROR: No waypoint network manager found")
        return false
    
    # Debug: Print current position when navigating
    # print("  Current position: ", global_position)
    # print("  Waypoint network manager exists: ", waypoint_network_manager != null)
    
    # Note: Cafeteria is an open area, so no special door handling needed
    
    # Get path from current position to target room
    var path = waypoint_network_manager.get_path_to_room(global_position, room_waypoint_name)
    if path.is_empty():
        print("  ERROR: No path found to ", room_waypoint_name)
        print("  Available waypoints: ", waypoint_network_manager.waypoint_nodes.keys())
        return false
    
    # Debug: Check if NPCs are using doors when leaving rooms
    if path.size() > 1:
        var first_waypoint = path[0]
        if first_waypoint.ends_with("_Center") and not path[1].contains("Door"):
            print("  WARNING: ", npc_name, " not using door to exit ", first_waypoint, "! Next waypoint: ", path[1])
    
    
    # The waypoint network should now handle cafeteria to lab paths efficiently
    
    # Clear any existing path first
    _clear_path_visualization()
    
    # Set up waypoint path
    waypoint_path = path
    waypoint_path_index = 0
    is_moving = true
    
    # Path visualization will show the route
    
    _visualize_waypoint_path()
    
    return true

func _handle_waypoint_movement(delta):
    if waypoint_path.is_empty() or waypoint_path_index >= waypoint_path.size():
        is_moving = false
        _on_waypoint_navigation_finished()
        return
    
    # Get current target waypoint
    var current_waypoint = waypoint_path[waypoint_path_index]
    var direction = (current_waypoint - global_position).normalized()
    
    # Update current target visualization
    _update_current_target_visualization(current_waypoint)
    
    # Check if we've reached current waypoint
    var distance_to_waypoint = global_position.distance_to(current_waypoint)
    if distance_to_waypoint <= waypoint_reach_distance:
        waypoint_path_index += 1
        if waypoint_path_index >= waypoint_path.size():
            is_moving = false
            _on_waypoint_navigation_finished()
            return
        # Move to next waypoint
        current_waypoint = waypoint_path[waypoint_path_index]
        direction = (current_waypoint - global_position).normalized()
        _update_current_target_visualization(current_waypoint)
    
    # Move towards target
    velocity.x = direction.x * movement_speed
    velocity.z = direction.z * movement_speed
    
    # Apply gravity
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0
    
    move_and_slide()
    
    # Rotate to face movement direction
    if direction.length() > 0.1:
        var target_rotation = atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)

func _on_waypoint_navigation_finished():
    # print(npc_name, ": Waypoint navigation completed!")
    is_moving = false
    velocity = Vector3.ZERO
    _clear_path_visualization()
    
    # If using schedule, pause in the room before moving to next location
    if use_schedule and schedule_manager:
        # Wait 5 seconds before checking schedule again
        await get_tree().create_timer(5.0).timeout
        
        # After pause, pick a new room to visit
        if use_schedule:  # Double-check in case it was disabled during wait
            _pick_random_room_to_visit()

func _visualize_waypoint_path():
    # Clear existing visualization
    _clear_path_visualization()
    
    if waypoint_path.is_empty():
        # print("  No waypoint path available for visualization")
        return
    
    # print("  Waypoint path has ", waypoint_path.size(), " points:")
    # for i in range(waypoint_path.size()):
        # print("    Point ", i, ": ", waypoint_path[i])
    
    # Create path spheres at each waypoint
    for i in range(waypoint_path.size()):
        var sphere = MeshInstance3D.new()
        sphere.mesh = SphereMesh.new()
        sphere.mesh.radius = 0.5  # Larger spheres for better visibility
        sphere.mesh.height = 1.0
        
        # Create material - red for start, green for end, blue for middle, purple for current target
        var material = StandardMaterial3D.new()
        if i == 0:
            material.albedo_color = Color.RED  # Start point
        elif i == waypoint_path.size() - 1:
            material.albedo_color = Color.GREEN  # End point
        elif i == waypoint_path_index:
            material.albedo_color = Color.PURPLE  # Current target waypoint
        else:
            material.albedo_color = Color.BLUE  # Waypoint points
        
        material.emission_enabled = true
        material.emission = material.albedo_color
        material.emission_energy = 1.0  # Brighter emission
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.albedo_color.a = 0.8  # Slightly transparent
        sphere.material_override = material
        
        # Position the sphere higher for better visibility
        get_tree().current_scene.add_child(sphere)
        sphere.global_position = waypoint_path[i] + Vector3(0, 1.0, 0)  # Raise 1 unit up
        path_spheres.append(sphere)
        
        # Add a label showing waypoint number
        var label = Label3D.new()
        label.text = str(i + 1)
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        label.font_size = 24
        label.outline_size = 4
        label.position.y = 1.2  # Above the sphere
        sphere.add_child(label)
    
    # Create lines between waypoints
    for i in range(waypoint_path.size() - 1):
        var line_mesh = MeshInstance3D.new()
        var array_mesh = ArrayMesh.new()
        var arrays = []
        arrays.resize(Mesh.ARRAY_MAX)
        
        var vertices = PackedVector3Array()
        var start_pos = waypoint_path[i] + Vector3(0, 1.0, 0)
        var end_pos = waypoint_path[i + 1] + Vector3(0, 1.0, 0)
        
        # Create a thick line using multiple vertices
        var direction = (end_pos - start_pos).normalized()
        var perpendicular = Vector3.UP.cross(direction).normalized() * 0.1
        
        vertices.append(start_pos + perpendicular)
        vertices.append(start_pos - perpendicular)
        vertices.append(end_pos + perpendicular)
        vertices.append(end_pos - perpendicular)
        
        var indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
        
        arrays[Mesh.ARRAY_VERTEX] = vertices
        arrays[Mesh.ARRAY_INDEX] = indices
        
        array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
        line_mesh.mesh = array_mesh
        
        # Create bright yellow material for lines
        var line_material = StandardMaterial3D.new()
        line_material.albedo_color = Color.YELLOW
        line_material.emission_enabled = true
        line_material.emission = Color.YELLOW
        line_material.emission_energy = 0.8
        line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        line_material.albedo_color.a = 0.9
        line_mesh.material_override = line_material
        
        get_tree().current_scene.add_child(line_mesh)
        path_spheres.append(line_mesh)  # Add to cleanup list


func _clear_path_visualization():
    # Remove all path spheres
    for sphere in path_spheres:
        if is_instance_valid(sphere):
            sphere.queue_free()
    path_spheres.clear()
    
    # Clear current target visualization
    if current_target_indicator:
        current_target_indicator.queue_free()
        current_target_indicator = null
    
    if current_path_line:
        current_path_line.queue_free()
        current_path_line = null

func _update_current_target_visualization(target_pos: Vector3):
    # Ensure we're in the scene tree
    if not is_inside_tree():
        return
    
    # Only update if target has changed significantly
    if last_visualized_target.distance_to(target_pos) < 0.1:
        return
    
    last_visualized_target = target_pos
        
    # Remove old visualizations immediately
    if current_target_indicator and is_instance_valid(current_target_indicator):
        if current_target_indicator.get_parent():
            current_target_indicator.get_parent().remove_child(current_target_indicator)
        current_target_indicator.queue_free()
        current_target_indicator = null
    if current_path_line and is_instance_valid(current_path_line):
        if current_path_line.get_parent():
            current_path_line.get_parent().remove_child(current_path_line)
        current_path_line.queue_free()
        current_path_line = null
    
    # print("Creating red line from ", global_position, " to ", target_pos)
    
    # Clean up old indicator if it exists
    if current_target_indicator and is_instance_valid(current_target_indicator):
        current_target_indicator.queue_free()
        current_target_indicator = null
    
    # Create target indicator - bright orange sphere
    current_target_indicator = MeshInstance3D.new()
    current_target_indicator.mesh = SphereMesh.new()
    current_target_indicator.mesh.radius = 0.6
    current_target_indicator.mesh.height = 1.2
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.ORANGE
    material.emission_enabled = true
    material.emission = Color.ORANGE
    material.emission_energy = 2.0
    current_target_indicator.material_override = material
    
    if current_target_indicator.get_parent():
        current_target_indicator.get_parent().remove_child(current_target_indicator)
    get_tree().current_scene.add_child(current_target_indicator)
    current_target_indicator.global_position = target_pos + Vector3(0, 1.5, 0)
    
    # Clean up old path line if it exists  
    if current_path_line and is_instance_valid(current_path_line):
        current_path_line.queue_free()
        current_path_line = null
    
    # Create RED LINE using a simple cylinder approach
    current_path_line = MeshInstance3D.new()
    current_path_line.mesh = CylinderMesh.new()
    current_path_line.mesh.top_radius = 0.2
    current_path_line.mesh.bottom_radius = 0.2
    
    var start_pos = global_position + Vector3(0, 1.0, 0)
    var end_pos = target_pos + Vector3(0, 1.0, 0)
    var distance = start_pos.distance_to(end_pos)
    var midpoint = (start_pos + end_pos) / 2.0
    
    current_path_line.mesh.height = distance
    
    # Add the line to the scene before setting position
    if current_path_line.get_parent():
        current_path_line.get_parent().remove_child(current_path_line)
    get_tree().current_scene.add_child(current_path_line)
    current_path_line.global_position = midpoint
    
    # Point the cylinder toward the target
    var direction = (end_pos - start_pos).normalized()
    if direction.length() > 0.1:
        # Calculate the rotation needed to point the cylinder along the direction
        var transform_basis = Basis.looking_at(direction, Vector3.UP)
        current_path_line.transform.basis = transform_basis
        # Rotate cylinder to align with its length axis (cylinder points along Y by default)
        current_path_line.rotate_object_local(Vector3.RIGHT, PI/2)
    
    # Bright red material for the line
    var line_material = StandardMaterial3D.new()
    line_material.albedo_color = Color.RED
    line_material.emission_enabled = true
    line_material.emission = Color.RED
    line_material.emission_energy = 3.0  # Very bright
    line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    current_path_line.material_override = line_material
    
    # Check if already has a parent before adding
    if current_path_line.get_parent():
        current_path_line.get_parent().remove_child(current_path_line)
    get_tree().current_scene.add_child(current_path_line)
    # print("Red line created with distance: ", distance)

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
    # For direct position movement, create a simple path
    waypoint_path = [position]
    waypoint_path_index = 0
    is_moving = true
    # print(npc_name, ": Moving to position ", position)

func stop_movement() -> void:
    is_moving = false
    velocity = Vector3.ZERO

func force_move_to_position(position: Vector3) -> void:
    move_to_position(position)

func _re_enable_waypoints(delay: float = 0.0):
    if delay > 0:
        await get_tree().create_timer(delay).timeout
    use_waypoints = true

# Movement system signal handlers
# Movement callbacks disabled - NPCs are stationary

# Waypoint callbacks disabled - NPCs are stationary

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

# State handler functions removed - NPCs are stationary

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
        dialogue_ui.start_dialogue(self)
    else:
        print("Warning: No dialogue UI found in 'dialogue_ui' group")

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
        # print(npc_name + " state changed to: ", MovementState.keys()[new_state])
        pass
    
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
        # Track if we were navigating
        if is_moving and not was_navigating_before_interrupt:
            was_navigating_before_interrupt = true
        # Stop any ongoing movement
        is_moving = false
        velocity = Vector3.ZERO
        set_talk_state(player.global_position)
    elif distance <= idle_trigger_distance:
        # Track if we were navigating
        if is_moving and not was_navigating_before_interrupt:
            was_navigating_before_interrupt = true
        # Stop any ongoing movement
        is_moving = false
        velocity = Vector3.ZERO
        set_idle_state()
    else:
        # Player is out of range
        if was_navigating_before_interrupt and not is_moving:
            # Resume navigation
            was_navigating_before_interrupt = false
            if waypoint_path.size() > 0 and waypoint_path_index < waypoint_path.size():
                is_moving = true
                set_patrol_state()  # Return to patrol state

# Waypoint functions
func _update_waypoint_target():
    if waypoint_nodes.size() == 0:
        return
        
    var current_waypoint = waypoint_nodes[current_waypoint_index]
    if is_instance_valid(current_waypoint):
        waypoint_target = current_waypoint.global_position
        # Always ignore Y - NPCs stay at ground level
        waypoint_target.y = global_position.y

# Stuck detection removed - NPCs are stationary

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
        # print(npc_name + ": Who's there? I see you!")
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
            # print(npc_name + ": What was that noise?")
            pass
        else:
            # print(npc_name + ": I heard something!")
            pass
        
        sound_detected = true
        is_investigating_sound = true
        set_state(MovementState.INVESTIGATE, sound_position)
        
        # Create debug sphere at investigation point
        _create_sound_waypoint_debug(sound_position)

func _on_schedule_changed(character_name: String, new_room: ScheduleManager.Room):
    if character_name != npc_name:
        return
    
    if not use_schedule:
        return
    
    # Get the waypoint for the scheduled room
    var waypoint_name = schedule_manager.get_room_waypoint_name(new_room)
    if waypoint_name.is_empty():
        # print("Warning: No waypoint defined for room ", schedule_manager.get_room_name(new_room))
        return
    
    # Navigate to the new scheduled room
    assigned_room = schedule_manager.get_room_name(new_room)
    
    # Check if we're already heading to this room to avoid duplicate navigation
    if assigned_room == schedule_manager.get_room_name(new_room) and is_moving:
        return
    
    # Use the waypoint name with _Center suffix for all rooms
    var room_center_waypoint = waypoint_name.replace("_Waypoint", "_Center")
    
    print(npc_name + ": Schedule changed - heading to " + assigned_room + " (waypoint: " + room_center_waypoint + ")")
    
    # Navigate to the scheduled room
    if not navigate_to_room(room_center_waypoint):
        print(npc_name + ": Failed to navigate to " + room_center_waypoint)

# Navigation functions disabled - NPCs are stationary

func _pick_random_room_to_visit():
    # For now, just visit rooms randomly
    var rooms = [
        "Laboratory_Center",
        "MedicalBay_Center", 
        "Security_Center",
        "Engineering_Center",
        "CrewQuarters_Center",
        "Cafeteria_Center"
    ]
    
    # Remove current room from options
    var current_pos = global_position
    var current_room_waypoint = waypoint_network_manager._find_nearest_waypoint(current_pos)
    
    # Filter out the current room
    var available_rooms = []
    for room in rooms:
        if not current_room_waypoint.begins_with(room.split("_")[0]):
            available_rooms.append(room)
    
    # Pick a random room
    if available_rooms.size() > 0:
        var random_room = available_rooms[randi() % available_rooms.size()]
        print(npc_name + ": Deciding to visit " + random_room)
        navigate_to_room(random_room)

# Getters for external systems

func get_waypoint_path() -> Array[Vector3]:
    return waypoint_path

func _initial_schedule_check():
    if not schedule_manager or not use_schedule:
        return
    
    # Wait for waypoint network to be initialized
    await get_tree().create_timer(0.1).timeout
    
    # Ensure waypoint network manager is available
    if not waypoint_network_manager:
        waypoint_network_manager = get_tree().get_first_node_in_group("waypoint_network_manager")
        if not waypoint_network_manager:
            print(npc_name + ": ERROR - No waypoint network manager found!")
            return
    
    # Check waypoint availability and perform schedule check
    if waypoint_network_manager.waypoint_nodes.size() > 0:
        print(npc_name + ": Schedule initialized (network ready with " + str(waypoint_network_manager.waypoint_nodes.size()) + " waypoints)")
    
    schedule_manager.update_npc_schedule(npc_name)

func _setup_schedule_manager():
    # Get schedule manager
    schedule_manager = get_tree().get_first_node_in_group("schedule_manager")
    if schedule_manager:
        # print(npc_name + ": Found schedule manager (deferred)")
        pass
    else:
        # print(npc_name + ": No schedule manager found! (deferred)")
        # Try again after a short delay
        await get_tree().create_timer(0.5).timeout
        schedule_manager = get_tree().get_first_node_in_group("schedule_manager")
        if schedule_manager:
            # print(npc_name + ": Found schedule manager on second attempt")
            pass
        else:
            print(npc_name + ": ERROR: Still no schedule manager found!")
            return
    
    # Connect to schedule changes if manager exists
    if schedule_manager and schedule_manager.has_signal("schedule_changed"):
        schedule_manager.schedule_changed.connect(_on_schedule_changed)
        # print(npc_name + ": Connected to schedule manager. use_schedule = " + str(use_schedule))
        
        # If using schedule, check initial schedule
        if use_schedule:
            _initial_schedule_check()
