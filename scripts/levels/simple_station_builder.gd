@tool
extends Node3D
class_name SimpleStationBuilder

# 3-Level Space Station Builder - Fixed doors, clean rooms, proper stairs

@export_group("Build Settings")
@export var auto_build: bool = true
@export var station_width: float = 60.0
@export var station_depth: float = 60.0
@export var deck_height: float = 4.0

@export_group("Editor Actions")
@export var rebuild: bool = false : set = set_rebuild
@export var clear_all: bool = false : set = set_clear_all

var station_root: Node3D
var deck_levels: Dictionary = {}

func _ready():
	if auto_build:
		build_station()

func set_rebuild(value: bool):
	if value and Engine.is_editor_hint():
		build_station()
		rebuild = false

func set_clear_all(value: bool):
	if value and Engine.is_editor_hint():
		clear_station()
		clear_all = false

func clear_station():
	if station_root and is_instance_valid(station_root):
		station_root.queue_free()
		station_root = null

func build_station():
	print("Building 3-level station with fixes...")
	
	# Initialize deck levels
	deck_levels = {
		"Deck1_Operations": 0.0,
		"Deck2_Living": 4.0,
		"Deck3_Engineering": 8.0
	}
	
	# Clear any existing station
	clear_station()
	
	# Create root
	station_root = Node3D.new()
	station_root.name = "ThreeLevelStation"
	add_child(station_root)
	
	# Build each deck
	create_deck_1_operations()
	create_deck_2_living()
	create_deck_3_engineering()
	
	# Add central stairwell connecting all decks
	create_central_stairwell()
	
	# Add global lighting
	create_station_lighting()
	
	# Add player spawn point
	create_player_spawn()
	
	# Set owner for saving
	if Engine.is_editor_hint():
		set_owner_recursive(station_root, get_tree().edited_scene_root)
	
	print("3-level station complete!")

func create_deck_1_operations():
	var deck1 = Node3D.new()
	deck1.name = "Deck1_Operations"
	deck1.position.y = deck_levels["Deck1_Operations"]
	station_root.add_child(deck1)
	
	# Create main floor with stairwell hole
	var floor = create_deck_floor(deck1, true)
	
	# Create outer walls
	create_deck_walls(deck1)
	
	# Create corridors
	create_deck_corridors(deck1)
	
	# Create rooms for Deck 1
	var rooms = [
		{"name": "DockingBay", "pos": Vector3(-15, 0, 15), "color": Color(0.5, 0.5, 0.6)},
		{"name": "BayControl", "pos": Vector3(15, 0, 15), "color": Color(0.6, 0.5, 0.5)},
		{"name": "MedicalBay", "pos": Vector3(-15, 0, 0), "color": Color(0.8, 0.8, 0.9)},
		{"name": "Laboratory", "pos": Vector3(15, 0, 0), "color": Color(0.7, 0.9, 0.7)},
		{"name": "SecurityOffice", "pos": Vector3(-15, 0, -15), "color": Color(0.6, 0.6, 0.8)},
		{"name": "CommandCenter", "pos": Vector3(15, 0, -15), "color": Color(0.8, 0.7, 0.6)}
	]
	
	for room_data in rooms:
		create_room_fixed(deck1, room_data.name, room_data.pos, room_data.color)
	
	# Create ceiling
	create_deck_ceiling(deck1)

