@tool
extends Node3D
class_name Waypoint3D

@export_group("Waypoint Visuals")
@export var waypoint_color: Color = Color.CYAN : set = set_waypoint_color
@export var waypoint_size: float = 0.5 : set = set_waypoint_size
@export var show_label: bool = true : set = set_show_label
@export var label_text: String = "" : set = set_label_text

@export_group("Waypoint Settings")
@export var waypoint_index: int = 0
@export var wait_time: float = 0.0  # How long NPC should wait at this waypoint

var sphere_mesh: MeshInstance3D
var label: Label3D

func _ready():
    # Create visual representation
    _create_waypoint_visual()
    
    # Hide in game
    if not Engine.is_editor_hint():
        visible = false

func _create_waypoint_visual():
    # Create sphere mesh
    if not sphere_mesh:
        sphere_mesh = MeshInstance3D.new()
        sphere_mesh.name = "WaypointSphere"
        add_child(sphere_mesh)
        
        var sphere = SphereMesh.new()
        sphere.radial_segments = 16
        sphere.rings = 8
        sphere_mesh.mesh = sphere
        
        # Create material
        var material = StandardMaterial3D.new()
        material.albedo_color = waypoint_color
        material.emission_enabled = true
        material.emission = waypoint_color
        material.emission_energy = 0.5
        sphere_mesh.material_override = material
    
    # Create label
    if not label:
        label = Label3D.new()
        label.name = "WaypointLabel"
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        label.modulate = Color.WHITE
        label.outline_modulate = Color.BLACK
        label.outline_size = 4
        label.font_size = 24
        label.position.y = waypoint_size + 0.2
        add_child(label)
    
    _update_visual()

func _update_visual():
    if sphere_mesh and sphere_mesh.mesh:
        sphere_mesh.mesh.radius = waypoint_size
        sphere_mesh.mesh.height = waypoint_size * 2
        
        if sphere_mesh.material_override:
            sphere_mesh.material_override.albedo_color = waypoint_color
            sphere_mesh.material_override.emission = waypoint_color
    
    if label:
        label.visible = show_label
        if label_text != "":
            label.text = label_text
        else:
            label.text = "W" + str(waypoint_index)
        label.position.y = waypoint_size + 0.2

func set_waypoint_color(value: Color):
    waypoint_color = value
    if sphere_mesh and sphere_mesh.material_override:
        sphere_mesh.material_override.albedo_color = waypoint_color
        sphere_mesh.material_override.emission = waypoint_color

func set_waypoint_size(value: float):
    waypoint_size = value
    _update_visual()

func set_show_label(value: bool):
    show_label = value
    if label:
        label.visible = show_label

func set_label_text(value: String):
    label_text = value
    if label:
        if label_text != "":
            label.text = label_text
        else:
            label.text = "W" + str(waypoint_index)

func get_wait_time() -> float:
    return wait_time