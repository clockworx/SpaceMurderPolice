@tool
extends Node3D

# Outlast Trials-style horror space station builder

const CORRIDOR_WIDTH = 2.5  # Narrow corridors
const CORRIDOR_HEIGHT = 2.8
const WALL_THICKNESS = 0.3

func _ready():
	if not Engine.is_editor_hint():
		build_horror_station()

func build_horror_station():
	print("Building horror space station...")
	
	# Dark metal materials
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
	
	# Main corridor system
	create_main_corridor(wall_mat, floor_mat)
	
	# Rooms
	create_security_checkpoint(wall_mat, floor_mat)
	create_medical_exam_room(wall_mat, floor_mat)
	create_maintenance_room(wall_mat, floor_mat)
	create_storage_room(wall_mat, floor_mat)
	create_crew_quarters(wall_mat, floor_mat)
	
	# Vents and hiding spots
	create_vent_system(grate_mat)
	add_lockers_and_hiding_spots()
	
	# Atmospheric elements
	add_emergency_lighting()
	add_pipes_and_cables()
	
	print("Horror station complete!")

func create_main_corridor(wall_mat: Material, floor_mat: Material):
	var corridor = Node3D.new()
	corridor.name = "MainCorridor"
	add_child(corridor)
	
	# L-shaped main corridor with multiple branches
	# Horizontal section
	add_corridor_section(corridor, Vector3(0, 0, 0), Vector3(20, 0, 0), wall_mat, floor_mat)
	
	# Vertical section
	add_corridor_section(corridor, Vector3(20, 0, 0), Vector3(20, 0, -15), wall_mat, floor_mat)
	
	# Left branch
	add_corridor_section(corridor, Vector3(10, 0, 0), Vector3(10, 0, 10), wall_mat, floor_mat)
	
	# Right branch  
	add_corridor_section(corridor, Vector3(10, 0, 0), Vector3(10, 0, -10), wall_mat, floor_mat)
	
	# Add T-junction
	add_corridor_section(corridor, Vector3(20, 0, -7.5), Vector3(30, 0, -7.5), wall_mat, floor_mat)

