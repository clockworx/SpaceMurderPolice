extends Node
class_name SaboteurPatrolAI

@export var patrol_speed: float = 3.0
@export var chase_speed: float = 4.5
@export var detection_range: float = 6.0
@export var vision_angle: float = 45.0
@export var hearing_range: float = 8.0
@export var patrol_wait_time: float = 3.0

@export_group("Debug Visualization")
@export var show_awareness_sphere: bool = false
@export var show_vision_cone: bool = false
@export var show_state_indicators: bool = false
@export var show_patrol_path: bool = false
@export var show_sound_detection: bool = false

# Room patrol targets - simplified direct positions
var room_targets = {
    "Laboratory": Vector3(0, 0.144, 10),
    "MedicalBay": Vector3(43, 0.144, -3),
    "Security": Vector3(-14, 0.144, 10),
    "Engineering": Vector3(-45, 0.144, 11),
    "CrewQuarters": Vector3(-5, 0.144, -28),
    "Cafeteria": Vector3(6, 0.144, 4)
}

var current_target_room: String = ""
var target_position: Vector3
var npc_base: CharacterBody3D
var player: Node3D
var is_active: bool = false:
    get:
        return is_active

# Visualization nodes
var state_light: OmniLight3D
var state_label: Label3D
var vision_cone_mesh: MeshInstance3D
var sound_detection_sphere: MeshInstance3D

# States
enum State {
    PATROLLING,
    WAITING,
    INVESTIGATING,
    CHASING,
    SEARCHING,
    SABOTAGE
}

var current_state: State = State.PATROLLING
var wait_timer: float = 0.0
var stuck_timer: float = 0.0
var last_position: Vector3

signal player_spotted(player_position: Vector3)
signal player_lost()
signal state_changed(new_state: State)

func _ready():
    npc_base = get_parent() as CharacterBody3D
    if not npc_base:
        push_error("SaboteurPatrolAI must be child of CharacterBody3D")
        return
    
    add_to_group("riley_patrol")
    
    # Wait for scene to be ready
    await get_tree().physics_frame
    
    # Find player
    player = get_tree().get_first_node_in_group("player")
    
    # Start inactive
    set_physics_process(false)
    is_active = false
    
    last_position = npc_base.global_position
    
    print("SaboteurPatrolAI: Ready on ", npc_base.name, " at ", npc_base.global_position)

func _physics_process(delta):
    if not is_active or not npc_base:
        return
    
    # Update visualization positions
    if state_light:
        state_light.global_position = npc_base.global_position + Vector3.UP * 2.5
    if state_label:
        state_label.global_position = npc_base.global_position + Vector3.UP * 3.0
    
    # Handle current state
    match current_state:
        State.PATROLLING:
            _handle_patrolling(delta)
        State.WAITING:
            _handle_waiting(delta)
        State.INVESTIGATING:
            _handle_investigating(delta)
        State.CHASING:
            _handle_chasing(delta)
        State.SEARCHING:
            _handle_searching(delta)
        State.SABOTAGE:
            _handle_sabotage(delta)
    
    # Check if stuck (only when patrolling)
    if current_state == State.PATROLLING and npc_base.velocity.length() > 0.1:
        var movement = npc_base.global_position.distance_to(last_position)
        if movement < 0.05:  # Moving but not actually changing position much
            stuck_timer += delta
            if stuck_timer > 3.0:  # Give more time before declaring stuck
                print("SaboteurPatrolAI: Stuck detected, choosing new target")
                _choose_new_patrol_target()
                stuck_timer = 0.0
        else:
            stuck_timer = 0.0
    
    # Always update last position
    last_position = npc_base.global_position

func _handle_patrolling(delta):
    if target_position == Vector3.ZERO:
        _choose_new_patrol_target()
        return
    
    # Move directly towards target
    var direction = (target_position - npc_base.global_position).normalized()
    direction.y = 0  # Keep movement horizontal
    
    # Check if reached target
    var distance_to_target = npc_base.global_position.distance_to(target_position)
    if distance_to_target < 2.0:
        print("SaboteurPatrolAI: Reached ", current_target_room)
        _change_state(State.WAITING)
        wait_timer = 0.0
        return
    
    # Apply movement
    npc_base.velocity.x = direction.x * patrol_speed
    npc_base.velocity.z = direction.z * patrol_speed
    
    # Apply gravity
    if not npc_base.is_on_floor():
        npc_base.velocity.y -= 9.8 * delta
    else:
        npc_base.velocity.y = 0
    
    # Debug: Check velocity before move_and_slide
    var velocity_before = npc_base.velocity
    
    npc_base.move_and_slide()
    
    # Debug: Check if velocity was reset
    if velocity_before.length() > 0.1 and npc_base.velocity.length() < 0.1:
        print("WARNING: Velocity was reset! Before: ", velocity_before, " After: ", npc_base.velocity)
    
    # Rotate to face movement direction
    if direction.length() > 0.1:
        var target_rotation = atan2(-direction.x, -direction.z)
        npc_base.rotation.y = lerp_angle(npc_base.rotation.y, target_rotation, 4.0 * delta)
    
    # Check for doors
    _check_for_doors()
    
    # Debug output
    if Engine.get_physics_frames() % 60 == 0:  # Every second
        print("SaboteurPatrolAI: Moving to ", current_target_room, " (", distance_to_target, "m away)")
        print("  Position: ", npc_base.global_position, " Velocity: ", npc_base.velocity)

