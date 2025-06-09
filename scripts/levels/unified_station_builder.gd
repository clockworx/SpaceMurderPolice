@tool
extends Node3D
class_name UnifiedStationBuilder

# Unified Space Station Builder - Single Scene with All Areas Connected
# No loading screens, seamless navigation between all areas

@export_group("Station Settings")
@export var build_on_ready: bool = true
@export var build_in_editor: bool = true
@export var enable_debug_visuals: bool = false

@export_group("Editor Tools")
@export var rebuild_station: bool = false : set = set_rebuild_station
@export var clear_station: bool = false : set = set_clear_station

# Station dimensions
const LEVEL_HEIGHT = 4.0
const CORRIDOR_WIDTH = 4.0
const CORRIDOR_HEIGHT = 3.5
const ROOM_MIN_SIZE = 6.0
const WALL_THICKNESS = 0.3

# Level Y positions
var level_positions = {
	"upper": 8.0,
	"main": 0.0,
	"lower": -8.0
}

# Materials
var materials: Dictionary = {}

# Main scene root
var station_root: Node3D

func _ready():
	if Engine.is_editor_hint():
		if build_in_editor:
			create_materials()
			build_unified_station()
	else:
		if build_on_ready:
			create_materials()
			build_unified_station()

func set_rebuild_station(value: bool):
	if value and Engine.is_editor_hint():
		print("Rebuilding station in editor...")
		# Clear existing station
		clear_existing_station()
		# Rebuild
		create_materials()
		build_unified_station()
		rebuild_station = false

func set_clear_station(value: bool):
	if value and Engine.is_editor_hint():
		print("Clearing station...")
		clear_existing_station()
		clear_station = false

func clear_existing_station():
	if station_root and is_instance_valid(station_root):
		station_root.queue_free()
		station_root = null

func set_owner_recursive(node: Node, owner: Node):
	if not Engine.is_editor_hint() or not owner:
		return
	
	node.owner = owner
	for child in node.get_children():
		set_owner_recursive(child, owner)

func create_materials():
	# Floor - metallic gray
	materials["floor"] = StandardMaterial3D.new()
	materials["floor"].albedo_color = Color(0.35, 0.35, 0.4)
	materials["floor"].metallic = 0.8
	materials["floor"].roughness = 0.4
	
	# Wall - light metallic
	materials["wall"] = StandardMaterial3D.new()
	materials["wall"].albedo_color = Color(0.65, 0.7, 0.75)
	materials["wall"].metallic = 0.9
	materials["wall"].roughness = 0.3
	
	# Ceiling with lighting
	materials["ceiling"] = StandardMaterial3D.new()
	materials["ceiling"].albedo_color = Color(0.9, 0.9, 0.95)
	materials["ceiling"].metallic = 0.3
	materials["ceiling"].roughness = 0.2
	materials["ceiling"].emission_enabled = true
	materials["ceiling"].emission = Color(0.95, 0.95, 1.0)
	materials["ceiling"].emission_energy_multiplier = 0.3
	
	# Emergency lighting
	materials["emergency"] = StandardMaterial3D.new()
	materials["emergency"].albedo_color = Color(0.8, 0.2, 0.2)
	materials["emergency"].emission_enabled = true
	materials["emergency"].emission = Color(1, 0, 0)
	materials["emergency"].emission_energy_multiplier = 0.5
	
	# Maintenance areas
	materials["maintenance"] = StandardMaterial3D.new()
	materials["maintenance"].albedo_color = Color(0.2, 0.2, 0.25)
	materials["maintenance"].metallic = 0.6
	materials["maintenance"].roughness = 0.6
	
	# Glass
	materials["glass"] = StandardMaterial3D.new()
	materials["glass"].albedo_color = Color(0.8, 0.85, 0.9, 0.3)
	materials["glass"].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials["glass"].metallic = 0.0
	materials["glass"].roughness = 0.1

