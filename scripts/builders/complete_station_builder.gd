extends Node3D

# This script builds the complete 3-level station with all rooms

func build_complete_station():
	print("Building complete 3-level station...")
	
	# Create deck containers
	var deck1 = Node3D.new()
	deck1.name = "Deck1_Operations"
	add_child(deck1)
	
	var deck2 = Node3D.new()
	deck2.name = "Deck2_Living"
	deck2.position.y = 4
	add_child(deck2)
	
	var deck3 = Node3D.new()
	deck3.name = "Deck3_Engineering"
	deck3.position.y = 8
	add_child(deck3)
	
	# Build Deck 1 rooms
	create_room(deck1, "DockingBay", Vector3(-15, 0, 15), Color(0.5, 0.5, 0.6), "north")
	create_room(deck1, "MedicalBay", Vector3(-15, 0, 0), Color(0.8, 0.8, 0.9), "east")
	create_room(deck1, "CommandCenter", Vector3(0, 0, -15), Color(0.8, 0.7, 0.6), "south")
	create_room(deck1, "ScienceLab", Vector3(15, 0, -15), Color(0.6, 0.8, 0.9), "west")
	create_room(deck1, "SecurityOffice", Vector3(15, 0, 0), Color(0.9, 0.6, 0.6), "west")
	create_room(deck1, "DataCenter", Vector3(15, 0, 15), Color(0.7, 0.9, 0.7), "south")
	
	# Build Deck 2 rooms
	create_room(deck2, "CrewQuartersA", Vector3(-15, 0, 15), Color(0.9, 0.8, 0.7), "north")
	create_room(deck2, "CrewQuartersB", Vector3(-15, 0, 0), Color(0.9, 0.8, 0.7), "east")
	create_room(deck2, "MessHall", Vector3(0, 0, -15), Color(0.7, 0.8, 0.7), "south")
	create_room(deck2, "RecreationRoom", Vector3(15, 0, -15), Color(0.8, 0.7, 0.9), "west")
	create_room(deck2, "Gymnasium", Vector3(15, 0, 0), Color(0.9, 0.9, 0.8), "west")
	create_room(deck2, "Hydroponics", Vector3(15, 0, 15), Color(0.7, 0.9, 0.8), "south")
	
	# Build Deck 3 rooms
	create_room(deck3, "MainEngineering", Vector3(-15, 0, 15), Color(0.8, 0.6, 0.4), "north")
	create_room(deck3, "ReactorRoom", Vector3(-15, 0, 0), Color(0.9, 0.5, 0.5), "east")
	create_room(deck3, "LifeSupport", Vector3(0, 0, -15), Color(0.6, 0.9, 0.6), "south")
	create_room(deck3, "ShieldGenerator", Vector3(15, 0, -15), Color(0.6, 0.8, 0.9), "west")
	create_room(deck3, "Navigation", Vector3(15, 0, 0), Color(0.7, 0.7, 0.9), "west")
	create_room(deck3, "Communications", Vector3(15, 0, 15), Color(0.8, 0.9, 0.7), "south")
	
	# Build central stairwell
	create_central_stairwell()
	
	# Add corridors connecting rooms to stairwell
	create_corridors()
	
	print("Station construction complete!")