func _handle_waiting(delta):
    wait_timer += delta
    if wait_timer >= patrol_wait_time:
        wait_timer = 0.0
        _choose_new_patrol_target()
        _change_state(State.PATROLLING)

func _handle_investigating(delta):
    wait_timer += delta
    if wait_timer >= patrol_wait_time:
        wait_timer = 0.0
        _change_state(State.PATROLLING)

func _handle_chasing(delta):
    # TODO: Implement chasing behavior
    _change_state(State.PATROLLING)

func _handle_searching(delta):
    # TODO: Implement searching behavior
    _change_state(State.PATROLLING)

func _handle_sabotage(delta):
    # TODO: Implement sabotage behavior
    _change_state(State.PATROLLING)

func _choose_new_patrol_target():
    # Get list of rooms excluding current
    var available_rooms = []
    for room_name in room_targets:
        if room_name != current_target_room:
            available_rooms.append(room_name)
    
    # Pick random room
    if available_rooms.is_empty():
        available_rooms = room_targets.keys()
    
    var new_room = available_rooms[randi() % available_rooms.size()]
    current_target_room = new_room
    target_position = room_targets[new_room]
    
    print("SaboteurPatrolAI: New target - ", new_room, " at ", target_position)

func _check_for_doors():
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 1.0
    
    # Check multiple directions
    var directions = []
    if npc_base.velocity.length() > 0.1:
        directions.append(npc_base.velocity.normalized())
    directions.append(-npc_base.global_transform.basis.z)
    
    for direction in directions:
        for distance in [1.5, 2.5, 3.5]:
            var to = from + direction * distance
            
            var query = PhysicsRayQueryParameters3D.create(from, to)
            query.collision_mask = 2  # Interactable layer
            query.exclude = [npc_base]
            
            var result = space_state.intersect_ray(query)
            if result and result.collider.has_method("interact"):
                if result.collider.has_method("get_interaction_prompt"):
                    var prompt = result.collider.get_interaction_prompt()
                    if "door" in prompt.to_lower():
                        print("SaboteurPatrolAI: Opening door")
                        result.collider.interact()
                        return

func _change_state(new_state: State):
    current_state = new_state
    state_changed.emit(new_state)
    
    print("SaboteurPatrolAI: State -> ", State.keys()[new_state])
    
    # Update visualization
    _update_state_visualization()

func _update_state_visualization():
    if not state_light or not state_label:
        return
    
    match current_state:
        State.CHASING:
            state_light.light_color = Color.RED
            state_light.light_energy = 3.0
            state_label.text = "CHASING"
            state_label.modulate = Color.RED
        State.INVESTIGATING:
            state_light.light_color = Color.YELLOW
            state_light.light_energy = 2.5
            state_label.text = "INVESTIGATING"
            state_label.modulate = Color.YELLOW
        State.SEARCHING:
            state_light.light_color = Color.ORANGE
            state_light.light_energy = 2.5
            state_label.text = "SEARCHING"
            state_label.modulate = Color.ORANGE
        State.WAITING:
            state_light.light_color = Color.CYAN
            state_light.light_energy = 1.5
            state_label.text = "WAITING"
            state_label.modulate = Color.CYAN
        State.SABOTAGE:
            state_light.light_color = Color.MAGENTA
            state_light.light_energy = 1.0
            state_label.text = "SABOTAGE"
            state_label.modulate = Color.MAGENTA
        _:  # PATROLLING
            state_light.light_color = Color.GREEN
            state_light.light_energy = 2.0
            state_label.text = "PATROLLING"
            state_label.modulate = Color.GREEN