func build_unified_station():
	print("Building unified space station...")
	
	# Clear any existing station first
	if Engine.is_editor_hint():
		clear_existing_station()
	
	# Create main station root
	station_root = Node3D.new()
	station_root.name = "UnifiedStation"
	add_child(station_root)
	
	# Set owner for editor visibility
	if Engine.is_editor_hint() and get_tree():
		var scene_root = get_tree().edited_scene_root
		if scene_root:
			station_root.owner = scene_root
	
	# Build core structure first
	_build_central_core()
	
	# Build each level
	_build_upper_level()
	_build_main_level()
	_build_lower_level()
	
	# Add vertical connections
	_build_vertical_connections()
	
	# Add maintenance network
	_build_maintenance_network()
	
	# Add station-wide systems
	_add_lighting_system()
	_add_navigation_aids()
	
	# Set owners for all nodes in editor
	if Engine.is_editor_hint() and get_tree():
		var scene_root = get_tree().edited_scene_root
		if scene_root and station_root:
			set_owner_recursive(station_root, scene_root)
	
	print("Unified station construction complete!")

func _build_central_core():
	# Central core that spans all levels
	var core = Node3D.new()
	core.name = "CentralCore"
	station_root.add_child(core)
	
	# Main vertical shaft
	var shaft = create_room(
		"CentralShaft",
		Vector3(0, 0, 0),
		Vector3(8, 20, 8),
		{},  # No doors in shaft walls
		"core"
	)
	core.add_child(shaft)
	
	# Add core features
	_add_core_features(core)

func _build_upper_level():
	var upper = Node3D.new()
	upper.name = "UpperLevel"
	upper.position.y = level_positions["upper"]
	station_root.add_child(upper)
	
	# Command Center (10x8m)
	var command = create_room(
		"CommandCenter",
		Vector3(0, 0, 0),
		Vector3(10, CORRIDOR_HEIGHT, 8),
		{"south": true, "east": true, "west": true},
		"operations"
	)
	upper.add_child(command)
	
	# Communications (8x6m)
	var comms = create_room(
		"Communications",
		Vector3(12, 0, 0),
		Vector3(8, CORRIDOR_HEIGHT, 6),
		{"west": true, "south": true},
		"operations"
	)
	upper.add_child(comms)
	
	# Navigation (8x6m)
	var nav = create_room(
		"Navigation",
		Vector3(-12, 0, 0),
		Vector3(8, CORRIDOR_HEIGHT, 6),
		{"east": true, "south": true},
		"operations"
	)
	upper.add_child(nav)
	
	# Observation Deck (12x10m)
	var observation = create_room(
		"ObservationDeck",
		Vector3(0, 0, -12),
		Vector3(12, CORRIDOR_HEIGHT, 10),
		{"north": true, "east": true, "west": true},
		"operations"
	)
	upper.add_child(observation)
	
	# Security Office (8x8m)
	var security = create_room(
		"SecurityOffice",
		Vector3(15, 0, -8),
		Vector3(8, CORRIDOR_HEIGHT, 8),
		{"west": true, "north": true},
		"operations"
	)
	upper.add_child(security)
	
	# Armory (6x6m)
	var armory = create_room(
		"Armory",
		Vector3(15, 0, -16),
		Vector3(6, CORRIDOR_HEIGHT, 6),
		{"north": true},
		"operations"
	)
	upper.add_child(armory)
	
	# Upper corridors
	_add_upper_corridors(upper)

