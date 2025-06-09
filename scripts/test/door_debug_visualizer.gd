@tool
extends Node3D

# Visual debugger to show where doors SHOULD be in the station

var door_locations = [
	# Deck 1 doors
	{"room": "Docking Bay", "world_pos": Vector3(-15, 1.35, 9), "size": Vector3(3, 2.8, 2), "color": Color.GREEN},
	{"room": "Medical Bay", "world_pos": Vector3(-9, 1.35, 0), "size": Vector3(2, 2.5, 0.5), "color": Color.BLUE},
	{"room": "Command Center", "world_pos": Vector3(9, 1.35, -15), "size": Vector3(2, 2.5, 0.5), "color": Color.YELLOW},
	
	# Stairwell doors
	{"room": "Stairwell D1 North", "world_pos": Vector3(0, 1.5, -4), "size": Vector3(3, 3, 2), "color": Color.CYAN},
	{"room": "Stairwell D1 South", "world_pos": Vector3(0, 1.5, 4), "size": Vector3(3, 3, 2), "color": Color.CYAN},
	
	# Deck 2 doors  
	{"room": "Crew Quarters A", "world_pos": Vector3(-9, 5.35, 15), "size": Vector3(2, 2.5, 0.5), "color": Color.PURPLE},
	
	# Deck 3 doors
	{"room": "Main Engineering", "world_pos": Vector3(-9, 9.35, 15), "size": Vector3(2, 2.5, 0.5), "color": Color.ORANGE}
]

func _ready():
	if Engine.is_editor_hint():
		create_door_markers()

func create_door_markers():
	for door_data in door_locations:
		create_door_marker(door_data)

func create_door_marker(door_data: Dictionary):
	# Create a visual marker for each door
	var marker = Node3D.new()
	marker.name = door_data.room + "_DoorMarker"
	marker.position = door_data.world_pos
	add_child(marker)
	
	# Add a box mesh to visualize the door opening
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = door_data.size
	mesh_instance.mesh = box_mesh
	
	# Create transparent material
	var material = StandardMaterial3D.new()
	material.albedo_color = door_data.color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	
	marker.add_child(mesh_instance)
	
	# Add label
	var label = Label3D.new()
	label.text = door_data.room + " DOOR"
	label.position = Vector3(0, 2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 8
	marker.add_child(label)
	
	# Set owner for scene saving
	if Engine.is_editor_hint():
		var scene_root = get_tree().edited_scene_root
		if scene_root:
			marker.owner = scene_root
			mesh_instance.owner = scene_root
			label.owner = scene_root