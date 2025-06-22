@tool
extends Node3D

# Simple waypoint visualizer - attach this to any Node3D to see it in editor

func _ready():
    if Engine.is_editor_hint():
        _create_visual()

func _enter_tree():
    if Engine.is_editor_hint():
        _create_visual()

func _create_visual():
    # Check if we already have a mesh
    var existing_mesh = get_node_or_null("WaypointMesh")
    if existing_mesh:
        return
    
    # Create mesh instance
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.name = "WaypointMesh"
    
    # Create sphere mesh
    var sphere = SphereMesh.new()
    sphere.radius = 0.3
    sphere.height = 0.6
    sphere.radial_segments = 16
    sphere.rings = 8
    mesh_instance.mesh = sphere
    
    # Create material with color based on waypoint type
    var material = StandardMaterial3D.new()
    
    # Color based on name
    if name.ends_with("_Center"):
        material.albedo_color = Color(0, 0.5, 1, 0.8)  # Blue for room centers
        sphere.radius = 0.4
        sphere.height = 0.8
    elif name.begins_with("Hallway_"):
        material.albedo_color = Color(1, 1, 0, 0.8)  # Yellow for hallways
    elif name.begins_with("Corner_"):
        material.albedo_color = Color(1, 0.5, 0, 0.8)  # Orange for corners
        sphere.radius = 0.25
        sphere.height = 0.5
    elif name.begins_with("Nav_"):
        material.albedo_color = Color(0, 1, 1, 0.8)  # Cyan for navigation aids
        sphere.radius = 0.25
        sphere.height = 0.5
    else:
        material.albedo_color = Color(1, 1, 1, 0.8)  # White default
    
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.no_depth_test = true
    mesh_instance.material_override = material
    
    add_child(mesh_instance)
    
    # Create label
    var label = Label3D.new()
    label.name = "WaypointLabel"
    label.text = name
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.fixed_size = true
    label.font_size = 14
    label.outline_size = 4
    label.position.y = sphere.radius + 0.2
    
    add_child(label)