func create_deck_2_living():
	var deck2 = Node3D.new()
	deck2.name = "Deck2_Living"
	deck2.position.y = deck_levels["Deck2_Living"]
	station_root.add_child(deck2)
	
	# Create main floor with stairwell hole
	var floor = create_deck_floor(deck2, true)
	
	# Create outer walls
	create_deck_walls(deck2)
	
	# Create corridors
	create_deck_corridors(deck2)
	
	# Create rooms for Deck 2
	var rooms = [
		{"name": "CrewQuartersA", "pos": Vector3(-15, 0, 15), "color": Color(0.8, 0.6, 0.8)},  # PURPLE
		{"name": "CrewQuartersB", "pos": Vector3(15, 0, 15), "color": Color(1.0, 0.7, 0.8)},   # PINK
		{"name": "Cafeteria", "pos": Vector3(-15, 0, 0), "color": Color(1.0, 0.6, 0.3)},      # ORANGE
		{"name": "Recreation", "pos": Vector3(15, 0, 0), "color": Color(0.3, 0.9, 0.9)},       # CYAN
		{"name": "StorageA", "pos": Vector3(-15, 0, -15), "color": Color(0.6, 0.4, 0.3)},     # BROWN
		{"name": "StorageB", "pos": Vector3(15, 0, -15), "color": Color(0.8, 0.7, 0.5)}       # TAN
	]
	
	for room_data in rooms:
		create_room_fixed(deck2, room_data.name, room_data.pos, room_data.color)
	
	# Create ceiling
	create_deck_ceiling(deck2)

func create_deck_3_engineering():
	var deck3 = Node3D.new()
	deck3.name = "Deck3_Engineering"
	deck3.position.y = deck_levels["Deck3_Engineering"]
	station_root.add_child(deck3)
	
	# Create main floor with stairwell hole
	var floor = create_deck_floor(deck3, true)
	
	# Create outer walls
	create_deck_walls(deck3)
	
	# Create corridors
	create_deck_corridors(deck3)
	
	# Create rooms for Deck 3
	var rooms = [
		{"name": "MainEngineering", "pos": Vector3(-15, 0, 15), "color": Color(1.0, 1.0, 0.3)}, # BRIGHT YELLOW
		{"name": "PowerCore", "pos": Vector3(15, 0, 15), "color": Color(1.0, 0.3, 0.3)},       # BRIGHT RED
		{"name": "LifeSupport", "pos": Vector3(-15, 0, 0), "color": Color(0.3, 1.0, 0.3)},    # BRIGHT GREEN
		{"name": "Manufacturing", "pos": Vector3(15, 0, 0), "color": Color(0.3, 0.3, 1.0)},    # BRIGHT BLUE
		{"name": "CargoHold", "pos": Vector3(-15, 0, -15), "color": Color(0.5, 0.5, 0.5)},    # GRAY
		{"name": "WasteProcessing", "pos": Vector3(15, 0, -15), "color": Color(0.2, 0.4, 0.2)} # DARK GREEN
	]
	
	for room_data in rooms:
		create_room_fixed(deck3, room_data.name, room_data.pos, room_data.color)
	
	# Create ceiling
	create_deck_ceiling(deck3)

func create_deck_floor(deck: Node3D, with_stairwell_hole: bool) -> CSGCombiner3D:
	var floor_combiner = CSGCombiner3D.new()
	floor_combiner.name = "Floor"
	floor_combiner.use_collision = true
	deck.add_child(floor_combiner)
	
	# Main floor
	var floor = CSGBox3D.new()
	floor.size = Vector3(station_width, 0.5, station_depth)
	floor.position = Vector3(0, -0.25, 0)
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.3, 0.35)
	floor_mat.metallic = 0.8
	floor_mat.roughness = 0.4
	floor.material = floor_mat
	floor_combiner.add_child(floor)
	
	# Cut stairwell hole if needed - FIXED: Make hole bigger than floor thickness
	if with_stairwell_hole:
		var stair_hole = CSGBox3D.new()
		stair_hole.size = Vector3(6, 1.0, 6)  # 6x6 meter opening, 1m thick (double floor thickness)
		stair_hole.position = Vector3(0, -0.25, 0)  # Align with floor position
		stair_hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		floor_combiner.add_child(stair_hole)
	
	return floor_combiner

