extends Node
class_name CleanSimpleNav

# Clean, simple navigation with NO interference

signal navigation_completed()
signal waypoint_reached(waypoint_name: String)

var character: CharacterBody3D
var current_path: Array = []
var current_index: int = 0
var is_active: bool = false

var movement_speed: float = 3.5
var reach_distance: float = 1.0
var door_reach_distance: float = 0.5

# Debug visualization
var debug_path_mesh: MeshInstance3D
var debug_spheres: Array = []
var debug_parent: Node3D

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
    
    # Build simple paths
    match room_name:
        "Security_Waypoint":
            # Direct path to security
            # First move to a clear position in the lab
            current_path = [
                Vector3(2.0, start_pos.y, 9.0),    # Clear position in lab
                Vector3(3.0, start_pos.y, 8.0),    # Approach door
                Vector3(3.67, start_pos.y, 7.9),   # Lab door center
                Vector3(3.67, start_pos.y, 6.0),   # Through door
                Vector3(3.67, start_pos.y, 5.0),   # Outside lab in hallway
                Vector3(0.0, start_pos.y, 5.0),    # Hallway center
                Vector3(-12.0, start_pos.y, 5.0),  # Near security
                Vector3(-12.95, start_pos.y, 5.9), # Security door
                Vector3(-12.3, start_pos.y, 8.0)   # Security center
            ]
        "MedicalBay_Waypoint":
            # Direct path to medical
            current_path = [
                Vector3(3.67, start_pos.y, 7.9),   # Lab door
                Vector3(3.67, start_pos.y, 5.0),   # Outside lab
                Vector3(15.0, start_pos.y, 5.0),   # East hallway
                Vector3(38.0, start_pos.y, 2.0),   # Medical door
                Vector3(40.2, start_pos.y, -2.3)   # Medical center
            ]
        "Laboratory_Waypoint":
            # Direct to lab
            current_path = [
                Vector3(0.0, start_pos.y, 10.0)    # Lab center
            ]
        _:
            print("  Unknown destination: ", room_name)
            return false
    
    print("  Path has ", current_path.size(), " waypoints")
    
    # Start navigation
    current_index = 0
    is_active = true
    set_physics_process(true)
    
    # Update debug visualization
    _update_debug_visualization()
    
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
    
    # Check if reached waypoint
    if distance <= reach_distance:
        print("  Reached waypoint ", current_index + 1, " at ", current_target)
        current_index += 1
        # Update debug visualization when reaching waypoint
        _update_debug_visualization()
        return
    
    # Debug: Print movement info every second
    if Engine.get_frames_drawn() % 60 == 0:
        print("  Moving to waypoint ", current_index + 1, "/", current_path.size())
        print("    Target: ", current_target)
        print("    Current pos: ", character.global_position)
        print("    Distance: ", distance)
    
    # Move towards target
    var direction = (current_target - character.global_position).normalized()
    direction.y = 0
    
    # Apply movement
    character.velocity = direction * movement_speed
    if not character.is_on_floor():
        character.velocity.y -= 9.8 * delta
    
    character.move_and_slide()
    
    # Update path visualization
    if debug_path_mesh:
        _update_path_line()
    
    # Rotate to face movement
    if direction.length() > 0.1:
        character.look_at(character.global_position + direction, Vector3.UP)
        character.rotation.x = 0

func is_navigating_active() -> bool:
    return is_active

func _setup_debug_visualization():
    # Create parent node for debug visuals at scene root level for better visibility
    debug_parent = Node3D.new()
    debug_parent.name = "NavigationDebug"
    character.get_tree().root.get_child(0).add_child(debug_parent)
    
    # Create mesh instance for path line
    debug_path_mesh = MeshInstance3D.new()
    debug_path_mesh.name = "PathLine"
    debug_path_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    debug_parent.add_child(debug_path_mesh)
    
    print("[DEBUG VIS] Setup complete")

func _update_debug_visualization():
    # Clear previous visualization
    _clear_debug_spheres()
    
    if not is_active or current_path.is_empty():
        return
    
    # Create path line
    _create_path_line()
    
    # Draw waypoint spheres
    for i in range(current_path.size()):
        _create_debug_sphere(i)

func _create_path_line():
    if not debug_path_mesh:
        return
        
    var array_mesh = ArrayMesh.new()
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    
    # Create vertices for line
    var vertices = PackedVector3Array()
    
    # Start from current position
    vertices.append(character.global_position)
    
    # Add remaining waypoints
    for i in range(current_index, current_path.size()):
        vertices.append(current_path[i])
    
    if vertices.size() < 2:
        return
    
    # Create line segments
    var line_vertices = PackedVector3Array()
    for i in range(vertices.size() - 1):
        line_vertices.append(vertices[i])
        line_vertices.append(vertices[i + 1])
    
    arrays[Mesh.ARRAY_VERTEX] = line_vertices
    
    # Create the mesh
    array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
    
    # Apply red material
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(1, 0, 0, 1)  # Red
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.vertex_color_use_as_albedo = false  # Don't use vertex colors
    mat.no_depth_test = true  # Always visible
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    
    debug_path_mesh.mesh = array_mesh
    debug_path_mesh.material_override = mat
    
    print("[DEBUG VIS] Created path with ", line_vertices.size() / 2, " segments")

func _update_path_line():
    # Recreate the path line with current position
    _create_path_line()

func _create_debug_sphere(index: int):
    var sphere = MeshInstance3D.new()
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 8
    sphere_mesh.rings = 4
    
    # Different sizes/colors for current waypoint
    if index == current_index:
        sphere_mesh.radius = 0.3
        sphere_mesh.height = 0.6
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0, 1, 0, 1)  # Green for current
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        sphere.material_override = mat
    elif index < current_index:
        sphere_mesh.radius = 0.15
        sphere_mesh.height = 0.3
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.5, 0.5, 0.5, 0.5)  # Gray for visited
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        sphere.material_override = mat
    else:
        sphere_mesh.radius = 0.2
        sphere_mesh.height = 0.4
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(1, 0, 0, 0.8)  # Red for future
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        sphere.material_override = mat
    
    sphere.mesh = sphere_mesh
    sphere.global_position = current_path[index]
    debug_parent.add_child(sphere)
    debug_spheres.append(sphere)

func _clear_debug_spheres():
    for sphere in debug_spheres:
        if is_instance_valid(sphere):
            sphere.queue_free()
    debug_spheres.clear()

func _clear_debug_visualization():
    _clear_debug_spheres()
    if debug_path_mesh and debug_path_mesh.mesh:
        debug_path_mesh.mesh = null
