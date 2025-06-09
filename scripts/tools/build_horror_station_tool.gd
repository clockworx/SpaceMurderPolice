@tool
extends EditorScript

# This tool builds the horror station directly in the editor
# Run from Script Editor: File -> Run

func _run():
	print("Building horror station in editor...")
	
	var scene_root = get_scene()
	if not scene_root:
		push_error("No scene open! Open simple_station.tscn first")
		return
		
	# Remove any existing station nodes
	for child in scene_root.get_children():
		if child.name in ["MainCorridor", "SecurityCheckpoint", "MedicalExamRoom", 
						  "MaintenanceRoom", "StorageRoom", "CrewQuarters", 
						  "VentSystem", "HidingSpots", "EmergencyLights", "PipesAndCables"]:
			child.queue_free()
	
	# Materials
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.15, 0.15, 0.18)
	wall_mat.metallic = 0.9
	wall_mat.roughness = 0.7
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.1, 0.1, 0.12)
	floor_mat.metallic = 0.8
	floor_mat.roughness = 0.9
	
	var grate_mat = StandardMaterial3D.new()
	grate_mat.albedo_color = Color(0.08, 0.08, 0.1)
	grate_mat.metallic = 0.95
	grate_mat.roughness = 0.3
	
	# Build all components
	create_main_corridor(scene_root, wall_mat, floor_mat)
	create_security_checkpoint(scene_root, wall_mat, floor_mat)
	create_medical_exam_room(scene_root, wall_mat, floor_mat)
	create_maintenance_room(scene_root, wall_mat, floor_mat)
	create_storage_room(scene_root, wall_mat, floor_mat)
	create_crew_quarters(scene_root, wall_mat, floor_mat)
	create_vent_system(scene_root, grate_mat)
	add_lockers_and_hiding_spots(scene_root)
	add_emergency_lighting(scene_root)
	add_pipes_and_cables(scene_root)
	
	print("Horror station built! Save the scene to keep changes.")

const CORRIDOR_WIDTH = 2.5
const CORRIDOR_HEIGHT = 2.8
const WALL_THICKNESS = 0.3

func create_main_corridor(root: Node3D, wall_mat: Material, floor_mat: Material):
	var corridor = Node3D.new()
	corridor.name = "MainCorridor"
	root.add_child(corridor)
	corridor.owner = root
	
	# L-shaped main corridor
	add_corridor_section(corridor, root, Vector3(0, 0, 0), Vector3(20, 0, 0), wall_mat, floor_mat)
	add_corridor_section(corridor, root, Vector3(20, 0, 0), Vector3(20, 0, -15), wall_mat, floor_mat)
	add_corridor_section(corridor, root, Vector3(10, 0, 0), Vector3(10, 0, 10), wall_mat, floor_mat)
	add_corridor_section(corridor, root, Vector3(10, 0, 0), Vector3(10, 0, -10), wall_mat, floor_mat)
	add_corridor_section(corridor, root, Vector3(20, 0, -7.5), Vector3(30, 0, -7.5), wall_mat, floor_mat)