func create_deck_walls(deck: Node3D):
	var walls_group = Node3D.new()
	walls_group.name = "OuterWalls"
	deck.add_child(walls_group)
	
	var wall_height = deck_height
	var wall_thickness = 0.5
	
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.6, 0.65, 0.7)
	wall_mat.metallic = 0.9
	wall_mat.roughness = 0.3
	
	# Create all four walls
	var walls = [
		{"name": "NorthWall", "size": Vector3(station_width, wall_height, wall_thickness), "pos": Vector3(0, wall_height/2, -station_depth/2)},
		{"name": "SouthWall", "size": Vector3(station_width, wall_height, wall_thickness), "pos": Vector3(0, wall_height/2, station_depth/2)},
		{"name": "EastWall", "size": Vector3(wall_thickness, wall_height, station_depth), "pos": Vector3(station_width/2, wall_height/2, 0)},
		{"name": "WestWall", "size": Vector3(wall_thickness, wall_height, station_depth), "pos": Vector3(-station_width/2, wall_height/2, 0)}
	]
	
	for wall_data in walls:
		var wall = CSGBox3D.new()
		wall.name = wall_data.name
		wall.size = wall_data.size
		wall.position = wall_data.pos
		wall.use_collision = true
		wall.material = wall_mat
		walls_group.add_child(wall)