func _build_main_level():
	var main = Node3D.new()
	main.name = "MainLevel"
	main.position.y = level_positions["main"]
	station_root.add_child(main)
	
	# Central Hub (12x12m)
	var hub = create_room(
		"CentralHub",
		Vector3(0, 0, 0),
		Vector3(12, CORRIDOR_HEIGHT, 12),
		{"north": true, "south": true, "east": true, "west": true},
		"public"
	)
	main.add_child(hub)
	
	# Medical Bay (10x8m)
	var medical = create_room(
		"MedicalBay",
		Vector3(16, 0, 0),
		Vector3(10, CORRIDOR_HEIGHT, 8),
		{"west": true, "south": true},
		"medical"
	)
	main.add_child(medical)
	
	# Surgery (6x6m)
	var surgery = create_room(
		"Surgery",
		Vector3(16, 0, -10),
		Vector3(6, CORRIDOR_HEIGHT, 6),
		{"north": true, "east": true},
		"medical"
	)
	main.add_child(surgery)
	
	# Laboratory Complex
	var lab1 = create_room(
		"Laboratory1",
		Vector3(-16, 0, 0),
		Vector3(8, CORRIDOR_HEIGHT, 8),
		{"east": true, "south": true},
		"research"
	)
	main.add_child(lab1)
	
	var lab2 = create_room(
		"Laboratory2",
		Vector3(-16, 0, -10),
		Vector3(8, CORRIDOR_HEIGHT, 8),
		{"north": true, "east": true},
		"research"
	)
	main.add_child(lab2)
	
	var lab3 = create_room(
		"Laboratory3",
		Vector3(-26, 0, -5),
		Vector3(8, CORRIDOR_HEIGHT, 8),
		{"east": true},
		"research"
	)
	main.add_child(lab3)
	
	# Living quarters
	var quarters1 = create_room(
		"CrewQuarters1",
		Vector3(0, 0, 16),
		Vector3(8, CORRIDOR_HEIGHT, 6),
		{"south": true, "east": true},
		"residential"
	)
	main.add_child(quarters1)
	
	var quarters2 = create_room(
		"CrewQuarters2",
		Vector3(10, 0, 16),
		Vector3(8, CORRIDOR_HEIGHT, 6),
		{"west": true, "south": true},
		"residential"
	)
	main.add_child(quarters2)
	
	# Common areas
	var cafeteria = create_room(
		"Cafeteria",
		Vector3(0, 0, -16),
		Vector3(12, CORRIDOR_HEIGHT, 10),
		{"north": true, "west": true},
		"public"
	)
	main.add_child(cafeteria)
	
	var recreation = create_room(
		"RecreationRoom",
		Vector3(-14, 0, -16),
		Vector3(10, CORRIDOR_HEIGHT, 8),
		{"east": true, "north": true},
		"public"
	)
	main.add_child(recreation)
	
	# Main corridors
	_add_main_corridors(main)

func _build_lower_level():
	var lower = Node3D.new()
	lower.name = "LowerLevel"
	lower.position.y = level_positions["lower"]
	station_root.add_child(lower)
	
	# Engineering (15x12m)
	var engineering = create_room(
		"MainEngineering",
		Vector3(0, 0, 0),
		Vector3(15, CORRIDOR_HEIGHT + 0.5, 12),
		{"north": true, "south": true, "east": true, "west": true},
		"engineering"
	)
	lower.add_child(engineering)
	
	# Power Generation (10x8m)
	var power = create_room(
		"PowerGeneration",
		Vector3(0, 0, -16),
		Vector3(10, CORRIDOR_HEIGHT, 8),
		{"north": true, "east": true},
		"engineering"
	)
	lower.add_child(power)
	
	# Life Support (8x8m)
	var life_support = create_room(
		"LifeSupport",
		Vector3(-12, 0, -16),
		Vector3(8, CORRIDOR_HEIGHT, 8),
		{"west": true, "north": true},
		"engineering"
	)
	lower.add_child(life_support)
	
	# Storage areas
	var storage1 = create_room(
		"Storage1",
		Vector3(18, 0, 0),
		Vector3(8, CORRIDOR_HEIGHT, 10),
		{"west": true},
		"storage"
	)
	lower.add_child(storage1)
	
	var storage2 = create_room(
		"Storage2",
		Vector3(-18, 0, 0),
		Vector3(8, CORRIDOR_HEIGHT, 10),
		{"east": true},
		"storage"
	)
	lower.add_child(storage2)
	
	# Maintenance workshop
	var workshop = create_room(
		"Workshop",
		Vector3(12, 0, 10),
		Vector3(10, CORRIDOR_HEIGHT, 8),
		{"west": true, "south": true},
		"engineering"
	)
	lower.add_child(workshop)
	
	# Waste processing
	var waste = create_room(
		"WasteProcessing",
		Vector3(-12, 0, 10),
		Vector3(8, CORRIDOR_HEIGHT, 6),
		{"east": true, "south": true},
		"engineering"
	)
	lower.add_child(waste)
	
	# Lower corridors
	_add_lower_corridors(lower)

func _add_upper_corridors(upper: Node3D):
	# Main east-west corridor
	var main_corridor = create_corridor(
		"UpperMainCorridor",
		Vector3(0, 0, 4),
		Vector3(30, CORRIDOR_HEIGHT, CORRIDOR_WIDTH),
		true
	)
	upper.add_child(main_corridor)
	
	# North-south corridors
	var ns_corridor1 = create_corridor(
		"UpperNSCorridor1",
		Vector3(12, 0, -4),
		Vector3(CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 12),
		false
	)
	upper.add_child(ns_corridor1)
	
	var ns_corridor2 = create_corridor(
		"UpperNSCorridor2",
		Vector3(-12, 0, -4),
		Vector3(CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 12),
		false
	)
	upper.add_child(ns_corridor2)