func add_corridor_section(parent: Node3D, root: Node3D, start: Vector3, end: Vector3, wall_mat: Material, floor_mat: Material):
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	var center = (start + end) / 2
	
	var section = Node3D.new()
	section.name = "CorridorSection"
	section.position = center
	parent.add_child(section)
	section.owner = root
	
	# Floor
	var floor_size = Vector3(length if abs(direction.x) > 0 else CORRIDOR_WIDTH, 
							0.2, 
							length if abs(direction.z) > 0 else CORRIDOR_WIDTH)
	add_box(section, root, "Floor", Vector3(0, -0.1, 0), floor_size, floor_mat)
	
	# Walls
	if abs(direction.x) > 0:  # East-West corridor
		add_box(section, root, "NorthWall", Vector3(0, CORRIDOR_HEIGHT/2, -CORRIDOR_WIDTH/2), 
				Vector3(length, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
		add_box(section, root, "SouthWall", Vector3(0, CORRIDOR_HEIGHT/2, CORRIDOR_WIDTH/2), 
				Vector3(length, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	else:  # North-South corridor
		add_box(section, root, "EastWall", Vector3(CORRIDOR_WIDTH/2, CORRIDOR_HEIGHT/2, 0), 
				Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT, length), wall_mat)
		add_box(section, root, "WestWall", Vector3(-CORRIDOR_WIDTH/2, CORRIDOR_HEIGHT/2, 0), 
				Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT, length), wall_mat)
	
	# Ceiling
	var ceiling_size = floor_size
	ceiling_size.y = 0.1
	add_box(section, root, "Ceiling", Vector3(0, CORRIDOR_HEIGHT, 0), ceiling_size, wall_mat)

func create_security_checkpoint(root: Node3D, wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "SecurityCheckpoint"
	room.position = Vector3(5, 0, 0)
	root.add_child(room)
	room.owner = root
	
	var room_size = Vector3(4, CORRIDOR_HEIGHT, 4)
	
	# Floor
	add_box(room, root, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), floor_mat)
	
	# Walls with door and window
	add_box(room, root, "NorthWallLeft", Vector3(-1.5, CORRIDOR_HEIGHT/2, -2), 
			Vector3(1, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	add_box(room, root, "NorthWallRight", Vector3(1.5, CORRIDOR_HEIGHT/2, -2), 
			Vector3(1, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	add_box(room, root, "NorthWallTop", Vector3(0, CORRIDOR_HEIGHT - 0.5, -2), 
			Vector3(2, 1, WALL_THICKNESS), wall_mat)
	add_box(room, root, "NorthWallBottom", Vector3(0, 0.5, -2), 
			Vector3(2, 1, WALL_THICKNESS), wall_mat)
	
	add_box(room, root, "SouthWall", Vector3(0, CORRIDOR_HEIGHT/2, 2), 
			Vector3(room_size.x, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	add_box(room, root, "EastWall", Vector3(2, CORRIDOR_HEIGHT/2, 0), 
			Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT, room_size.z), wall_mat)
	
	# West wall with door
	add_box(room, root, "WestWallTop", Vector3(-2, CORRIDOR_HEIGHT - 0.25, 0), 
			Vector3(WALL_THICKNESS, 0.5, room_size.z), wall_mat)
	add_box(room, root, "WestWallLeft", Vector3(-2, CORRIDOR_HEIGHT/2, -1.5), 
			Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT - 0.5, 1), wall_mat)
	add_box(room, root, "WestWallRight", Vector3(-2, CORRIDOR_HEIGHT/2, 1.5), 
			Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT - 0.5, 1), wall_mat)
	
	# Ceiling
	add_box(room, root, "Ceiling", Vector3(0, CORRIDOR_HEIGHT, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Security desk
	var desk_mat = StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.2, 0.2, 0.25)
	add_box(room, root, "SecurityDesk", Vector3(0, 0.4, -0.5), Vector3(3, 0.8, 1), desk_mat)

func create_medical_exam_room(root: Node3D, wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "MedicalExamRoom"
	room.position = Vector3(10, 0, 10)
	root.add_child(room)
	room.owner = root
	
	var room_size = Vector3(5, CORRIDOR_HEIGHT, 6)
	
	# White medical floor
	var med_floor_mat = StandardMaterial3D.new()
	med_floor_mat.albedo_color = Color(0.9, 0.9, 0.95)
	med_floor_mat.metallic = 0.2
	med_floor_mat.roughness = 0.3
	add_box(room, root, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), med_floor_mat)
	
	# North wall with door
	add_box(room, root, "NorthWallLeft", Vector3(-2, room_size.y/2, -room_size.z/2), 
			Vector3(1, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "NorthWallRight", Vector3(1.5, room_size.y/2, -room_size.z/2), 
			Vector3(2, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "NorthWallTop", Vector3(-0.25, room_size.y - 0.25, -room_size.z/2), 
			Vector3(2.5, 0.5, WALL_THICKNESS), wall_mat)
	
	# Other walls
	add_box(room, root, "SouthWall", Vector3(0, room_size.y/2, room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "EastWall", Vector3(room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	add_box(room, root, "WestWall", Vector3(-room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	
	# Ceiling
	add_box(room, root, "Ceiling", Vector3(0, room_size.y, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Medical equipment
	var table_mat = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.7, 0.7, 0.8)
	table_mat.metallic = 0.9
	add_box(room, root, "ExamTable", Vector3(0, 0.5, 0), Vector3(2, 0.1, 0.7), table_mat)
	
	var cabinet_mat = StandardMaterial3D.new()
	cabinet_mat.albedo_color = Color(0.85, 0.85, 0.9)
	add_box(room, root, "MedCabinet", Vector3(2, 1, -2.5), Vector3(0.8, 2, 0.5), cabinet_mat)

func create_maintenance_room(root: Node3D, wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "MaintenanceRoom"
	room.position = Vector3(20, 0, -7.5)
	root.add_child(room)
	room.owner = root
	
	var room_size = Vector3(6, CORRIDOR_HEIGHT + 0.5, 5)
	
	# Grated floor
	var grate_mat = StandardMaterial3D.new()
	grate_mat.albedo_color = Color(0.1, 0.1, 0.12)
	grate_mat.metallic = 0.95
	add_box(room, root, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), grate_mat)
	
	# West wall with door
	add_box(room, root, "WestWallTop", Vector3(-room_size.x/2, room_size.y - 0.25, 0), 
			Vector3(WALL_THICKNESS, 0.5, room_size.z), wall_mat)
	add_box(room, root, "WestWallLeft", Vector3(-room_size.x/2, room_size.y/2, -2), 
			Vector3(WALL_THICKNESS, room_size.y - 0.5, 1), wall_mat)
	add_box(room, root, "WestWallRight", Vector3(-room_size.x/2, room_size.y/2, 2), 
			Vector3(WALL_THICKNESS, room_size.y - 0.5, 1), wall_mat)
	
	# Other walls
	add_box(room, root, "NorthWall", Vector3(0, room_size.y/2, -room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "SouthWall", Vector3(0, room_size.y/2, room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "EastWall", Vector3(room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	
	# Ceiling
	add_box(room, root, "Ceiling", Vector3(0, room_size.y, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Pipes
	var pipe_mat = StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.3, 0.3, 0.35)
	pipe_mat.metallic = 0.8
	add_box(room, root, "Pipe1", Vector3(0, 2.5, -2.3), Vector3(5, 0.3, 0.3), pipe_mat)
	add_box(room, root, "Pipe2", Vector3(-2.7, 1.5, 0), Vector3(0.3, 0.3, 4), pipe_mat)

func create_storage_room(root: Node3D, wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "StorageRoom"
	room.position = Vector3(10, 0, -10)
	root.add_child(room)
	room.owner = root
	
	var room_size = Vector3(4, CORRIDOR_HEIGHT, 6)
	
	# Floor
	add_box(room, root, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), floor_mat)
	
	# North wall with door
	add_box(room, root, "NorthWallLeft", Vector3(-1.5, room_size.y/2, -room_size.z/2), 
			Vector3(1, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "NorthWallRight", Vector3(1.5, room_size.y/2, -room_size.z/2), 
			Vector3(1, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "NorthWallTop", Vector3(0, room_size.y - 0.25, -room_size.z/2), 
			Vector3(2, 0.5, WALL_THICKNESS), wall_mat)
	
	# Other walls
	add_box(room, root, "SouthWall", Vector3(0, room_size.y/2, room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "EastWall", Vector3(room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	add_box(room, root, "WestWall", Vector3(-room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	
	# Ceiling
	add_box(room, root, "Ceiling", Vector3(0, room_size.y, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Shelves
	var shelf_mat = StandardMaterial3D.new()
	shelf_mat.albedo_color = Color(0.25, 0.25, 0.3)
	shelf_mat.metallic = 0.9
	for i in range(4):
		var y = 0.5 + i * 0.6
		add_box(room, root, "ShelfL%d" % i, Vector3(-1.7, y, 0), Vector3(0.5, 0.05, 5), shelf_mat)
		add_box(room, root, "ShelfR%d" % i, Vector3(1.7, y, 0), Vector3(0.5, 0.05, 5), shelf_mat)

func create_crew_quarters(root: Node3D, wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "CrewQuarters"
	room.position = Vector3(30, 0, -7.5)
	root.add_child(room)
	room.owner = root
	
	var room_size = Vector3(5, CORRIDOR_HEIGHT, 7)
	
	# Floor
	add_box(room, root, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), floor_mat)
	
	# West wall with door
	add_box(room, root, "WestWallTop", Vector3(-room_size.x/2, room_size.y - 0.25, 0), 
			Vector3(WALL_THICKNESS, 0.5, room_size.z), wall_mat)
	add_box(room, root, "WestWallLeft", Vector3(-room_size.x/2, room_size.y/2, -3), 
			Vector3(WALL_THICKNESS, room_size.y - 0.5, 1), wall_mat)
	add_box(room, root, "WestWallRight", Vector3(-room_size.x/2, room_size.y/2, 3), 
			Vector3(WALL_THICKNESS, room_size.y - 0.5, 1), wall_mat)
	
	# Other walls
	add_box(room, root, "NorthWall", Vector3(0, room_size.y/2, -room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "SouthWall", Vector3(0, room_size.y/2, room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, root, "EastWall", Vector3(room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	
	# Ceiling
	add_box(room, root, "Ceiling", Vector3(0, room_size.y, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Beds
	var bed_mat = StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.3, 0.3, 0.35)
	add_box(room, root, "Bed1Lower", Vector3(-1.5, 0.3, -2.5), Vector3(0.8, 0.1, 2), bed_mat)
	add_box(room, root, "Bed2Lower", Vector3(1.5, 0.3, -2.5), Vector3(0.8, 0.1, 2), bed_mat)
	
	# Lockers
	var locker_mat = StandardMaterial3D.new()
	locker_mat.albedo_color = Color(0.2, 0.2, 0.25)
	locker_mat.metallic = 0.9
	add_box(room, root, "Locker1", Vector3(-2, 1, 2), Vector3(0.6, 2, 0.8), locker_mat)
	add_box(room, root, "Locker2", Vector3(0, 1, 2), Vector3(0.6, 2, 0.8), locker_mat)
	add_box(room, root, "Locker3", Vector3(2, 1, 2), Vector3(0.6, 2, 0.8), locker_mat)

func create_vent_system(root: Node3D, grate_mat: Material):
	var vents = Node3D.new()
	vents.name = "VentSystem"
	root.add_child(vents)
	vents.owner = root
	
	# Main vent shaft
	add_box(vents, root, "MainShaft", Vector3(10, 3.5, 0), Vector3(20, 0.8, 0.8), grate_mat)
	
	# Vent openings
	add_vent_opening(vents, root, Vector3(5, 2.5, -1.5), grate_mat)
	add_vent_opening(vents, root, Vector3(10, 2.5, 9), grate_mat)
	add_vent_opening(vents, root, Vector3(20, 3, -7.5), grate_mat)

func add_vent_opening(parent: Node3D, root: Node3D, pos: Vector3, mat: Material):
	var opening = Node3D.new()
	opening.name = "VentOpening"
	opening.position = pos
	parent.add_child(opening)
	opening.owner = root
	
	add_box(opening, root, "Grate", Vector3.ZERO, Vector3(0.6, 0.6, 0.05), mat)

func add_lockers_and_hiding_spots(root: Node3D):
	var hiding = Node3D.new()
	hiding.name = "HidingSpots"
	root.add_child(hiding)
	hiding.owner = root
	
	var locker_mat = StandardMaterial3D.new()
	locker_mat.albedo_color = Color(0.25, 0.25, 0.3)
	locker_mat.metallic = 0.8
	
	# Corridor lockers
	add_locker(hiding, root, Vector3(3, 0, -5), locker_mat)
	add_locker(hiding, root, Vector3(15, 0, 2), locker_mat)
	add_locker(hiding, root, Vector3(25, 0, -7.5), locker_mat)

func add_locker(parent: Node3D, root: Node3D, pos: Vector3, mat: Material):
	var locker = Node3D.new()
	locker.name = "Locker"
	locker.position = pos
	parent.add_child(locker)
	locker.owner = root
	
	# Locker structure
	add_box(locker, root, "Back", Vector3(0, 1, -0.4), Vector3(0.6, 2, 0.05), mat)
	add_box(locker, root, "Left", Vector3(-0.3, 1, 0), Vector3(0.05, 2, 0.8), mat)
	add_box(locker, root, "Right", Vector3(0.3, 1, 0), Vector3(0.05, 2, 0.8), mat)
	add_box(locker, root, "Top", Vector3(0, 2, 0), Vector3(0.6, 0.05, 0.8), mat)
	add_box(locker, root, "Bottom", Vector3(0, 0.05, 0), Vector3(0.6, 0.05, 0.8), mat)
	add_box(locker, root, "Door", Vector3(0, 1, 0.4), Vector3(0.55, 1.9, 0.05), mat)

func add_emergency_lighting(root: Node3D):
	var lights = Node3D.new()
	lights.name = "EmergencyLights"
	root.add_child(lights)
	lights.owner = root
	
	# Red emergency lights
	var light_mat = StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.1, 0.1, 0.1)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.8, 0.1, 0.1)
	light_mat.emission_energy = 2.0
	
	var positions = [
		Vector3(5, 2.7, 0), Vector3(15, 2.7, 0),
		Vector3(20, 2.7, -5), Vector3(20, 2.7, -10),
		Vector3(10, 2.7, 5), Vector3(10, 2.7, -5)
	]
	
	for i in range(positions.size()):
		add_box(lights, root, "EmLight%d" % i, positions[i], 
				Vector3(0.3, 0.1, 0.15), light_mat)

func add_pipes_and_cables(root: Node3D):
	var details = Node3D.new()
	details.name = "PipesAndCables"
	root.add_child(details)
	details.owner = root
	
	var pipe_mat = StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.2, 0.2, 0.22)
	pipe_mat.metallic = 0.9
	
	# Ceiling pipes
	add_box(details, root, "CeilingPipe1", Vector3(10, 2.6, -0.8), 
			Vector3(20, 0.15, 0.15), pipe_mat)

func add_box(parent: Node3D, root: Node3D, name: String, pos: Vector3, size: Vector3, mat: Material):
	var body = StaticBody3D.new()
	body.name = name
	body.position = pos
	parent.add_child(body)
	body.owner = root
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	collision.owner = root
	
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	mesh_instance.owner = root