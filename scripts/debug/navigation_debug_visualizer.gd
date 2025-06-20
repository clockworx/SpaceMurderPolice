extends Node3D

@export var enabled: bool = true
@export var update_interval: float = 0.1
@export var nav_region_color: Color = Color(0, 1, 0, 0.3)
@export var nav_link_color: Color = Color(1, 1, 0, 1)
@export var nav_link_width: float = 3.0
@export var show_nav_regions: bool = true
@export var show_nav_links: bool = true
@export var show_agent_paths: bool = true
@export var agent_path_color: Color = Color(1, 0, 0, 1)
@export var agent_path_width: float = 2.0
@export var show_waypoints: bool = true
@export var waypoint_color: Color = Color(0, 0.5, 1, 1)
@export var waypoint_size: float = 0.3
@export var room_waypoint_color: Color = Color(0.5, 1, 0.5, 1)  # Green for room waypoints
@export var room_waypoint_size: float = 0.6  # Larger for visibility
@export var current_waypoint_color: Color = Color(1, 1, 0, 1)  # Yellow for current target
@export var current_waypoint_size: float = 0.5  # Larger for visibility

var _timer: float = 0.0
var _debug_meshes: Array = []
var _line_meshes: Array = []

func _ready():
    set_process(enabled)
    if enabled:
        _create_debug_visualization()

func _process(delta):
    if not enabled:
        return
        
    _timer += delta
    if _timer >= update_interval:
        _timer = 0.0
        _update_debug_visualization()

func _create_debug_visualization():
    _clear_debug_visualization()
    
    if show_nav_regions:
        _visualize_navigation_regions()
    
    if show_nav_links:
        _visualize_navigation_links()
    
    if show_waypoints:
        _visualize_waypoints()

func _update_debug_visualization():
    if show_agent_paths:
        _visualize_agent_paths()
    
    if show_waypoints:
        _update_waypoint_highlights()

func _visualize_navigation_regions():
    # Get all NavigationRegion3D nodes in the scene
    var nav_regions = get_tree().get_nodes_in_group("navigation_regions")
    if nav_regions.is_empty():
        # Try to find NavigationRegion3D nodes without group
        _find_nav_regions_recursive(get_tree().root)
    
func _find_nav_regions_recursive(node: Node):
    if node is NavigationRegion3D:
        var nav_mesh = node.navigation_mesh
        if nav_mesh:
            var mesh_instance = MeshInstance3D.new()
            add_child(mesh_instance)
            _debug_meshes.append(mesh_instance)
            
            # Create visual representation of navigation mesh
            var arrays = []
            arrays.resize(Mesh.ARRAY_MAX)
            arrays[Mesh.ARRAY_VERTEX] = nav_mesh.vertices
            
            var array_mesh = ArrayMesh.new()
            array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
            
            var material = StandardMaterial3D.new()
            material.albedo_color = nav_region_color
            material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            material.cull_mode = BaseMaterial3D.CULL_DISABLED
            
            mesh_instance.mesh = array_mesh
            mesh_instance.material_override = material
            mesh_instance.global_transform = node.global_transform
    
    for child in node.get_children():
        _find_nav_regions_recursive(child)

func _visualize_navigation_links():
    # Get all NavigationLink3D nodes in the scene
    var links = get_tree().get_nodes_in_group("navigation_links")
    
    for link in links:
        if link is NavigationLink3D:
            var start_pos = link.global_transform * link.start_position
            var end_pos = link.global_transform * link.end_position
            
            _draw_debug_line(start_pos, end_pos, nav_link_color, nav_link_width)
            
            # Draw small spheres at connection points
            _draw_debug_sphere(start_pos, 0.2, nav_link_color)
            _draw_debug_sphere(end_pos, 0.2, nav_link_color)

func _visualize_waypoints():
    # Find all waypoint nodes in the scene
    var waypoints = get_tree().get_nodes_in_group("waypoints")
    
    # Also check for nodes named "Waypoint" if group is empty
    if waypoints.is_empty():
        _find_waypoints_recursive(get_tree().root)
    else:
        for waypoint in waypoints:
            if waypoint is Node3D:
                _draw_debug_sphere(waypoint.global_position, waypoint_size, waypoint_color)
                
                # Draw waypoint label
                var label = Label3D.new()
                label.text = waypoint.name
                label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
                label.modulate = waypoint_color
                add_child(label)
                label.global_position = waypoint.global_position + Vector3(0, waypoint_size + 0.2, 0)
                _debug_meshes.append(label)
    
    # Also visualize waypoints from NPC waypoint arrays
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if npc.has_method("get") and npc.get("waypoint_nodes"):
            var waypoint_nodes = npc.get("waypoint_nodes")
            for waypoint_node in waypoint_nodes:
                var waypoint
                if waypoint_node is NodePath:
                    waypoint = npc.get_node_or_null(waypoint_node)
                elif waypoint_node is Node3D:
                    waypoint = waypoint_node
                
                if waypoint and waypoint is Node3D:
                    _draw_debug_sphere(waypoint.global_position, waypoint_size, waypoint_color)

