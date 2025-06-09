extends Node
class_name ImprovedNPCNavigation

@export var navigation_debug_enabled: bool = false
@export var avoidance_enabled: bool = true
@export var avoidance_radius: float = 1.5
@export var avoidance_strength: float = 5.0
@export var corner_detection_distance: float = 2.0
@export var stuck_detection_time: float = 2.0
@export var stuck_movement_threshold: float = 0.5

var npc_base: NPCBase
var navigation_agent: NavigationAgent3D
var awareness_mesh: MeshInstance3D
var stuck_timer: float = 0.0
var last_position: Vector3
var is_navigating: bool = false
var target_position: Vector3

signal navigation_finished()
signal got_stuck(position: Vector3)

func _ready():
    npc_base = get_parent()
    if not npc_base:
        push_error("ImprovedNPCNavigation must be child of NPCBase")
        return
    
    # Create NavigationAgent3D
    navigation_agent = NavigationAgent3D.new()
    navigation_agent.name = "NavigationAgent3D"
    navigation_agent.path_desired_distance = 0.5
    navigation_agent.target_desired_distance = 1.0
    navigation_agent.path_max_distance = 3.0
    navigation_agent.navigation_layers = 1
    navigation_agent.avoidance_enabled = avoidance_enabled
    navigation_agent.radius = 0.5
    navigation_agent.height = 1.8
    navigation_agent.neighbor_distance = 5.0
    navigation_agent.max_neighbors = 5
    navigation_agent.time_horizon_agents = 1.0
    navigation_agent.time_horizon_obstacles = 0.5
    navigation_agent.max_speed = 5.0
    navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
    
    npc_base.add_child(navigation_agent)
    
    # Connect navigation signals
    navigation_agent.velocity_computed.connect(_on_velocity_computed)
    navigation_agent.navigation_finished.connect(_on_navigation_finished)
    navigation_agent.link_reached.connect(_on_link_reached)
    
    # Create debug visualization
    if navigation_debug_enabled:
        _create_debug_visualization()
    
    # Initialize stuck detection
    last_position = npc_base.global_position

func _physics_process(delta):
    if not is_navigating:
        return
    
    # Update stuck detection
    _update_stuck_detection(delta)
    
    # Update debug visualization
    if navigation_debug_enabled and awareness_mesh:
        _update_debug_visualization()

func navigate_to(new_target_position: Vector3):
    if not navigation_agent:
        return
    
    is_navigating = true
    target_position = new_target_position
    navigation_agent.target_position = new_target_position
    stuck_timer = 0.0
    last_position = npc_base.global_position

func stop_navigation():
    is_navigating = false
    if navigation_agent:
        navigation_agent.set_velocity(Vector3.ZERO)

func get_next_velocity(_current_velocity: Vector3, speed: float) -> Vector3:
    if not navigation_agent or not is_navigating:
        return Vector3.ZERO
    
    if navigation_agent.is_navigation_finished():
        return Vector3.ZERO
    
    var next_path_position = navigation_agent.get_next_path_position()
    var direction = (next_path_position - npc_base.global_position).normalized()
    direction.y = 0
    
    var desired_velocity = direction * speed
    
    # Add obstacle avoidance
    if avoidance_enabled:
        desired_velocity = _apply_obstacle_avoidance(desired_velocity)
    
    # Set velocity for avoidance calculations
    navigation_agent.set_velocity(desired_velocity)
    
    return desired_velocity

func _apply_obstacle_avoidance(velocity: Vector3) -> Vector3:
    var space_state = npc_base.get_world_3d().direct_space_state
    var avoidance_vector = Vector3.ZERO
    
    # Cast rays in multiple directions for obstacle detection
    var ray_directions = [
        Vector3.FORWARD,
        Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(30)),
        Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(-30)),
        Vector3.RIGHT,
        Vector3.LEFT
    ]
    
    for dir in ray_directions:
        var world_dir = npc_base.global_transform.basis * dir
        var from = npc_base.global_position + Vector3.UP * 0.9
        var to = from + world_dir * corner_detection_distance
        
        var query = PhysicsRayQueryParameters3D.create(from, to)
        query.exclude = [npc_base]
        query.collision_mask = 1  # Environment layer
        
        var result = space_state.intersect_ray(query)
        if result:
            var distance = from.distance_to(result.position)
            var avoidance_force = (from - result.position).normalized()
            avoidance_force.y = 0
            avoidance_force *= (1.0 - distance / corner_detection_distance) * avoidance_strength
            avoidance_vector += avoidance_force
    
    return velocity + avoidance_vector