func create_room(parent: Node3D, room_name: String, position: Vector3, color: Color, door_side: String):
	var room = Node3D.new()
	room.name = room_name
	room.position = position
	parent.add_child(room)
	
	var room_size = Vector3(12, 3.5, 12)
	var wall_thickness = 0.3
	var door_width = 3.0
	var door_height = 2.8
	
	# Floor
	var floor = create_static_body_with_mesh(Vector3(12, 0.2, 12), Vector3(0, -0.1, 0))
	floor.name = "Floor"
	room.add_child(floor)
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.3, 0.35)
	floor_mat.metallic = 0.8
	floor.get_node("MeshInstance3D").material_override = floor_mat
	
	# Ceiling
	var ceiling = create_static_body_with_mesh(Vector3(12, 0.2, 12), Vector3(0, 3.6, 0))
	ceiling.name = "Ceiling"
	room.add_child(ceiling)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.7
	ceiling.get_node("MeshInstance3D").material_override = mat
	
	# Create walls with door opening
	if door_side == "north":
		# North wall with door
		var left = create_static_body_with_mesh(Vector3(4.5, 3.5, 0.3), Vector3(-3.75, 1.75, -6))
		left.name = "NorthWallLeft"
		room.add_child(left)
		left.get_node("MeshInstance3D").material_override = mat
		
		var right = create_static_body_with_mesh(Vector3(4.5, 3.5, 0.3), Vector3(3.75, 1.75, -6))
		right.name = "NorthWallRight"
		room.add_child(right)
		right.get_node("MeshInstance3D").material_override = mat
		
		var top = create_static_body_with_mesh(Vector3(3, 0.5, 0.3), Vector3(0, 3.25, -6))
		top.name = "NorthWallTop"
		room.add_child(top)
		top.get_node("MeshInstance3D").material_override = mat
		
		# Other walls solid
		create_solid_wall(room, "SouthWall", Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), mat)
		create_solid_wall(room, "EastWall", Vector3(6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)
		create_solid_wall(room, "WestWall", Vector3(-6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)
		
	elif door_side == "east":
		# East wall with door
		var left = create_static_body_with_mesh(Vector3(0.3, 3.5, 4.5), Vector3(6, 1.75, -3.75))
		left.name = "EastWallLeft"
		room.add_child(left)
		left.get_node("MeshInstance3D").material_override = mat
		
		var right = create_static_body_with_mesh(Vector3(0.3, 3.5, 4.5), Vector3(6, 1.75, 3.75))
		right.name = "EastWallRight"
		room.add_child(right)
		right.get_node("MeshInstance3D").material_override = mat
		
		var top = create_static_body_with_mesh(Vector3(0.3, 0.5, 3), Vector3(6, 3.25, 0))
		top.name = "EastWallTop"
		room.add_child(top)
		top.get_node("MeshInstance3D").material_override = mat
		
		# Other walls solid
		create_solid_wall(room, "NorthWall", Vector3(0, 1.75, -6), Vector3(12, 3.5, 0.3), mat)
		create_solid_wall(room, "SouthWall", Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), mat)
		create_solid_wall(room, "WestWall", Vector3(-6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)
		
	elif door_side == "south":
		# South wall with door
		var left = create_static_body_with_mesh(Vector3(4.5, 3.5, 0.3), Vector3(-3.75, 1.75, 6))
		left.name = "SouthWallLeft"
		room.add_child(left)
		left.get_node("MeshInstance3D").material_override = mat
		
		var right = create_static_body_with_mesh(Vector3(4.5, 3.5, 0.3), Vector3(3.75, 1.75, 6))
		right.name = "SouthWallRight"
		room.add_child(right)
		right.get_node("MeshInstance3D").material_override = mat
		
		var top = create_static_body_with_mesh(Vector3(3, 0.5, 0.3), Vector3(0, 3.25, 6))
		top.name = "SouthWallTop"
		room.add_child(top)
		top.get_node("MeshInstance3D").material_override = mat
		
		# Other walls solid
		create_solid_wall(room, "NorthWall", Vector3(0, 1.75, -6), Vector3(12, 3.5, 0.3), mat)
		create_solid_wall(room, "EastWall", Vector3(6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)
		create_solid_wall(room, "WestWall", Vector3(-6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)
		
	elif door_side == "west":
		# West wall with door
		var left = create_static_body_with_mesh(Vector3(0.3, 3.5, 4.5), Vector3(-6, 1.75, -3.75))
		left.name = "WestWallLeft"
		room.add_child(left)
		left.get_node("MeshInstance3D").material_override = mat
		
		var right = create_static_body_with_mesh(Vector3(0.3, 3.5, 4.5), Vector3(-6, 1.75, 3.75))
		right.name = "WestWallRight"
		room.add_child(right)
		right.get_node("MeshInstance3D").material_override = mat
		
		var top = create_static_body_with_mesh(Vector3(0.3, 0.5, 3), Vector3(-6, 3.25, 0))
		top.name = "WestWallTop"
		room.add_child(top)
		top.get_node("MeshInstance3D").material_override = mat
		
		# Other walls solid
		create_solid_wall(room, "NorthWall", Vector3(0, 1.75, -6), Vector3(12, 3.5, 0.3), mat)
		create_solid_wall(room, "SouthWall", Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), mat)
		create_solid_wall(room, "EastWall", Vector3(6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)

func create_solid_wall(parent: Node3D, name: String, pos: Vector3, size: Vector3, mat: Material):
	var wall = create_static_body_with_mesh(size, pos)
	wall.name = name
	parent.add_child(wall)
	wall.get_node("MeshInstance3D").material_override = mat

func create_static_body_with_mesh(size: Vector3, position: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = position
	
	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	
	var mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	body.add_child(mesh)
	
	return body

func create_central_stairwell():
	var stairwell = Node3D.new()
	stairwell.name = "CentralStairwell"
	add_child(stairwell)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.5)
	mat.metallic = 0.9
	
	# Create stairwell shaft (6x6 area in center)
	for i in range(3):
		var y_pos = i * 4
		
		# Floor with hole for stairs
		var floor_parts = []
		floor_parts.append(create_static_body_with_mesh(Vector3(6, 0.2, 2), Vector3(0, y_pos - 0.1, -2)))
		floor_parts.append(create_static_body_with_mesh(Vector3(6, 0.2, 2), Vector3(0, y_pos - 0.1, 2)))
		floor_parts.append(create_static_body_with_mesh(Vector3(2, 0.2, 2), Vector3(-2, y_pos - 0.1, 0)))
		floor_parts.append(create_static_body_with_mesh(Vector3(2, 0.2, 2), Vector3(2, y_pos - 0.1, 0)))
		
		for part in floor_parts:
			part.name = "Deck%d_Floor" % (i + 1)
			stairwell.add_child(part)
			part.get_node("MeshInstance3D").material_override = mat
		
		# Walls around stairwell with door openings
		if i < 3:  # All decks have doors
			# North wall with door
			var north_left = create_static_body_with_mesh(Vector3(1.5, 3.5, 0.3), Vector3(-2.25, y_pos + 1.75, -3))
			north_left.name = "Deck%d_NorthLeft" % (i + 1)
			stairwell.add_child(north_left)
			north_left.get_node("MeshInstance3D").material_override = mat
			
			var north_right = create_static_body_with_mesh(Vector3(1.5, 3.5, 0.3), Vector3(2.25, y_pos + 1.75, -3))
			north_right.name = "Deck%d_NorthRight" % (i + 1)
			stairwell.add_child(north_right)
			north_right.get_node("MeshInstance3D").material_override = mat
			
			# South wall with door
			var south_left = create_static_body_with_mesh(Vector3(1.5, 3.5, 0.3), Vector3(-2.25, y_pos + 1.75, 3))
			south_left.name = "Deck%d_SouthLeft" % (i + 1)
			stairwell.add_child(south_left)
			south_left.get_node("MeshInstance3D").material_override = mat
			
			var south_right = create_static_body_with_mesh(Vector3(1.5, 3.5, 0.3), Vector3(2.25, y_pos + 1.75, 3))
			south_right.name = "Deck%d_SouthRight" % (i + 1)
			stairwell.add_child(south_right)
			south_right.get_node("MeshInstance3D").material_override = mat
			
			# East and West walls solid
			var east = create_static_body_with_mesh(Vector3(0.3, 3.5, 6), Vector3(3, y_pos + 1.75, 0))
			east.name = "Deck%d_East" % (i + 1)
			stairwell.add_child(east)
			east.get_node("MeshInstance3D").material_override = mat
			
			var west = create_static_body_with_mesh(Vector3(0.3, 3.5, 6), Vector3(-3, y_pos + 1.75, 0))
			west.name = "Deck%d_West" % (i + 1)
			stairwell.add_child(west)
			west.get_node("MeshInstance3D").material_override = mat
	
	# Create stairs between decks
	create_stairs(stairwell, 0, 4)  # Deck 1 to 2
	create_stairs(stairwell, 4, 8)  # Deck 2 to 3

func create_stairs(parent: Node3D, start_y: float, end_y: float):
	var steps = 8
	var step_height = (end_y - start_y) / steps
	var step_depth = 0.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5)
	mat.metallic = 0.8
	
	for i in range(steps):
		var step = create_static_body_with_mesh(
			Vector3(2, 0.2, step_depth),
			Vector3(0, start_y + (i * step_height), -1.5 + (i * step_depth))
		)
		step.name = "Step_%d" % i
		parent.add_child(step)
		step.get_node("MeshInstance3D").material_override = mat

func create_corridors():
	# Create corridors connecting rooms to central stairwell
	var corridor_mat = StandardMaterial3D.new()
	corridor_mat.albedo_color = Color(0.5, 0.5, 0.5)
	corridor_mat.metallic = 0.7
	
	# Deck 1 corridors
	create_corridor(Vector3(-7.5, 0, 9), Vector3(15, 0.2, 3), corridor_mat)  # Docking Bay to center
	create_corridor(Vector3(-7.5, 0, 0), Vector3(15, 0.2, 3), corridor_mat)  # Medical Bay to center
	create_corridor(Vector3(0, 0, -7.5), Vector3(3, 0.2, 15), corridor_mat)  # Command Center to center
	create_corridor(Vector3(7.5, 0, -7.5), Vector3(15, 0.2, 3), corridor_mat)  # Science Lab to center
	create_corridor(Vector3(7.5, 0, 0), Vector3(15, 0.2, 3), corridor_mat)  # Security to center
	create_corridor(Vector3(7.5, 0, 7.5), Vector3(15, 0.2, 3), corridor_mat)  # Data Center to center
	
	# Similar for Deck 2 and 3...

func create_corridor(position: Vector3, size: Vector3, mat: Material):
	var corridor = create_static_body_with_mesh(size, position)
	corridor.name = "Corridor"
	add_child(corridor)
	corridor.get_node("MeshInstance3D").material_override = mat