func add_corridor_section(parent: Node3D, start: Vector3, end: Vector3, wall_mat: Material, floor_mat: Material):
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	var center = (start + end) / 2
	
	var section = Node3D.new()
	section.name = "CorridorSection"
	section.position = center
	parent.add_child(section)
	
	# Floor
	var floor_size = Vector3(length if abs(direction.x) > 0 else CORRIDOR_WIDTH, 
							0.2, 
							length if abs(direction.z) > 0 else CORRIDOR_WIDTH)
	add_box(section, "Floor", Vector3(0, -0.1, 0), floor_size, floor_mat)
	
	# Walls
	if abs(direction.x) > 0:  # East-West corridor
		add_box(section, "NorthWall", Vector3(0, CORRIDOR_HEIGHT/2, -CORRIDOR_WIDTH/2), 
				Vector3(length, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
		add_box(section, "SouthWall", Vector3(0, CORRIDOR_HEIGHT/2, CORRIDOR_WIDTH/2), 
				Vector3(length, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	else:  # North-South corridor
		add_box(section, "EastWall", Vector3(CORRIDOR_WIDTH/2, CORRIDOR_HEIGHT/2, 0), 
				Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT, length), wall_mat)
		add_box(section, "WestWall", Vector3(-CORRIDOR_WIDTH/2, CORRIDOR_HEIGHT/2, 0), 
				Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT, length), wall_mat)
	
	# Ceiling with gaps for atmosphere
	var ceiling_size = floor_size
	ceiling_size.y = 0.1
	add_box(section, "Ceiling", Vector3(0, CORRIDOR_HEIGHT, 0), ceiling_size, wall_mat)

func create_security_checkpoint(wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "SecurityCheckpoint"
	room.position = Vector3(5, 0, 0)
	add_child(room)
	
	# Small 4x4 room with window
	var room_size = Vector3(4, CORRIDOR_HEIGHT, 4)
	
	# Floor
	add_box(room, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), floor_mat)
	
	# Walls with door opening
	# North wall with window
	add_box(room, "NorthWallLeft", Vector3(-1.5, CORRIDOR_HEIGHT/2, -2), 
			Vector3(1, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	add_box(room, "NorthWallRight", Vector3(1.5, CORRIDOR_HEIGHT/2, -2), 
			Vector3(1, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	add_box(room, "NorthWallTop", Vector3(0, CORRIDOR_HEIGHT - 0.5, -2), 
			Vector3(2, 1, WALL_THICKNESS), wall_mat)
	add_box(room, "NorthWallBottom", Vector3(0, 0.5, -2), 
			Vector3(2, 1, WALL_THICKNESS), wall_mat)
	
	# Other walls
	add_box(room, "SouthWall", Vector3(0, CORRIDOR_HEIGHT/2, 2), 
			Vector3(room_size.x, CORRIDOR_HEIGHT, WALL_THICKNESS), wall_mat)
	add_box(room, "EastWall", Vector3(2, CORRIDOR_HEIGHT/2, 0), 
			Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT, room_size.z), wall_mat)
	
	# West wall with door
	add_box(room, "WestWallTop", Vector3(-2, CORRIDOR_HEIGHT - 0.25, 0), 
			Vector3(WALL_THICKNESS, 0.5, room_size.z), wall_mat)
	add_box(room, "WestWallLeft", Vector3(-2, CORRIDOR_HEIGHT/2, -1.5), 
			Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT - 0.5, 1), wall_mat)
	add_box(room, "WestWallRight", Vector3(-2, CORRIDOR_HEIGHT/2, 1.5), 
			Vector3(WALL_THICKNESS, CORRIDOR_HEIGHT - 0.5, 1), wall_mat)
	
	# Ceiling
	add_box(room, "Ceiling", Vector3(0, CORRIDOR_HEIGHT, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Security desk
	var desk_mat = StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.2, 0.2, 0.25)
	add_box(room, "SecurityDesk", Vector3(0, 0.4, -0.5), Vector3(3, 0.8, 1), desk_mat)

func create_medical_exam_room(wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "MedicalExamRoom"
	room.position = Vector3(10, 0, 10)
	add_child(room)
	
	# 5x6 medical room
	var room_size = Vector3(5, CORRIDOR_HEIGHT, 6)
	
	# Floor - white tiles
	var med_floor_mat = StandardMaterial3D.new()
	med_floor_mat.albedo_color = Color(0.9, 0.9, 0.95)
	med_floor_mat.metallic = 0.2
	med_floor_mat.roughness = 0.3
	add_box(room, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), med_floor_mat)
	
	# Walls
	add_medical_walls(room, room_size, wall_mat)
	
	# Ceiling with surgical light
	add_box(room, "Ceiling", Vector3(0, CORRIDOR_HEIGHT, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Medical equipment
	add_medical_equipment(room)

func add_medical_walls(room: Node3D, size: Vector3, mat: Material):
	# North wall with door
	add_box(room, "NorthWallLeft", Vector3(-2, size.y/2, -size.z/2), 
			Vector3(1, size.y, WALL_THICKNESS), mat)
	add_box(room, "NorthWallRight", Vector3(1.5, size.y/2, -size.z/2), 
			Vector3(2, size.y, WALL_THICKNESS), mat)
	add_box(room, "NorthWallTop", Vector3(-0.25, size.y - 0.25, -size.z/2), 
			Vector3(2.5, 0.5, WALL_THICKNESS), mat)
	
	# Other walls solid
	add_box(room, "SouthWall", Vector3(0, size.y/2, size.z/2), 
			Vector3(size.x, size.y, WALL_THICKNESS), mat)
	add_box(room, "EastWall", Vector3(size.x/2, size.y/2, 0), 
			Vector3(WALL_THICKNESS, size.y, size.z), mat)
	add_box(room, "WestWall", Vector3(-size.x/2, size.y/2, 0), 
			Vector3(WALL_THICKNESS, size.y, size.z), mat)

func add_medical_equipment(room: Node3D):
	# Exam table
	var table_mat = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.7, 0.7, 0.8)
	table_mat.metallic = 0.9
	add_box(room, "ExamTable", Vector3(0, 0.5, 0), Vector3(2, 0.1, 0.7), table_mat)
	add_box(room, "TableLeg1", Vector3(-0.8, 0.25, -0.25), Vector3(0.1, 0.5, 0.1), table_mat)
	add_box(room, "TableLeg2", Vector3(0.8, 0.25, -0.25), Vector3(0.1, 0.5, 0.1), table_mat)
	add_box(room, "TableLeg3", Vector3(-0.8, 0.25, 0.25), Vector3(0.1, 0.5, 0.1), table_mat)
	add_box(room, "TableLeg4", Vector3(0.8, 0.25, 0.25), Vector3(0.1, 0.5, 0.1), table_mat)
	
	# Medical cabinet
	var cabinet_mat = StandardMaterial3D.new()
	cabinet_mat.albedo_color = Color(0.85, 0.85, 0.9)
	add_box(room, "MedCabinet", Vector3(2, 1, -2.5), Vector3(0.8, 2, 0.5), cabinet_mat)
	
	# Sink
	add_box(room, "Sink", Vector3(-2, 0.8, 2), Vector3(0.6, 0.2, 0.5), table_mat)

func create_maintenance_room(wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "MaintenanceRoom"
	room.position = Vector3(20, 0, -7.5)
	add_child(room)
	
	# 6x5 maintenance room with pipes and machinery
	var room_size = Vector3(6, CORRIDOR_HEIGHT + 0.5, 5)
	
	# Grated floor
	var grate_mat = StandardMaterial3D.new()
	grate_mat.albedo_color = Color(0.1, 0.1, 0.12)
	grate_mat.metallic = 0.95
	add_box(room, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), grate_mat)
	
	# Industrial walls
	create_maintenance_walls(room, room_size, wall_mat)
	
	# Pipes and machinery
	add_maintenance_equipment(room)

func create_maintenance_walls(room: Node3D, size: Vector3, mat: Material):
	# West wall with door
	add_box(room, "WestWallTop", Vector3(-size.x/2, size.y - 0.25, 0), 
			Vector3(WALL_THICKNESS, 0.5, size.z), mat)
	add_box(room, "WestWallLeft", Vector3(-size.x/2, size.y/2, -2), 
			Vector3(WALL_THICKNESS, size.y - 0.5, 1), mat)
	add_box(room, "WestWallRight", Vector3(-size.x/2, size.y/2, 2), 
			Vector3(WALL_THICKNESS, size.y - 0.5, 1), mat)
	
	# Other walls
	add_box(room, "NorthWall", Vector3(0, size.y/2, -size.z/2), 
			Vector3(size.x, size.y, WALL_THICKNESS), mat)
	add_box(room, "SouthWall", Vector3(0, size.y/2, size.z/2), 
			Vector3(size.x, size.y, WALL_THICKNESS), mat)
	add_box(room, "EastWall", Vector3(size.x/2, size.y/2, 0), 
			Vector3(WALL_THICKNESS, size.y, size.z), mat)
	
	# Lower ceiling for claustrophobia
	add_box(room, "Ceiling", Vector3(0, size.y, 0), 
			Vector3(size.x, 0.1, size.z), mat)

func add_maintenance_equipment(room: Node3D):
	var pipe_mat = StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.3, 0.3, 0.35)
	pipe_mat.metallic = 0.8
	
	# Large pipes along walls
	add_box(room, "Pipe1", Vector3(0, 2.5, -2.3), Vector3(5, 0.3, 0.3), pipe_mat)
	add_box(room, "Pipe2", Vector3(-2.7, 1.5, 0), Vector3(0.3, 0.3, 4), pipe_mat)
	add_box(room, "Pipe3", Vector3(2.7, 2.2, 0), Vector3(0.3, 0.2, 4), pipe_mat)
	
	# Vertical pipes
	add_box(room, "VertPipe1", Vector3(-2, 1.5, -2), Vector3(0.2, 3, 0.2), pipe_mat)
	add_box(room, "VertPipe2", Vector3(2, 1.5, 2), Vector3(0.2, 3, 0.2), pipe_mat)
	
	# Control panel
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.2, 0.25, 0.3)
	panel_mat.metallic = 0.7
	panel_mat.emission_enabled = true
	panel_mat.emission = Color(0.1, 0.2, 0.3)
	panel_mat.emission_energy = 0.5
	add_box(room, "ControlPanel", Vector3(0, 1, -2.3), Vector3(2, 1.5, 0.2), panel_mat)
	
	# Steam/gas effect areas (just geometry markers)
	var steam_mat = StandardMaterial3D.new()
	steam_mat.albedo_color = Color(0.7, 0.7, 0.7, 0.3)
	steam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_box(room, "SteamArea1", Vector3(-1.5, 1, 0), Vector3(0.5, 2, 0.5), steam_mat)

func create_storage_room(wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "StorageRoom"
	room.position = Vector3(10, 0, -10)
	add_child(room)
	
	# 4x6 storage room with shelves
	var room_size = Vector3(4, CORRIDOR_HEIGHT, 6)
	
	# Floor
	add_box(room, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), floor_mat)
	
	# Walls with door on north
	add_box(room, "NorthWallLeft", Vector3(-1.5, room_size.y/2, -room_size.z/2), 
			Vector3(1, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, "NorthWallRight", Vector3(1.5, room_size.y/2, -room_size.z/2), 
			Vector3(1, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, "NorthWallTop", Vector3(0, room_size.y - 0.25, -room_size.z/2), 
			Vector3(2, 0.5, WALL_THICKNESS), wall_mat)
			
	add_box(room, "SouthWall", Vector3(0, room_size.y/2, room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, "EastWall", Vector3(room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	add_box(room, "WestWall", Vector3(-room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	
	# Ceiling
	add_box(room, "Ceiling", Vector3(0, room_size.y, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Shelving units
	add_storage_shelves(room)

func add_storage_shelves(room: Node3D):
	var shelf_mat = StandardMaterial3D.new()
	shelf_mat.albedo_color = Color(0.25, 0.25, 0.3)
	shelf_mat.metallic = 0.9
	
	# Left shelving unit
	for i in range(4):
		var y = 0.5 + i * 0.6
		add_box(room, "ShelfL%d" % i, Vector3(-1.7, y, 0), Vector3(0.5, 0.05, 5), shelf_mat)
	
	# Right shelving unit  
	for i in range(4):
		var y = 0.5 + i * 0.6
		add_box(room, "ShelfR%d" % i, Vector3(1.7, y, 0), Vector3(0.5, 0.05, 5), shelf_mat)
	
	# Crates and boxes
	var crate_mat = StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.4, 0.35, 0.3)
	add_box(room, "Crate1", Vector3(-1.7, 1.2, -1.5), Vector3(0.4, 0.4, 0.4), crate_mat)
	add_box(room, "Crate2", Vector3(1.7, 0.2, 0.5), Vector3(0.4, 0.4, 0.4), crate_mat)
	add_box(room, "Crate3", Vector3(-1.7, 0.2, 2), Vector3(0.4, 0.4, 0.4), crate_mat)

func create_crew_quarters(wall_mat: Material, floor_mat: Material):
	var room = Node3D.new()
	room.name = "CrewQuarters"
	room.position = Vector3(30, 0, -7.5)
	add_child(room)
	
	# 5x7 crew quarters with beds
	var room_size = Vector3(5, CORRIDOR_HEIGHT, 7)
	
	# Floor
	add_box(room, "Floor", Vector3(0, -0.1, 0), Vector3(room_size.x, 0.2, room_size.z), floor_mat)
	
	# Walls with door on west
	add_box(room, "WestWallTop", Vector3(-room_size.x/2, room_size.y - 0.25, 0), 
			Vector3(WALL_THICKNESS, 0.5, room_size.z), wall_mat)
	add_box(room, "WestWallLeft", Vector3(-room_size.x/2, room_size.y/2, -3), 
			Vector3(WALL_THICKNESS, room_size.y - 0.5, 1), wall_mat)
	add_box(room, "WestWallRight", Vector3(-room_size.x/2, room_size.y/2, 3), 
			Vector3(WALL_THICKNESS, room_size.y - 0.5, 1), wall_mat)
			
	add_box(room, "NorthWall", Vector3(0, room_size.y/2, -room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, "SouthWall", Vector3(0, room_size.y/2, room_size.z/2), 
			Vector3(room_size.x, room_size.y, WALL_THICKNESS), wall_mat)
	add_box(room, "EastWall", Vector3(room_size.x/2, room_size.y/2, 0), 
			Vector3(WALL_THICKNESS, room_size.y, room_size.z), wall_mat)
	
	# Ceiling
	add_box(room, "Ceiling", Vector3(0, room_size.y, 0), 
			Vector3(room_size.x, 0.1, room_size.z), wall_mat)
	
	# Beds and furniture
	add_crew_furniture(room)

func add_crew_furniture(room: Node3D):
	var bed_mat = StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.3, 0.3, 0.35)
	
	# Bunk beds
	# Lower bunks
	add_box(room, "Bed1Lower", Vector3(-1.5, 0.3, -2.5), Vector3(0.8, 0.1, 2), bed_mat)
	add_box(room, "Bed2Lower", Vector3(1.5, 0.3, -2.5), Vector3(0.8, 0.1, 2), bed_mat)
	
	# Upper bunks
	add_box(room, "Bed1Upper", Vector3(-1.5, 1.5, -2.5), Vector3(0.8, 0.1, 2), bed_mat)
	add_box(room, "Bed2Upper", Vector3(1.5, 1.5, -2.5), Vector3(0.8, 0.1, 2), bed_mat)
	
	# Bunk frames
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.2, 0.2, 0.25)
	frame_mat.metallic = 0.9
	add_box(room, "Frame1", Vector3(-1.5, 0.9, -1.5), Vector3(0.05, 1.8, 0.05), frame_mat)
	add_box(room, "Frame2", Vector3(-1.5, 0.9, -3.5), Vector3(0.05, 1.8, 0.05), frame_mat)
	add_box(room, "Frame3", Vector3(1.5, 0.9, -1.5), Vector3(0.05, 1.8, 0.05), frame_mat)
	add_box(room, "Frame4", Vector3(1.5, 0.9, -3.5), Vector3(0.05, 1.8, 0.05), frame_mat)
	
	# Lockers (hiding spots)
	add_box(room, "Locker1", Vector3(-2, 1, 2), Vector3(0.6, 2, 0.8), frame_mat)
	add_box(room, "Locker2", Vector3(0, 1, 2), Vector3(0.6, 2, 0.8), frame_mat)
	add_box(room, "Locker3", Vector3(2, 1, 2), Vector3(0.6, 2, 0.8), frame_mat)

func create_vent_system(grate_mat: Material):
	var vents = Node3D.new()
	vents.name = "VentSystem"
	add_child(vents)
	
	# Main vent shaft running above corridor
	add_box(vents, "MainShaft", Vector3(10, 3.5, 0), Vector3(20, 0.8, 0.8), grate_mat)
	
	# Vent openings in rooms
	add_vent_opening(vents, Vector3(5, 2.5, -1.5), grate_mat)  # Security
	add_vent_opening(vents, Vector3(10, 2.5, 9), grate_mat)    # Medical
	add_vent_opening(vents, Vector3(20, 3, -7.5), grate_mat)   # Maintenance
	add_vent_opening(vents, Vector3(30, 2.5, -7.5), grate_mat) # Crew quarters

func add_vent_opening(parent: Node3D, pos: Vector3, mat: Material):
	var opening = Node3D.new()
	opening.name = "VentOpening"
	opening.position = pos
	parent.add_child(opening)
	
	# Vent grate
	add_box(opening, "Grate", Vector3.ZERO, Vector3(0.6, 0.6, 0.05), mat)
	
	# Vent shaft connection
	add_box(opening, "Shaft", Vector3(0, 0, -0.4), Vector3(0.5, 0.5, 0.8), mat)

func add_lockers_and_hiding_spots():
	var hiding = Node3D.new()
	hiding.name = "HidingSpots"
	add_child(hiding)
	
	var locker_mat = StandardMaterial3D.new()
	locker_mat.albedo_color = Color(0.25, 0.25, 0.3)
	locker_mat.metallic = 0.8
	
	# Corridor lockers
	add_locker(hiding, Vector3(3, 0, -5), locker_mat)
	add_locker(hiding, Vector3(15, 0, 2), locker_mat)
	add_locker(hiding, Vector3(25, 0, -7.5), locker_mat)
	
	# Under-desk hiding spots are created with the desks

func add_locker(parent: Node3D, pos: Vector3, mat: Material):
	var locker = Node3D.new()
	locker.name = "Locker"
	locker.position = pos
	parent.add_child(locker)
	
	# Locker body (hollow for hiding)
	add_box(locker, "Back", Vector3(0, 1, -0.4), Vector3(0.6, 2, 0.05), mat)
	add_box(locker, "Left", Vector3(-0.3, 1, 0), Vector3(0.05, 2, 0.8), mat)
	add_box(locker, "Right", Vector3(0.3, 1, 0), Vector3(0.05, 2, 0.8), mat)
	add_box(locker, "Top", Vector3(0, 2, 0), Vector3(0.6, 0.05, 0.8), mat)
	add_box(locker, "Bottom", Vector3(0, 0.05, 0), Vector3(0.6, 0.05, 0.8), mat)
	
	# Door (separate for interaction)
	add_box(locker, "Door", Vector3(0, 1, 0.4), Vector3(0.55, 1.9, 0.05), mat)

func add_emergency_lighting():
	var lights = Node3D.new()
	lights.name = "EmergencyLights"
	add_child(lights)
	
	# Red emergency light material
	var light_mat = StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.1, 0.1, 0.1)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.8, 0.1, 0.1)
	light_mat.emission_energy = 2.0
	
	# Place emergency lights along corridors
	var light_positions = [
		Vector3(5, 2.7, 0),
		Vector3(15, 2.7, 0),
		Vector3(20, 2.7, -5),
		Vector3(20, 2.7, -10),
		Vector3(10, 2.7, 5),
		Vector3(10, 2.7, -5),
		Vector3(25, 2.7, -7.5),
		Vector3(30, 2.7, -7.5)
	]
	
	for i in range(light_positions.size()):
		add_box(lights, "EmLight%d" % i, light_positions[i], 
				Vector3(0.3, 0.1, 0.15), light_mat)

func add_pipes_and_cables():
	var details = Node3D.new()
	details.name = "PipesAndCables"
	add_child(details)
	
	var pipe_mat = StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.2, 0.2, 0.22)
	pipe_mat.metallic = 0.9
	
	var cable_mat = StandardMaterial3D.new()
	cable_mat.albedo_color = Color(0.15, 0.15, 0.15)
	
	# Ceiling pipes along main corridor
	add_box(details, "CeilingPipe1", Vector3(10, 2.6, -0.8), 
			Vector3(20, 0.15, 0.15), pipe_mat)
	add_box(details, "CeilingPipe2", Vector3(10, 2.6, 0.8), 
			Vector3(20, 0.1, 0.1), cable_mat)
	
	# Vertical pipes in corners
	add_box(details, "VertPipe1", Vector3(0, 1.4, -1.2), Vector3(0.2, 2.8, 0.2), pipe_mat)
	add_box(details, "VertPipe2", Vector3(20, 1.4, -1.2), Vector3(0.2, 2.8, 0.2), pipe_mat)

func add_box(parent: Node3D, name: String, pos: Vector3, size: Vector3, mat: Material):
	var body = StaticBody3D.new()
	body.name = name
	body.position = pos
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
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	
	# Set owner for scene saving
	if Engine.is_editor_hint() and get_tree():
		var scene_root = get_tree().edited_scene_root
		if scene_root:
			body.owner = scene_root
			collision.owner = scene_root
			mesh_instance.owner = scene_root