func set_active(active: bool):
    if is_active == active:
        return
    
    is_active = active
    set_physics_process(active)
    
    print("SaboteurPatrolAI: Active = ", active)
    
    if active:
        # Disable NPC base class physics processing to prevent conflicts
        npc_base.set_physics_process(false)
        print("SaboteurPatrolAI: Disabled NPC base physics processing")
        
        # Clear any existing velocity
        npc_base.velocity = Vector3.ZERO
        
        # Disable any NPC schedule
        if npc_base.has_method("stop_movement"):
            npc_base.stop_movement()
        if "use_schedule" in npc_base:
            npc_base.use_schedule = false
        if "is_moving" in npc_base:
            npc_base.is_moving = false
        
        # Clear any waypoint paths from the base NPC
        if npc_base.has_method("clear_waypoint_path"):
            npc_base.clear_waypoint_path()
        
        # Create visualizations if needed
        if not state_light:
            _create_state_indicators()
        
        # Update visibility
        if state_light:
            state_light.visible = show_state_indicators
        if state_label:
            state_label.visible = show_state_indicators
        
        # Start patrolling
        _choose_new_patrol_target()
        _change_state(State.PATROLLING)
    else:
        # Re-enable NPC base physics processing
        npc_base.set_physics_process(true)
        
        # Hide visualizations
        if state_light:
            state_light.visible = false
        if state_label:
            state_label.visible = false

func _create_state_indicators():
    # Create overhead light
    state_light = OmniLight3D.new()
    state_light.light_color = Color.GREEN
    state_light.light_energy = 2.0
    state_light.omni_range = 5.0
    state_light.visible = show_state_indicators
    get_tree().current_scene.add_child(state_light)
    
    # Create label
    state_label = Label3D.new()
    state_label.text = "PATROLLING"
    state_label.modulate = Color.GREEN
    state_label.font_size = 12
    state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    state_label.no_depth_test = true
    state_label.fixed_size = true
    state_label.visible = show_state_indicators
    get_tree().current_scene.add_child(state_label)

func _create_awareness_visualization():
    if show_awareness_sphere or show_vision_cone:
        # Create vision cone
        vision_cone_mesh = MeshInstance3D.new()
        vision_cone_mesh.name = "VisionCone"
        
        # Simple cone mesh
        var cone_mesh = CylinderMesh.new()
        cone_mesh.height = detection_range
        cone_mesh.top_radius = 0.1
        cone_mesh.bottom_radius = detection_range * tan(deg_to_rad(vision_angle / 2.0))
        vision_cone_mesh.mesh = cone_mesh
        
        # Semi-transparent material
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(1, 1, 0, 0.2)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        vision_cone_mesh.material_override = mat
        
        vision_cone_mesh.rotation.x = -PI/2
        vision_cone_mesh.position.z = -detection_range/2
        vision_cone_mesh.position.y = 1.6
        vision_cone_mesh.visible = show_vision_cone
        
        npc_base.add_child(vision_cone_mesh)

func _create_sound_detection_visualization():
    if show_sound_detection:
        sound_detection_sphere = MeshInstance3D.new()
        sound_detection_sphere.name = "SoundDetection"
        
        var sphere = SphereMesh.new()
        sphere.radius = hearing_range
        sphere.height = hearing_range * 2
        sound_detection_sphere.mesh = sphere
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0, 0.7, 1, 0.2)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        sound_detection_sphere.material_override = mat
        
        sound_detection_sphere.visible = show_sound_detection
        npc_base.add_child(sound_detection_sphere)

func set_debug_visualization(awareness: bool, vision: bool, state: bool, path: bool, sound: bool):
    show_awareness_sphere = awareness
    show_vision_cone = vision
    show_state_indicators = state
    show_patrol_path = path
    show_sound_detection = sound
    
    # Create visualizations if needed
    if (awareness or vision) and not vision_cone_mesh:
        _create_awareness_visualization()
    if sound and not sound_detection_sphere:
        _create_sound_detection_visualization()
    if state and not state_light:
        _create_state_indicators()
    
    # Update visibility
    if vision_cone_mesh:
        vision_cone_mesh.visible = vision and is_active
    if sound_detection_sphere:
        sound_detection_sphere.visible = sound and is_active
    if state_light:
        state_light.visible = state and is_active
    if state_label:
        state_label.visible = state and is_active

func investigate_position(pos: Vector3):
    target_position = pos
    _change_state(State.INVESTIGATING)
    wait_timer = 0.0

func on_sound_heard(position: Vector3):
    # Temporarily disabled to prevent movement interruption
    return
    
    if not is_active or current_state == State.CHASING:
        return
    
    var distance = npc_base.global_position.distance_to(position)
    if distance <= hearing_range:
        print("SaboteurPatrolAI: Investigating sound")
        investigate_position(position)