func create_room_simple(parent: Node3D, room_name: String, pos: Vector3, size: Vector3, wall_mat: Material):
	var room = Node3D.new()
	room.name = room_name
	room.position = pos
	parent.add_child(room)
	
	var wall_thickness = 0.3
	
	# Use CSGCombiner for proper room construction
	var room_combiner = CSGCombiner3D.new()
	room_combiner.use_collision = true
	room.add_child(room_combiner)
	
	# Create outer box
	var outer_box = CSGBox3D.new()
	outer_box.size = size + Vector3(wall_thickness * 2, 0, wall_thickness * 2)
	outer_box.position = Vector3(0, size.y/2, 0)
	outer_box.material = wall_mat
	room_combiner.add_child(outer_box)
	
	# Hollow out the inside
	var inner_box = CSGBox3D.new()
	inner_box.size = size - Vector3(0, wall_thickness, 0)
	inner_box.position = Vector3(0, size.y/2, 0)
	inner_box.operation = CSGShape3D.OPERATION_SUBTRACTION
	room_combiner.add_child(inner_box)
	
	# Cut door openings based on room position
	var door_size = Vector3(3, 3, wall_thickness * 2)
	
	# Determine which walls need doors based on room position
	if pos.x < 0 and abs(pos.x) > 10:  # West rooms need east doors
		var door_cut = CSGBox3D.new()
		door_cut.size = door_size
		door_cut.position = Vector3(size.x/2, 1.5, 0)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	if pos.x > 0 and abs(pos.x) > 10:  # East rooms need west doors
		var door_cut = CSGBox3D.new()
		door_cut.size = door_size
		door_cut.position = Vector3(-size.x/2, 1.5, 0)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	if pos.z < 0 and abs(pos.z) > 10:  # North rooms need south doors
		var door_cut = CSGBox3D.new()
		door_cut.size = door_size.rotated(Vector3.UP, PI/2)
		door_cut.position = Vector3(0, 1.5, size.z/2)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	if pos.z > 0 and abs(pos.z) > 10:  # South rooms need north doors
		var door_cut = CSGBox3D.new()
		door_cut.size = door_size.rotated(Vector3.UP, PI/2)
		door_cut.position = Vector3(0, 1.5, -size.z/2)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	# Center rooms need multiple doors
	if abs(pos.x) < 10 and abs(pos.z) < 10:
		# Add doors on all sides for center rooms
		for dir in [Vector3(size.x/2, 1.5, 0), Vector3(-size.x/2, 1.5, 0),
					Vector3(0, 1.5, size.z/2), Vector3(0, 1.5, -size.z/2)]:
			var door_cut = CSGBox3D.new()
			door_cut.size = door_size if abs(dir.x) > 0 else door_size.rotated(Vector3.UP, PI/2)
			door_cut.position = dir
			door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
			room_combiner.add_child(door_cut)
	
	# Add room label
	var label = Label3D.new()
	label.text = room_name
	label.position = Vector3(0, size.y - 0.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	room.add_child(label)

func create_level_corridors(level: Node3D):
	var corridors_group = Node3D.new()
	corridors_group.name = "Corridors"
	level.add_child(corridors_group)
	
	# Corridor material
	var corridor_mat = StandardMaterial3D.new()
	corridor_mat.albedo_color = Color(0.25, 0.25, 0.3)
	corridor_mat.metallic = 0.6
	corridor_mat.roughness = 0.5
	
	# Main cross corridors
	var h_corridor = CSGBox3D.new()
	h_corridor.name = "HorizontalCorridor"
	h_corridor.size = Vector3(station_width - 10, 0.1, 4)
	h_corridor.position = Vector3(0, 0.01, 0)
	h_corridor.material = corridor_mat
	corridors_group.add_child(h_corridor)
	
	var v_corridor = CSGBox3D.new()
	v_corridor.name = "VerticalCorridor"
	v_corridor.size = Vector3(4, 0.1, station_depth - 10)
	v_corridor.position = Vector3(0, 0.01, 0)
	v_corridor.material = corridor_mat
	corridors_group.add_child(v_corridor)

func create_deck_corridors(deck: Node3D):
	var corridors = Node3D.new()
	corridors.name = "Corridors"
	deck.add_child(corridors)
	
	var corridor_mat = StandardMaterial3D.new()
	corridor_mat.albedo_color = Color(0.25, 0.25, 0.3)
	corridor_mat.metallic = 0.6
	corridor_mat.roughness = 0.5
	
	# Cross corridors with access to stairwell
	var h_corridor = CSGBox3D.new()
	h_corridor.name = "HorizontalCorridor"
	h_corridor.size = Vector3(station_width - 20, 0.1, 4)
	h_corridor.position = Vector3(0, 0.01, 0)
	h_corridor.material = corridor_mat
	corridors.add_child(h_corridor)
	
	var v_corridor = CSGBox3D.new()
	v_corridor.name = "VerticalCorridor"
	v_corridor.size = Vector3(4, 0.1, station_depth - 20)
	v_corridor.position = Vector3(0, 0.01, 0)
	v_corridor.material = corridor_mat
	corridors.add_child(v_corridor)

func create_room_fixed(deck: Node3D, room_name: String, pos: Vector3, wall_color: Color):
	var room = Node3D.new()
	room.name = room_name
	room.position = pos
	deck.add_child(room)
	
	var room_size = Vector3(12, deck_height - 0.5, 12)  # Standard room size
	var wall_thickness = 0.3
	
	# Create wall material with custom color
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = wall_color
	wall_mat.metallic = 0.7
	wall_mat.roughness = 0.4
	
	# Create room using CSGCombiner (clean interior)
	var room_combiner = CSGCombiner3D.new()
	room_combiner.use_collision = true
	room.add_child(room_combiner)
	
	# Outer shell
	var outer_box = CSGBox3D.new()
	outer_box.size = room_size
	outer_box.position = Vector3(0, room_size.y/2, 0)
	outer_box.material = wall_mat
	room_combiner.add_child(outer_box)
	
	# Hollow interior (clean room)
	var inner_box = CSGBox3D.new()
	inner_box.size = room_size - Vector3(wall_thickness * 2, wall_thickness, wall_thickness * 2)
	inner_box.position = Vector3(0, room_size.y/2, 0)
	inner_box.operation = CSGShape3D.OPERATION_SUBTRACTION
	room_combiner.add_child(inner_box)
	
	# FIXED: Door cuts must go THROUGH wall thickness
	# Door dimensions: 2m wide, 2.5m tall
	var door_width = 2.0
	var door_height = 2.5
	
	# East rooms: door faces west (toward corridor)
	if pos.x > 0:
		var door_cut = CSGBox3D.new()
		# Door cut must be THICKER than wall in X direction
		door_cut.size = Vector3(wall_thickness + 0.2, door_height, door_width)
		door_cut.position = Vector3(-room_size.x/2, door_height/2 + 0.1, 0)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	# West rooms: door faces east (toward corridor)
	if pos.x < 0:
		var door_cut = CSGBox3D.new()
		# Door cut must be THICKER than wall in X direction
		door_cut.size = Vector3(wall_thickness + 0.2, door_height, door_width)
		door_cut.position = Vector3(room_size.x/2, door_height/2 + 0.1, 0)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	# North rooms: additional door if on corridor
	if pos.z < 0 and abs(pos.x) < 20:
		var door_cut = CSGBox3D.new()
		# Door cut must be THICKER than wall in Z direction
		door_cut.size = Vector3(door_width, door_height, wall_thickness + 0.2)
		door_cut.position = Vector3(0, door_height/2 + 0.1, room_size.z/2)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	# South rooms: additional door if on corridor
	if pos.z > 0 and abs(pos.x) < 20:
		var door_cut = CSGBox3D.new()
		# Door cut must be THICKER than wall in Z direction
		door_cut.size = Vector3(door_width, door_height, wall_thickness + 0.2)
		door_cut.position = Vector3(0, door_height/2 + 0.1, -room_size.z/2)
		door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		room_combiner.add_child(door_cut)
	
	# Add room label
	var label = Label3D.new()
	label.text = room_name
	label.position = Vector3(0, room_size.y - 0.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	room.add_child(label)

func create_deck_ceiling(deck: Node3D):
	# FIXED: Create ceiling with stairwell hole
	var ceiling_combiner = CSGCombiner3D.new()
	ceiling_combiner.name = "Ceiling"
	ceiling_combiner.use_collision = true
	deck.add_child(ceiling_combiner)
	
	# Main ceiling
	var ceiling = CSGBox3D.new()
	ceiling.size = Vector3(station_width, 0.3, station_depth)
	ceiling.position = Vector3(0, deck_height, 0)
	
	var ceiling_mat = StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.9, 0.9, 0.95)
	ceiling_mat.metallic = 0.3
	ceiling_mat.emission_enabled = true
	ceiling_mat.emission = Color(0.9, 0.9, 1.0)
	ceiling_mat.emission_energy_multiplier = 0.2
	ceiling.material = ceiling_mat
	ceiling_combiner.add_child(ceiling)
	
	# Cut stairwell hole in ceiling (except for top deck)
	if deck.name != "Deck3_Engineering":
		var stair_hole = CSGBox3D.new()
		stair_hole.size = Vector3(6, 0.5, 6)  # Bigger than ceiling thickness
		stair_hole.position = Vector3(0, deck_height, 0)
		stair_hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		ceiling_combiner.add_child(stair_hole)

func create_central_stairwell():
	var stairwell = Node3D.new()
	stairwell.name = "CentralStairwell"
	station_root.add_child(stairwell)
	
	# Stairwell enclosure
	var stair_mat = StandardMaterial3D.new()
	stair_mat.albedo_color = Color(0.5, 0.5, 0.55)
	stair_mat.metallic = 0.8
	stair_mat.roughness = 0.3
	
	# Create stairwell shaft
	var shaft_combiner = CSGCombiner3D.new()
	shaft_combiner.name = "StairwellShaft"
	shaft_combiner.use_collision = true
	stairwell.add_child(shaft_combiner)
	
	# Outer walls of stairwell
	var shaft_outer = CSGBox3D.new()
	shaft_outer.size = Vector3(8, 12, 8)  # Full height of all 3 decks
	shaft_outer.position = Vector3(0, 6, 0)  # Center at middle of station height
	shaft_outer.material = stair_mat
	shaft_combiner.add_child(shaft_outer)
	
	# Hollow interior
	var shaft_inner = CSGBox3D.new()
	shaft_inner.size = Vector3(7, 11.5, 7)
	shaft_inner.position = Vector3(0, 6, 0)
	shaft_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	shaft_combiner.add_child(shaft_inner)
	
	# Cut doorways at each level
	for deck_name in deck_levels:
		var door_height = deck_levels[deck_name] + 1.5
		
		# North doorway
		var north_door = CSGBox3D.new()
		north_door.size = Vector3(3, 3, 2)
		north_door.position = Vector3(0, door_height, -4)
		north_door.operation = CSGShape3D.OPERATION_SUBTRACTION
		shaft_combiner.add_child(north_door)
		
		# South doorway
		var south_door = CSGBox3D.new()
		south_door.size = Vector3(3, 3, 2)
		south_door.position = Vector3(0, door_height, 4)
		south_door.operation = CSGShape3D.OPERATION_SUBTRACTION
		shaft_combiner.add_child(south_door)
	
	# Create actual stairs
	create_stair_segments(stairwell)
	
	# Add railings for safety
	create_stairwell_railings(stairwell)

func create_stair_segments(stairwell: Node3D):
	var stair_mat = StandardMaterial3D.new()
	stair_mat.albedo_color = Color(0.4, 0.4, 0.45)
	stair_mat.metallic = 0.6
	stair_mat.roughness = 0.5
	
	# FIXED: Create proper walkable stairs
	var step_height = 0.2  # 20cm per step
	var step_depth = 0.3   # 30cm deep steps
	var stair_width = 3.0  # 3m wide stairs
	var num_steps = 20     # 20 steps for 4m height
	
	# Stairs from Deck 1 to Deck 2 (going north)
	var stairs1 = Node3D.new()
	stairs1.name = "Stairs_Deck1_to_Deck2"
	stairwell.add_child(stairs1)
	
	for i in range(num_steps):
		var step = CSGBox3D.new()
		step.size = Vector3(stair_width, step_height, step_depth)
		step.position = Vector3(
			0,
			i * step_height + step_height/2,
			-2.5 + (i * step_depth)
		)
		step.use_collision = true
		step.material = stair_mat
		stairs1.add_child(step)
	
	# Platform at Deck 2
	var platform2 = CSGBox3D.new()
	platform2.name = "Platform_Deck2"
	platform2.size = Vector3(5, 0.3, 5)
	platform2.position = Vector3(0, deck_levels["Deck2_Living"] - 0.15, 0)
	platform2.use_collision = true
	platform2.material = stair_mat
	stairwell.add_child(platform2)
	
	# Stairs from Deck 2 to Deck 3 (going south)
	var stairs2 = Node3D.new()
	stairs2.name = "Stairs_Deck2_to_Deck3"
	stairwell.add_child(stairs2)
	
	for i in range(num_steps):
		var step = CSGBox3D.new()
		step.size = Vector3(stair_width, step_height, step_depth)
		step.position = Vector3(
			0,
			deck_levels["Deck2_Living"] + (i * step_height) + step_height/2,
			2.5 - (i * step_depth)
		)
		step.use_collision = true
		step.material = stair_mat
		stairs2.add_child(step)

func create_stairwell_railings(stairwell: Node3D):
	var rail_mat = StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.7, 0.7, 0.75)
	rail_mat.metallic = 0.9
	rail_mat.roughness = 0.2
	
	# Add safety railings along stairs
	var rail1 = CSGBox3D.new()
	rail1.size = Vector3(0.1, 1, 6)
	rail1.position = Vector3(-3, 2, 0)
	rail1.material = rail_mat
	stairwell.add_child(rail1)
	
	var rail2 = CSGBox3D.new()
	rail2.size = Vector3(0.1, 1, 6)
	rail2.position = Vector3(3, 6, 0)
	rail2.material = rail_mat
	stairwell.add_child(rail2)

func create_station_lighting():
	var lights = Node3D.new()
	lights.name = "StationLighting"
	station_root.add_child(lights)
	
	# Add lights for each deck
	for deck_name in deck_levels:
		var deck_y = deck_levels[deck_name]
		
		# Grid of lights for this deck
		for x in range(-2, 3):
			for z in range(-2, 3):
				var light = OmniLight3D.new()
				light.position = Vector3(x * 12, deck_y + 3.5, z * 12)
				light.light_energy = 1.5
				light.omni_range = 10.0
				light.shadow_enabled = true
				lights.add_child(light)

func create_player_spawn():
	var spawn = Node3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(-15, 1, 15)  # Inside Docking Bay on Deck 1
	station_root.add_child(spawn)
	
	# Add visual marker in editor
	if Engine.is_editor_hint():
		var marker = Label3D.new()
		marker.text = "PLAYER SPAWN"
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 24
		marker.outline_size = 8
		spawn.add_child(marker)


func set_owner_recursive(node: Node, owner: Node):
	if not owner:
		return
	
	node.owner = owner
	for child in node.get_children():
		set_owner_recursive(child, owner)