func _add_main_corridors(main: Node3D):
	# Central ring corridor
	var ring_n = create_corridor(
		"RingNorth",
		Vector3(0, 0, 8),
		Vector3(20, CORRIDOR_HEIGHT, CORRIDOR_WIDTH),
		true
	)
	main.add_child(ring_n)
	
	var ring_s = create_corridor(
		"RingSouth",
		Vector3(0, 0, -8),
		Vector3(20, CORRIDOR_HEIGHT, CORRIDOR_WIDTH),
		true
	)
	main.add_child(ring_s)
	
	var ring_e = create_corridor(
		"RingEast",
		Vector3(10, 0, 0),
		Vector3(CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 20),
		false
	)
	main.add_child(ring_e)
	
	var ring_w = create_corridor(
		"RingWest",
		Vector3(-10, 0, 0),
		Vector3(CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 20),
		false
	)
	main.add_child(ring_w)
	
	# Extended corridors
	var lab_corridor = create_corridor(
		"LabCorridor",
		Vector3(-20, 0, -5),
		Vector3(8, CORRIDOR_HEIGHT, CORRIDOR_WIDTH),
		true
	)
	main.add_child(lab_corridor)
	
	var medical_corridor = create_corridor(
		"MedicalCorridor",
		Vector3(16, 0, -5),
		Vector3(CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 10),
		false
	)
	main.add_child(medical_corridor)

func _add_lower_corridors(lower: Node3D):
	# Main engineering corridor
	var eng_corridor = create_corridor(
		"EngineeringCorridor",
		Vector3(0, 0, -8),
		Vector3(24, CORRIDOR_HEIGHT, CORRIDOR_WIDTH),
		true
	)
	lower.add_child(eng_corridor)
	
	# Side corridors
	var side_e = create_corridor(
		"LowerEastCorridor",
		Vector3(12, 0, 5),
		Vector3(12, CORRIDOR_HEIGHT, CORRIDOR_WIDTH),
		true
	)
	lower.add_child(side_e)
	
	var side_w = create_corridor(
		"LowerWestCorridor",
		Vector3(-12, 0, 5),
		Vector3(12, CORRIDOR_HEIGHT, CORRIDOR_WIDTH),
		true
	)
	lower.add_child(side_w)

func _build_vertical_connections():
	var verticals = Node3D.new()
	verticals.name = "VerticalConnections"
	station_root.add_child(verticals)
	
	# Central elevator
	create_elevator_shaft(verticals, "CentralElevator", Vector3(0, 0, 0))
	
	# Emergency stairs
	create_stairwell(verticals, "Stairwell1", Vector3(20, 0, 0))
	create_stairwell(verticals, "Stairwell2", Vector3(-20, 0, 0))
	create_stairwell(verticals, "Stairwell3", Vector3(0, 0, 20))
	create_stairwell(verticals, "Stairwell4", Vector3(0, 0, -20))

func _build_maintenance_network():
	var maintenance = Node3D.new()
	maintenance.name = "MaintenanceNetwork"
	station_root.add_child(maintenance)
	
	# Maintenance tunnels run between main levels
	for level_name in ["upper", "main", "lower"]:
		var level_maint = Node3D.new()
		level_maint.name = "Maintenance_" + level_name
		level_maint.position.y = level_positions[level_name] - 2.0
		maintenance.add_child(level_maint)
		
		# Main maintenance spine
		var spine = create_maintenance_tunnel(
			"MaintSpine",
			Vector3(0, 0, 0),
			Vector3(2, 2, 40)
		)
		level_maint.add_child(spine)
		
		# Cross tunnels
		var cross1 = create_maintenance_tunnel(
			"MaintCross1",
			Vector3(0, 0, 10),
			Vector3(30, 2, 2)
		)
		level_maint.add_child(cross1)
		
		var cross2 = create_maintenance_tunnel(
			"MaintCross2",
			Vector3(0, 0, -10),
			Vector3(30, 2, 2)
		)
		level_maint.add_child(cross2)