func _find_waypoints_recursive(node: Node):
    if node is Node3D and node.name.contains("Waypoint"):
        # Check if it's a room waypoint
        var is_room_waypoint = false
        var room_names = ["Laboratory", "MedicalBay", "Security", "Engineering", "CrewQuarters", "Cafeteria"]
        for room_name in room_names:
            if node.name.contains(room_name):
                is_room_waypoint = true
                break
        
        # Use different size/color for room waypoints
        var size = room_waypoint_size if is_room_waypoint else waypoint_size
        var color = room_waypoint_color if is_room_waypoint else waypoint_color
        
        _draw_debug_sphere(node.global_position, size, color)
        
        # Draw waypoint label
        var label = Label3D.new()
        label.text = node.name
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.modulate = color
        label.font_size = 32 if is_room_waypoint else 16
        add_child(label)
        label.global_position = node.global_position + Vector3(0, size + 0.3, 0)
        _debug_meshes.append(label)
    
    for child in node.get_children():
        _find_waypoints_recursive(child)

func _update_waypoint_highlights():
    # Update highlighting for current waypoints
    # This runs frequently to show the current target
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc.has_method("get") and npc.get("waypoint_nodes"):
            var current_index = npc.get("current_waypoint_index")
            if current_index >= 0:
                var waypoint_nodes = npc.get("waypoint_nodes")
                if current_index < waypoint_nodes.size():
                    var waypoint_node = waypoint_nodes[current_index]
                    # Check if it's a NodePath or a Node3D
                    var target_waypoint
                    if waypoint_node is NodePath:
                        target_waypoint = npc.get_node_or_null(waypoint_node)
                    elif waypoint_node is Node3D:
                        target_waypoint = waypoint_node
                    
                    if target_waypoint and target_waypoint is Node3D:
                        # Draw highlighted sphere at current target
                        var pulse = abs(sin(Time.get_ticks_msec() * 0.003)) * 0.3 + 0.2
                        _draw_temp_sphere(target_waypoint.global_position, current_waypoint_size + pulse, current_waypoint_color)

func _draw_temp_sphere(position: Vector3, radius: float, color: Color):
    # Create temporary sphere that will be cleared next frame
    var mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)
    _line_meshes.append(mesh_instance)  # Add to temporary meshes
    
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 12
    sphere_mesh.rings = 6
    sphere_mesh.radius = radius
    sphere_mesh.height = radius * 2
    
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.8
    
    mesh_instance.mesh = sphere_mesh
    mesh_instance.material_override = material
    mesh_instance.global_position = position

func _visualize_agent_paths():
    # Clear previous path lines
    for mesh in _line_meshes:
        mesh.queue_free()
    _line_meshes.clear()
    
    # Find all NPCs with navigation agents
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc.has_node("NavigationAgent3D"):
            var agent = npc.get_node("NavigationAgent3D")
            if agent.is_navigation_finished():
                continue
                
            var path = agent.get_current_navigation_path()
            if path.size() > 1:
                # Draw the full path
                for i in range(path.size() - 1):
                    _draw_debug_line(path[i], path[i + 1], agent_path_color, agent_path_width)
                
                # Draw spheres at each path point
                for point in path:
                    _draw_debug_sphere(point, 0.1, agent_path_color)
                
                # Draw current position to first path point
                if path.size() > 0:
                    _draw_debug_line(npc.global_position, path[0], agent_path_color * 0.5, agent_path_width * 0.5)
        
        # Also visualize the full navigation path if NPC has one
        if npc.has_method("get") and npc.get("navigation_path"):
            var nav_path = npc.get("navigation_path")
            var nav_index = npc.get("navigation_path_index")
            if nav_path and nav_path.size() > 1:
                # Draw the planned navigation path in green
                for i in range(nav_path.size() - 1):
                    var color = Color(0, 1, 0, 0.8) if i >= nav_index else Color(0.5, 0.5, 0.5, 0.5)
                    _draw_debug_line(nav_path[i], nav_path[i + 1], color, agent_path_width * 0.8)
                
                # Highlight current target waypoint
                if nav_index < nav_path.size():
                    _draw_temp_sphere(nav_path[nav_index], 0.2, Color(0, 1, 0, 1))

func _draw_debug_line(from: Vector3, to: Vector3, color: Color, width: float):
    var mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)
    _line_meshes.append(mesh_instance)
    
    var immediate_mesh = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.albedo_color = color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    
    mesh_instance.mesh = immediate_mesh
    mesh_instance.material_override = material
    
    immediate_mesh.clear_surfaces()
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    immediate_mesh.surface_set_color(color)
    immediate_mesh.surface_add_vertex(from)
    immediate_mesh.surface_add_vertex(to)
    immediate_mesh.surface_end()

func _draw_debug_sphere(position: Vector3, radius: float, color: Color):
    var mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)
    _debug_meshes.append(mesh_instance)
    
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 8
    sphere_mesh.rings = 4
    sphere_mesh.radius = radius
    sphere_mesh.height = radius * 2
    
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    
    mesh_instance.mesh = sphere_mesh
    mesh_instance.material_override = material
    mesh_instance.global_position = position

func _clear_debug_visualization():
    for mesh in _debug_meshes:
        mesh.queue_free()
    _debug_meshes.clear()
    
    for mesh in _line_meshes:
        mesh.queue_free()
    _line_meshes.clear()

func set_enabled(value: bool):
    enabled = value
    set_process(enabled)
    if enabled:
        _create_debug_visualization()
    else:
        _clear_debug_visualization()
