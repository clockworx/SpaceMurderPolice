extends Node3D

# Visualizes NavigationLink3D connections in the scene

@export var enabled: bool = true
@export var link_color: Color = Color(1, 1, 0, 1)
@export var link_width: float = 0.1
@export var endpoint_size: float = 0.2
@export var show_labels: bool = true

var link_meshes: Array = []

func _ready():
	if enabled:
		_visualize_navigation_links()

func _visualize_navigation_links():
	# Clear old meshes
	for mesh in link_meshes:
		mesh.queue_free()
	link_meshes.clear()
	
	# Find all NavigationLink3D nodes
	var links = get_tree().get_nodes_in_group("navigation_links")
	if links.is_empty():
		# Search recursively
		_find_links_recursive(get_tree().current_scene)
		links = get_tree().get_nodes_in_group("navigation_links")
	
	print("NavigationLinkVisualizer: Found ", links.size(), " navigation links")
	
	for link in links:
		if link is NavigationLink3D and link.enabled:
			_visualize_single_link(link)

func _find_links_recursive(node: Node):
	if node is NavigationLink3D:
		node.add_to_group("navigation_links")
	
	for child in node.get_children():
		_find_links_recursive(child)

func _visualize_single_link(link: NavigationLink3D):
	# Get global positions
	var start_global = link.global_transform * link.start_position
	var end_global = link.global_transform * link.end_position
	
	# Create line between start and end
	var line_mesh = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = link_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	
	line_mesh.mesh = immediate_mesh
	line_mesh.material_override = material
	add_child(line_mesh)
	link_meshes.append(line_mesh)
	
	# Draw line
	var direction = (end_global - start_global).normalized()
	var length = start_global.distance_to(end_global)
	
	# Create cylinder for the line
	var cylinder = CylinderMesh.new()
	cylinder.height = length
	cylinder.top_radius = link_width
	cylinder.bottom_radius = link_width
	cylinder.radial_segments = 8
	
	line_mesh.mesh = cylinder
	line_mesh.global_position = (start_global + end_global) / 2
	line_mesh.look_at(end_global, Vector3.UP)
	line_mesh.rotate_object_local(Vector3(1, 0, 0), PI/2)
	
	# Create spheres at endpoints
	_create_endpoint_sphere(start_global, Color.GREEN)
	_create_endpoint_sphere(end_global, Color.RED)
	
	# Create label
	if show_labels:
		var label = Label3D.new()
		label.text = link.get_parent().name + " Link"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = link_color
		label.font_size = 16
		add_child(label)
		label.global_position = (start_global + end_global) / 2 + Vector3(0, 0.5, 0)
		link_meshes.append(label)
		
		# Direction indicator
		if link.bidirectional:
			label.text += " ↔"
		else:
			label.text += " →"

func _create_endpoint_sphere(position: Vector3, color: Color):
	var sphere_mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = endpoint_size
	sphere.height = endpoint_size * 2
	sphere.radial_segments = 8
	sphere.rings = 4
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	sphere_mesh_instance.mesh = sphere
	sphere_mesh_instance.material_override = material
	add_child(sphere_mesh_instance)
	sphere_mesh_instance.global_position = position
	link_meshes.append(sphere_mesh_instance)