func create_room(room_name: String, pos: Vector3, size: Vector3, doors: Dictionary, room_type: String) -> Node3D:
	var room = Node3D.new()
	room.name = room_name
	room.position = pos
	
	var combiner = CSGCombiner3D.new()
	combiner.use_collision = true
	room.add_child(combiner)
	
	# Create room using CSG
	var outer = CSGBox3D.new()
	outer.size = size + Vector3(WALL_THICKNESS * 2, WALL_THICKNESS * 2, WALL_THICKNESS * 2)
	outer.material = materials["wall"]
	combiner.add_child(outer)
	
	var inner = CSGBox3D.new()
	inner.size = size
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	combiner.add_child(inner)
	
	# Floor
	var floor = CSGBox3D.new()
	floor.size = Vector3(size.x, WALL_THICKNESS, size.z)
	floor.position = Vector3(0, -size.y/2, 0)
	floor.material = materials["floor"]
	combiner.add_child(floor)
	
	# Ceiling
	var ceiling = CSGBox3D.new()
	ceiling.size = Vector3(size.x, WALL_THICKNESS, size.z)
	ceiling.position = Vector3(0, size.y/2, 0)
	ceiling.material = materials["ceiling"]
	combiner.add_child(ceiling)
	
	# Cut doorways
	for direction in doors:
		if doors[direction]:
			var doorway = CSGBox3D.new()
			doorway.size = Vector3(2, 2.5, 1)
			doorway.operation = CSGShape3D.OPERATION_SUBTRACTION
			
			match direction:
				"north":
					doorway.position = Vector3(0, -size.y/2 + 1.25 + 0.3, size.z/2)
				"south":
					doorway.position = Vector3(0, -size.y/2 + 1.25 + 0.3, -size.z/2)
				"east":
					doorway.position = Vector3(size.x/2, -size.y/2 + 1.25 + 0.3, 0)
					doorway.rotation.y = PI/2
				"west":
					doorway.position = Vector3(-size.x/2, -size.y/2 + 1.25 + 0.3, 0)
					doorway.rotation.y = PI/2
			
			combiner.add_child(doorway)
	
	# Add room type indicator
	room.add_to_group("rooms")
	room.add_to_group(room_type + "_rooms")
	room.set_meta("room_type", room_type)
	room.set_meta("room_size", size)
	
	return room

func create_corridor(name: String, pos: Vector3, size: Vector3, is_horizontal: bool) -> Node3D:
	var corridor = Node3D.new()
	corridor.name = name
	corridor.position = pos
	
	var combiner = CSGCombiner3D.new()
	combiner.use_collision = true
	corridor.add_child(combiner)
	
	# Floor
	var floor = CSGBox3D.new()
	floor.size = Vector3(size.x, WALL_THICKNESS, size.z)
	floor.position = Vector3(0, -size.y/2, 0)
	floor.material = materials["floor"]
	combiner.add_child(floor)
	
	# Ceiling
	var ceiling = CSGBox3D.new()
	ceiling.size = Vector3(size.x, WALL_THICKNESS, size.z)
	ceiling.position = Vector3(0, size.y/2, 0)
	ceiling.material = materials["ceiling"]
	combiner.add_child(ceiling)
	
	# Walls (only on long sides)
	if is_horizontal:
		# North wall
		var north = CSGBox3D.new()
		north.size = Vector3(size.x, size.y, WALL_THICKNESS)
		north.position = Vector3(0, 0, size.z/2)
		north.material = materials["wall"]
		combiner.add_child(north)
		
		# South wall
		var south = CSGBox3D.new()
		south.size = Vector3(size.x, size.y, WALL_THICKNESS)
		south.position = Vector3(0, 0, -size.z/2)
		south.material = materials["wall"]
		combiner.add_child(south)
	else:
		# East wall
		var east = CSGBox3D.new()
		east.size = Vector3(WALL_THICKNESS, size.y, size.z)
		east.position = Vector3(size.x/2, 0, 0)
		east.material = materials["wall"]
		combiner.add_child(east)
		
		# West wall
		var west = CSGBox3D.new()
		west.size = Vector3(WALL_THICKNESS, size.y, size.z)
		west.position = Vector3(-size.x/2, 0, 0)
		west.material = materials["wall"]
		combiner.add_child(west)
	
	corridor.add_to_group("corridors")
	return corridor

