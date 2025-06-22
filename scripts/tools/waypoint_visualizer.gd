@tool
extends Node3D

# Script to add to waypoint nodes for editor visualization

@export var waypoint_color: Color = Color.YELLOW : set = set_waypoint_color
@export var waypoint_size: float = 0.3 : set = set_waypoint_size
@export var show_label: bool = true : set = set_show_label

var debug_mesh: MeshInstance3D
var label: Label3D

func _ready():
	if Engine.is_editor_hint():
		_setup_visualization()

func _setup_visualization():
	# Create mesh instance if it doesn't exist
	if not debug_mesh:
		debug_mesh = MeshInstance3D.new()
		debug_mesh.name = "DebugMesh"
		add_child(debug_mesh)
		
		# Create sphere mesh
		var sphere = SphereMesh.new()
		sphere.radius = waypoint_size
		sphere.height = waypoint_size * 2
		sphere.radial_segments = 16
		sphere.rings = 8
		debug_mesh.mesh = sphere
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = waypoint_color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.8
		debug_mesh.material_override = material
	
	# Create label if it doesn't exist
	if not label and show_label:
		label = Label3D.new()
		label.name = "Label"
		label.text = name
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.fixed_size = true
		label.font_size = 14
		label.outline_size = 4
		label.position.y = waypoint_size + 0.2
		add_child(label)

func set_waypoint_color(value: Color):
	waypoint_color = value
	if debug_mesh and debug_mesh.material_override:
		debug_mesh.material_override.albedo_color = waypoint_color

func set_waypoint_size(value: float):
	waypoint_size = value
	if debug_mesh and debug_mesh.mesh:
		debug_mesh.mesh.radius = waypoint_size
		debug_mesh.mesh.height = waypoint_size * 2
	if label:
		label.position.y = waypoint_size + 0.2

func set_show_label(value: bool):
	show_label = value
	if label:
		label.visible = show_label
	elif show_label and Engine.is_editor_hint():
		_setup_visualization()

func _enter_tree():
	if Engine.is_editor_hint():
		_setup_visualization()

func _exit_tree():
	if Engine.is_editor_hint():
		if debug_mesh:
			debug_mesh.queue_free()
		if label:
			label.queue_free()