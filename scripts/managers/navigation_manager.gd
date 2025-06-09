extends Node
class_name NavigationManager

@export var enable_debug_visualization: bool = false
@export var navigation_mesh_agent_radius: float = 0.5
@export var navigation_mesh_agent_height: float = 1.8
@export var navigation_mesh_cell_size: float = 0.25
@export var navigation_mesh_cell_height: float = 0.25

var navigation_region: NavigationRegion3D
var debug_instance: MeshInstance3D

signal navigation_ready()

func _ready():
    # Add to manager group
    add_to_group("navigation_manager")
    
    # Wait for scene to be ready
    await get_tree().process_frame
    
    # Setup navigation
    _setup_navigation_region()
    
    # Create debug visualization if enabled
    if enable_debug_visualization:
        _create_debug_visualization()

func _setup_navigation_region():
    # Find existing NavigationRegion3D or create one
    navigation_region = get_tree().get_first_node_in_group("navigation_region")
    
    if not navigation_region:
        print("NavigationManager: No NavigationRegion3D found, creating one")
        navigation_region = NavigationRegion3D.new()
        navigation_region.name = "NavigationRegion3D"
        navigation_region.add_to_group("navigation_region")
        
        # Create navigation mesh
        var nav_mesh = NavigationMesh.new()
        nav_mesh.agent_radius = navigation_mesh_agent_radius
        nav_mesh.agent_height = navigation_mesh_agent_height
        nav_mesh.agent_max_climb = 0.5
        nav_mesh.agent_max_slope = 45.0
        nav_mesh.cell_size = navigation_mesh_cell_size
        nav_mesh.cell_height = navigation_mesh_cell_height
        nav_mesh.filter_low_hanging_obstacles = true
        nav_mesh.filter_ledge_spans = true
        nav_mesh.filter_walkable_low_height_spans = true
        
        navigation_region.navigation_mesh = nav_mesh
        
        # Add to root of current scene
        get_tree().current_scene.add_child(navigation_region)
        
        # Bake navigation mesh
        await get_tree().process_frame
        _bake_navigation_mesh()
    else:
        print("NavigationManager: Found existing NavigationRegion3D")
    
    navigation_ready.emit()

func _bake_navigation_mesh():
    if not navigation_region or not navigation_region.navigation_mesh:
        return
    
    print("NavigationManager: Baking navigation mesh...")
    
    # In Godot 4.4, we need to set up the source geometry
    var source_geometry = NavigationMeshSourceGeometryData3D.new()
    
    # Parse the scene for navigation mesh sources
    NavigationServer3D.parse_source_geometry_data(
        navigation_region.navigation_mesh,
        source_geometry,
        get_tree().current_scene
    )
    
    # Bake the navigation mesh with the parsed data
    NavigationServer3D.bake_from_source_geometry_data_async(
        navigation_region.navigation_mesh,
        source_geometry,
        _on_navigation_mesh_baked
    )

func _on_navigation_mesh_baked():
    print("NavigationManager: Navigation mesh baking complete!")
    
    # Update the navigation region
    if navigation_region:
        navigation_region.bake_finished.emit()

func _create_debug_visualization():
    if not navigation_region:
        return
    
    # Create debug mesh instance
    debug_instance = MeshInstance3D.new()
    debug_instance.name = "NavigationDebugMesh"
    
    # Create a simple material for debug visualization
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0, 0.5, 1, 0.3)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    material.no_depth_test = true
    
    debug_instance.material_override = material
    debug_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    
    navigation_region.add_child(debug_instance)
    
    # Update debug mesh when navigation is ready
    if navigation_region.navigation_mesh:
        _update_debug_mesh()

func _update_debug_mesh():
    if not debug_instance or not navigation_region or not navigation_region.navigation_mesh:
        return
    
    # Get the navigation mesh vertices
    # var _nav_mesh = navigation_region.navigation_mesh
    
    # Create a simple box mesh for now (full visualization would be complex)
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(50, 0.1, 50)  # Flat box to show navigation area
    debug_instance.mesh = box_mesh
    debug_instance.position.y = 0.05  # Slightly above ground

func get_navigation_path(from: Vector3, to: Vector3) -> PackedVector3Array:
    return NavigationServer3D.map_get_path(
        navigation_region.get_navigation_map(),
        from,
        to,
        true
    )

func is_position_on_navmesh(position: Vector3) -> bool:
    var map = navigation_region.get_navigation_map()
    var closest_point = NavigationServer3D.map_get_closest_point(map, position)
    return position.distance_to(closest_point) < 1.0

func get_random_position_on_navmesh(origin: Vector3, radius: float) -> Vector3:
    var map = navigation_region.get_navigation_map()
    
    # Try several random positions
    for i in range(10):
        var angle = randf() * TAU
        var distance = randf() * radius
        var test_pos = origin + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
        
        var closest_point = NavigationServer3D.map_get_closest_point(map, test_pos)
        if test_pos.distance_to(closest_point) < 1.0:
            return closest_point
    
    # Fallback to origin if no valid position found
    return NavigationServer3D.map_get_closest_point(map, origin)

func set_debug_enabled(enabled: bool):
    enable_debug_visualization = enabled
    if debug_instance:
        debug_instance.visible = enabled
