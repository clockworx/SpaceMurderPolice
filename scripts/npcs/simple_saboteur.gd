extends CharacterBody3D
class_name SimpleSaboteur

# Simple standalone saboteur that doesn't fight with NPC base class

@export var patrol_speed: float = 3.0
@export var wait_time: float = 3.0
@export var gravity: float = 9.8

# Room targets for patrol
var room_targets = {
    "Laboratory": Vector3(0, 0.144, 10),
    "MedicalBay": Vector3(43, 0.144, -3),
    "Security": Vector3(-14, 0.144, 10),
    "Engineering": Vector3(-45, 0.144, 11),
    "CrewQuarters": Vector3(-5, 0.144, -28),
    "Cafeteria": Vector3(6, 0.144, 4)
}

var current_target: Vector3
var current_room: String = ""
var wait_timer: float = 0.0
var is_waiting: bool = false

# Visual elements
var mesh_instance: MeshInstance3D
var name_label: Label3D
var state_label: Label3D

func _ready():
    # Add to groups
    add_to_group("npcs")
    add_to_group("saboteur")
    
    # Get visual elements
    mesh_instance = get_node_or_null("MeshInstance3D")
    name_label = get_node_or_null("Head/NameLabel")
    var role_label = get_node_or_null("Head/RoleLabel")
    
    # Update appearance
    if name_label:
        name_label.text = "Unknown Figure"
    if role_label:
        role_label.visible = false
    
    # Dark appearance
    if mesh_instance:
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.1, 0.1, 0.1)
        material.emission_enabled = true
        material.emission = Color(0.8, 0.2, 0.2)
        material.emission_energy = 0.3
        mesh_instance.material_override = material
    
    # Create state label
    _create_state_label()
    
    # Start patrolling
    _pick_new_target()
    
    print("SimpleSaboteur: Initialized at ", global_position)

func _physics_process(delta):
    # Always apply gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0
    
    if is_waiting:
        # Handle waiting
        wait_timer += delta
        if wait_timer >= wait_time:
            is_waiting = false
            wait_timer = 0.0
            _pick_new_target()
            _update_state_label("PATROLLING")
    else:
        # Move toward target
        if current_target != Vector3.ZERO:
            var direction = (current_target - global_position).normalized()
            direction.y = 0  # Keep horizontal
            
            # Check if reached target
            var distance = global_position.distance_to(current_target)
            if distance < 2.0:
                print("SimpleSaboteur: Reached ", current_room)
                is_waiting = true
                velocity.x = 0
                velocity.z = 0
                _update_state_label("WAITING")
            else:
                # Apply movement
                velocity.x = direction.x * patrol_speed
                velocity.z = direction.z * patrol_speed
                
                # Rotate to face movement
                if direction.length() > 0.1:
                    rotation.y = atan2(-direction.x, -direction.z)
    
    # Actually move
    move_and_slide()
    
    # Check for doors
    _check_doors()
    
    # Update debug label position
    if state_label:
        state_label.global_position = global_position + Vector3.UP * 2.5

func _pick_new_target():
    # Get rooms excluding current
    var available = []
    for room in room_targets:
        if room != current_room:
            available.append(room)
    
    if available.is_empty():
        available = room_targets.keys()
    
    # Pick random room
    current_room = available[randi() % available.size()]
    current_target = room_targets[current_room]
    
    print("SimpleSaboteur: New target - ", current_room, " at ", current_target)

func _check_doors():
    # Simple door check
    var space_state = get_world_3d().direct_space_state
    var from = global_position + Vector3.UP
    var to = from - global_transform.basis.z * 2.5
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Interactables
    query.exclude = [self]
    
    var result = space_state.intersect_ray(query)
    if result and result.collider.has_method("interact"):
        if result.collider.has_method("get_interaction_prompt"):
            var prompt = result.collider.get_interaction_prompt()
            if "door" in prompt.to_lower():
                result.collider.interact()

func _create_state_label():
    state_label = Label3D.new()
    state_label.text = "PATROLLING"
    state_label.modulate = Color.GREEN
    state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    state_label.no_depth_test = true
    state_label.font_size = 16
    add_child(state_label)
    state_label.position = Vector3.UP * 2.5

func _update_state_label(state: String):
    if not state_label:
        return
    
    state_label.text = state
    match state:
        "WAITING":
            state_label.modulate = Color.CYAN
        "PATROLLING":
            state_label.modulate = Color.GREEN
        _:
            state_label.modulate = Color.WHITE