func create_elevator_shaft(parent: Node3D, name: String, pos: Vector3):
	var elevator = Node3D.new()
	elevator.name = name
	elevator.position = pos
	parent.add_child(elevator)
	
	var shaft = CSGBox3D.new()
	shaft.size = Vector3(4, 20, 4)
	shaft.position = Vector3(0, 0, 0)
	shaft.material = materials["wall"]
	shaft.use_collision = true
	elevator.add_child(shaft)
	
	# Hollow interior
	var hollow = CSGBox3D.new()
	hollow.size = Vector3(3.5, 19.5, 3.5)
	hollow.operation = CSGShape3D.OPERATION_SUBTRACTION
	elevator.add_child(hollow)
	
	# Door openings at each level
	for level_name in level_positions:
		var door_cutout = CSGBox3D.new()
		door_cutout.size = Vector3(2, 2.5, 1)
		door_cutout.position = Vector3(0, level_positions[level_name] - 0.75, 2)
		door_cutout.operation = CSGShape3D.OPERATION_SUBTRACTION
		elevator.add_child(door_cutout)

func create_stairwell(parent: Node3D, name: String, pos: Vector3):
	var stairwell = Node3D.new()
	stairwell.name = name
	stairwell.position = pos
	parent.add_child(stairwell)
	
	var shaft = CSGBox3D.new()
	shaft.size = Vector3(4, 20, 4)
	shaft.position = Vector3(0, 0, 0)
	shaft.material = materials["wall"]
	shaft.use_collision = true
	stairwell.add_child(shaft)
	
	# Hollow interior
	var hollow = CSGBox3D.new()
	hollow.size = Vector3(3.5, 19.5, 3.5)
	hollow.operation = CSGShape3D.OPERATION_SUBTRACTION
	stairwell.add_child(hollow)
	
	# Emergency lighting
	var emergency_strip = CSGBox3D.new()
	emergency_strip.size = Vector3(0.2, 19, 0.2)
	emergency_strip.position = Vector3(1.5, 0, 1.5)
	emergency_strip.material = materials["emergency"]
	stairwell.add_child(emergency_strip)

func create_maintenance_tunnel(name: String, pos: Vector3, size: Vector3) -> Node3D:
	var tunnel = Node3D.new()
	tunnel.name = name
	tunnel.position = pos
	
	var combiner = CSGCombiner3D.new()
	combiner.use_collision = true
	tunnel.add_child(combiner)
	
	# Outer shell
	var outer = CSGBox3D.new()
	outer.size = size
	outer.material = materials["maintenance"]
	combiner.add_child(outer)
	
	# Hollow interior
	var inner = CSGBox3D.new()
	inner.size = size - Vector3(0.2, 0.2, 0.2)
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	combiner.add_child(inner)
	
	tunnel.add_to_group("maintenance_tunnels")
	return tunnel

func _add_core_features(core: Node3D):
	# Add platforms at each level
	for level_name in level_positions:
		var platform = CSGBox3D.new()
		platform.size = Vector3(6, 0.3, 6)
		platform.position = Vector3(0, level_positions[level_name], 0)
		platform.material = materials["floor"]
		platform.use_collision = true
		core.add_child(platform)
		
		# Cut hole for shaft access
		var hole = CSGBox3D.new()
		hole.size = Vector3(4, 0.5, 4)
		hole.position = platform.position
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		core.add_child(hole)

func _add_lighting_system():
	var lights = Node3D.new()
	lights.name = "StationLighting"
	station_root.add_child(lights)
	
	# Add lights for each level
	for level_name in level_positions:
		var level_lights = Node3D.new()
		level_lights.name = "Lights_" + level_name
		level_lights.position.y = level_positions[level_name] + 3.0
		lights.add_child(level_lights)
		
		# Grid of lights
		for x in range(-3, 4):
			for z in range(-3, 4):
				var light = OmniLight3D.new()
				light.name = "Light_" + str(x) + "_" + str(z)
				light.position = Vector3(x * 8, 0, z * 8)
				light.omni_range = 10
				light.light_energy = 1.5
				light.shadow_enabled = true
				level_lights.add_child(light)

func _add_navigation_aids():
	var nav_aids = Node3D.new()
	nav_aids.name = "NavigationAids"
	station_root.add_child(nav_aids)
	
	# Level indicators
	for level_name in level_positions:
		var level_label = Label3D.new()
		level_label.name = "Label_" + level_name
		level_label.text = level_name.to_upper() + " LEVEL"
		level_label.position = Vector3(0, level_positions[level_name] + 2.5, 5)
		level_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		level_label.font_size = 64
		level_label.outline_size = 10
		nav_aids.add_child(level_label)