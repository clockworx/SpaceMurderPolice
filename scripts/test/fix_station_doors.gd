@tool
extends Node3D

# Script to fix doors in the simple_station scene by adding proper openings

@export var fix_doors: bool = false : set = set_fix_doors

func set_fix_doors(value: bool):
	if value and Engine.is_editor_hint():
		fix_all_doors()
		fix_doors = false

func fix_all_doors():
	print("Fixing station doors...")
	
	# Find the station root
	var station = get_node_or_null("ThreeLevelStation")
	if not station:
		push_error("ThreeLevelStation not found!")
		return
	
	# Fix Docking Bay door
	fix_docking_bay_door(station)
	
	# Fix Medical Bay door  
	fix_medical_bay_door(station)
	
	# Fix Command Center door
	fix_command_center_door(station)
	
	# Fix stairwell doors
	fix_stairwell_doors(station)
	
	print("Door fixes complete!")

func fix_docking_bay_door(station: Node3D):
	var docking_bay = station.get_node_or_null("Deck1_Operations/DockingBay")
	if not docking_bay:
		return
		
	print("Fixing Docking Bay door...")
	
	# Remove the existing room combiner approach
	var room = docking_bay.get_node_or_null("Room")
	if room:
		room.queue_free()
	
	# Create individual walls with doorway
	create_room_with_door(docking_bay, "north", Color(0.5, 0.5, 0.6))

func fix_medical_bay_door(station: Node3D):
	var medical_bay = station.get_node_or_null("Deck1_Operations/MedicalBay")
	if not medical_bay:
		return
		
	print("Fixing Medical Bay door...")
	
	var room = medical_bay.get_node_or_null("Room")
	if room:
		room.queue_free()
	
	create_room_with_door(medical_bay, "east", Color(0.8, 0.8, 0.9))

func fix_command_center_door(station: Node3D):
	var command = station.get_node_or_null("Deck1_Operations/CommandCenter")
	if not command:
		return
		
	print("Fixing Command Center door...")
	
	var room = command.get_node_or_null("Room")
	if room:
		room.queue_free()
	
	create_room_with_door(command, "west", Color(0.8, 0.7, 0.6))

func create_room_with_door(parent: Node3D, door_side: String, wall_color: Color):
	var walls = Node3D.new()
	walls.name = "Walls"
	parent.add_child(walls)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = wall_color
	mat.metallic = 0.7
	mat.roughness = 0.4
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.3, 0.35)
	floor_mat.metallic = 0.8
	floor_mat.roughness = 0.4
	
	# Floor
	var floor = CSGBox3D.new()
	floor.name = "Floor"
	floor.size = Vector3(12, 0.2, 12)
	floor.position = Vector3(0, -0.1, 0)
	floor.use_collision = true
	floor.material = floor_mat
	walls.add_child(floor)
	
	# Create walls based on door position
	if door_side == "north":
		# North wall with door gap
		create_wall_with_gap(walls, Vector3(-4.5, 1.75, -6), Vector3(3, 3.5, 0.3), mat)  # Left of door
		create_wall_with_gap(walls, Vector3(4.5, 1.75, -6), Vector3(3, 3.5, 0.3), mat)   # Right of door
		create_wall_with_gap(walls, Vector3(0, 3.25, -6), Vector3(3, 0.5, 0.3), mat)     # Above door
		
		# Other solid walls
		create_solid_wall(walls, Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), mat)    # South
		create_solid_wall(walls, Vector3(6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)    # East
		create_solid_wall(walls, Vector3(-6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)   # West
		
	elif door_side == "east":
		# East wall with door gap
		create_wall_with_gap(walls, Vector3(6, 1.75, -4.5), Vector3(0.3, 3.5, 3), mat)  # Left of door
		create_wall_with_gap(walls, Vector3(6, 1.75, 4.5), Vector3(0.3, 3.5, 3), mat)   # Right of door
		create_wall_with_gap(walls, Vector3(6, 3.25, 0), Vector3(0.3, 0.5, 3), mat)     # Above door
		
		# Other solid walls
		create_solid_wall(walls, Vector3(0, 1.75, -6), Vector3(12, 3.5, 0.3), mat)   # North
		create_solid_wall(walls, Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), mat)    # South
		create_solid_wall(walls, Vector3(-6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)   # West
		
	elif door_side == "west":
		# West wall with door gap
		create_wall_with_gap(walls, Vector3(-6, 1.75, -4.5), Vector3(0.3, 3.5, 3), mat)  # Left of door
		create_wall_with_gap(walls, Vector3(-6, 1.75, 4.5), Vector3(0.3, 3.5, 3), mat)   # Right of door
		create_wall_with_gap(walls, Vector3(-6, 3.25, 0), Vector3(0.3, 0.5, 3), mat)     # Above door
		
		# Other solid walls
		create_solid_wall(walls, Vector3(0, 1.75, -6), Vector3(12, 3.5, 0.3), mat)   # North
		create_solid_wall(walls, Vector3(0, 1.75, 6), Vector3(12, 3.5, 0.3), mat)    # South
		create_solid_wall(walls, Vector3(6, 1.75, 0), Vector3(0.3, 3.5, 12), mat)    # East
	
	# Ceiling
	var ceiling = CSGBox3D.new()
	ceiling.name = "Ceiling"
	ceiling.size = Vector3(12, 0.2, 12)
	ceiling.position = Vector3(0, 3.6, 0)
	ceiling.use_collision = true
	ceiling.material = mat
	walls.add_child(ceiling)
	
	# Set owner for saving
	if Engine.is_editor_hint():
		set_owner_recursive(walls, get_tree().edited_scene_root)

func create_solid_wall(parent: Node3D, pos: Vector3, size: Vector3, mat: Material):
	var wall = CSGBox3D.new()
	wall.position = pos
	wall.size = size
	wall.use_collision = true
	wall.material = mat
	parent.add_child(wall)

func create_wall_with_gap(parent: Node3D, pos: Vector3, size: Vector3, mat: Material):
	var wall = CSGBox3D.new()
	wall.position = pos
	wall.size = size
	wall.use_collision = true
	wall.material = mat
	parent.add_child(wall)

func fix_stairwell_doors(station: Node3D):
	# The stairwell already has door cuts in the shaft, but let's make them bigger
	var shaft = station.get_node_or_null("CentralStairwell/Shaft")
	if not shaft:
		return
		
	print("Fixing stairwell doors...")
	
	# Find and enlarge existing door cuts
	for child in shaft.get_children():
		if child.name.contains("Door") and child.operation == CSGShape3D.OPERATION_SUBTRACTION:
			# Make door cuts bigger
			child.size = Vector3(3.5, 3.2, 3)  # Wider and deeper

func set_owner_recursive(node: Node, owner: Node):
	if not owner:
		return
	node.owner = owner
	for child in node.get_children():
		set_owner_recursive(child, owner)