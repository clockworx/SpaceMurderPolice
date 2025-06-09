@tool
extends Node3D

# This script builds the complete station directly in the scene

func _ready():
	if not Engine.is_editor_hint():
		build_station()

func build_station():
	print("Building complete 3-level station...")
	
	# Materials
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.3, 0.35)
	floor_mat.metallic = 0.8
	floor_mat.roughness = 0.4
	
	var docking_mat = StandardMaterial3D.new()
	docking_mat.albedo_color = Color(0.5, 0.5, 0.6)
	docking_mat.metallic = 0.7
	docking_mat.roughness = 0.4
	
	var medical_mat = StandardMaterial3D.new()
	medical_mat.albedo_color = Color(0.8, 0.8, 0.9)
	medical_mat.metallic = 0.7
	medical_mat.roughness = 0.4
	
	var corridor_mat = StandardMaterial3D.new()
	corridor_mat.albedo_color = Color(0.5, 0.5, 0.5)
	corridor_mat.metallic = 0.7
	corridor_mat.roughness = 0.4
	
	var stairwell_mat = StandardMaterial3D.new()
	stairwell_mat.albedo_color = Color(0.4, 0.4, 0.5)
	stairwell_mat.metallic = 0.9
	stairwell_mat.roughness = 0.3
	
	# Build Docking Bay
	var docking_bay = Node3D.new()
	docking_bay.name = "DockingBay"
	docking_bay.position = Vector3(-15, 0, 15)
	
	# Floor
	add_box(docking_bay, "Floor", Vector3(0, -0.1, 0), Vector3(12, 0.2, 12), floor_mat)
	
	# Walls with door opening on north side
	add_box(docking_bay, "NorthWallLeft", Vector3(-3.75, 1.75, -6), Vector3(4.5, 3.5, 0.3), docking_mat)
	add_box(docking_bay, "NorthWallRight", Vector3(3.75, 1.75, -6), Vector3(4.5, 3.5, 0.3), docking_mat)
	add_box(docking_bay, "NorthWallTop", Vector3(0, 3.25, -6), Vector3(3, 0.5, 0.3), docking_mat)
	
	# Other walls
	add_box(docking_bay, "SouthWall", Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), docking_mat)
	add_box(docking_bay, "EastWall", Vector3(6, 1.75, 0), Vector3(0.3, 3.5, 12), docking_mat)
	add_box(docking_bay, "WestWall", Vector3(-6, 1.75, 0), Vector3(0.3, 3.5, 12), docking_mat)
	
	# Ceiling
	add_box(docking_bay, "Ceiling", Vector3(0, 3.6, 0), Vector3(12, 0.2, 12), docking_mat)
	
	add_child(docking_bay)
	
	# Build Medical Bay
	var medical_bay = Node3D.new()
	medical_bay.name = "MedicalBay"
	medical_bay.position = Vector3(-15, 0, 0)
	
	# Floor
	add_box(medical_bay, "Floor", Vector3(0, -0.1, 0), Vector3(12, 0.2, 12), floor_mat)
	
	# Walls with door opening on east side
	add_box(medical_bay, "EastWallTop", Vector3(6, 3.25, 0), Vector3(0.3, 0.5, 3), medical_mat)
	add_box(medical_bay, "EastWallLeft", Vector3(6, 1.75, -3.75), Vector3(0.3, 3.5, 4.5), medical_mat)
	add_box(medical_bay, "EastWallRight", Vector3(6, 1.75, 3.75), Vector3(0.3, 3.5, 4.5), medical_mat)
	
	# Other walls
	add_box(medical_bay, "NorthWall", Vector3(0, 1.75, -6), Vector3(12, 3.5, 0.3), medical_mat)
	add_box(medical_bay, "SouthWall", Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), medical_mat)
	add_box(medical_bay, "WestWall", Vector3(-6, 1.75, 0), Vector3(0.3, 3.5, 12), medical_mat)
	
	# Ceiling
	add_box(medical_bay, "Ceiling", Vector3(0, 3.6, 0), Vector3(12, 0.2, 12), medical_mat)
	
	add_child(medical_bay)
	
	# Build corridors
	add_box(self, "Corridor1", Vector3(-7.5, -0.1, 9), Vector3(15, 0.2, 3), corridor_mat)
	add_box(self, "Corridor2", Vector3(-7.5, -0.1, 0), Vector3(15, 0.2, 3), corridor_mat)
	
	# Build central stairwell
	add_box(self, "StairwellFloor", Vector3(0, -0.1, 0), Vector3(6, 0.2, 6), stairwell_mat)
	
	print("Basic station structure complete!")

func add_box(parent: Node3D, name: String, position: Vector3, size: Vector3, material: Material):
	var body = StaticBody3D.new()
	body.name = name
	body.position = position
	parent.add_child(body)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	
	# Set owner for scene saving
	if Engine.is_editor_hint() and get_tree():
		var scene_root = get_tree().edited_scene_root
		if scene_root:
			body.owner = scene_root
			collision.owner = scene_root
			mesh_instance.owner = scene_root