func _update_stuck_detection(delta):
    var movement = npc_base.global_position.distance_to(last_position)
    
    if movement < stuck_movement_threshold * delta:
        stuck_timer += delta
        if stuck_timer >= stuck_detection_time:
            _handle_stuck()
            stuck_timer = 0.0
    else:
        stuck_timer = 0.0
        last_position = npc_base.global_position

func _handle_stuck():
    print("NPC stuck at position: ", npc_base.global_position)
    got_stuck.emit(npc_base.global_position)
    
    # Try to unstuck by moving backwards slightly
    var backward = -npc_base.global_transform.basis.z * 1.0
    npc_base.global_position += backward
    
    # Recompute path
    if navigation_agent and is_navigating:
        navigation_agent.set_target_position(navigation_agent.target_position)

func _on_velocity_computed(safe_velocity: Vector3):
    if not npc_base:
        return
    
    # Apply the computed safe velocity
    npc_base.velocity = safe_velocity
    npc_base.move_and_slide()

func _on_navigation_finished():
    is_navigating = false
    navigation_finished.emit()

func _on_link_reached(details: Dictionary):
    # Handle navigation links (like doors or jumps)
    print("Navigation link reached: ", details)

func _create_debug_visualization():
    # Create awareness wireframe sphere
    awareness_mesh = MeshInstance3D.new()
    awareness_mesh.name = "AwarenessSphere"
    
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 16
    sphere_mesh.rings = 8
    sphere_mesh.radius = 5.0
    sphere_mesh.height = 10.0
    awareness_mesh.mesh = sphere_mesh
    
    # Create wireframe material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0, 1, 0, 0.3)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    material.wireframe = true
    material.no_depth_test = true
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    
    awareness_mesh.material_override = material
    awareness_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    
    npc_base.add_child(awareness_mesh)

func _update_debug_visualization():
    if not awareness_mesh:
        return
    
    # Update awareness sphere color based on state
    var material = awareness_mesh.material_override as StandardMaterial3D
    if not material:
        return
    
    # Get current state from parent if it has one
    var color = Color.GREEN
    if npc_base.has_method("get_current_state"):
        var state = npc_base.get_current_state()
        match state:
            "chasing":
                color = Color.RED
            "investigating":
                color = Color.YELLOW
            "searching":
                color = Color.ORANGE
            "sabotage":
                color = Color.MAGENTA
            _:
                color = Color.GREEN
    
    material.albedo_color = Color(color.r, color.g, color.b, 0.3)
    
    # Update awareness sphere size based on avoidance radius
    if awareness_mesh and awareness_mesh.mesh is SphereMesh:
        var sphere = awareness_mesh.mesh as SphereMesh
        sphere.radius = avoidance_radius
        sphere.height = avoidance_radius * 2

func set_debug_enabled(enabled: bool):
    navigation_debug_enabled = enabled
    if awareness_mesh:
        awareness_mesh.visible = enabled

func get_distance_to_target() -> float:
    if not navigation_agent:
        return 999999.0
    return navigation_agent.distance_to_target()

func is_target_reachable() -> bool:
    if not navigation_agent:
        return false
    return navigation_agent.is_target_reachable()

func has_path() -> bool:
    if not navigation_agent:
        return false
    return navigation_agent.has_path()

func open_nearby_doors():
    # Check for doors in front of the NPC
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 1.0
    var forward = -npc_base.global_transform.basis.z
    var to = from + forward * 2.5
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Interactable layer
    query.exclude = [npc_base]
    
    var result = space_state.intersect_ray(query)
    if result and result.collider.has_method("interact"):
        if result.collider.has_method("is_open") and not result.collider.is_open:
            print("Opening door for NPC navigation")
            result.collider.interact()
            # Wait a bit for door to open
            await npc_base.get_tree().create_timer(0.5).timeout
