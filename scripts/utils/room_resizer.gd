@tool
extends Node

# Tool script to help resize rooms in the editor
# Attach this to a room node to get resize controls

@export_group("Room Dimensions")
@export var room_width: float = 8.0:
	set(value):
		room_width = value
		if Engine.is_editor_hint():
			_update_room_size()

@export var room_depth: float = 8.0:
	set(value):
		room_depth = value
		if Engine.is_editor_hint():
			_update_room_size()

@export var room_height: float = 4.0:
	set(value):
		room_height = value
		if Engine.is_editor_hint():
			_update_room_size()

@export var apply_changes: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_update_room_size()
			apply_changes = false

func _ready():
	if not Engine.is_editor_hint():
		queue_free()  # Remove in game

func _update_room_size():
	if not Engine.is_editor_hint():
		return
		
	# Find room combiner
	var combiner = get_node_or_null("RoomCombiner")
	if not combiner:
		print("Room Resizer: No RoomCombiner found!")
		return
	
	# Update floor
	var floor = combiner.get_node_or_null("Floor")
	if floor and floor is CSGBox3D:
		floor.size = Vector3(room_width, 0.2, room_depth)
		print("Updated floor size")
	
	# Update ceiling
	var ceiling = combiner.get_node_or_null("Ceiling")
	if ceiling and ceiling is CSGBox3D:
		ceiling.size = Vector3(room_width, 0.2, room_depth)
		ceiling.position.y = room_height
		print("Updated ceiling size")
	
	# Update walls
	_update_wall("LeftWall", Vector3(0.2, room_height, room_depth), 
				Vector3(-room_width/2, room_height/2, 0))
	_update_wall("RightWall", Vector3(0.2, room_height, room_depth), 
				Vector3(room_width/2, room_height/2, 0))
	_update_wall("BackWall", Vector3(room_width, room_height, 0.2), 
				Vector3(0, room_height/2, -room_depth/2))
	_update_wall("FrontWall", Vector3(room_width, room_height, 0.2), 
				Vector3(0, room_height/2, room_depth/2))
	
	# Handle split walls (for doors)
	_update_wall("LeftWallFront", Vector3(0.2, room_height, room_depth/2 - 1), 
				Vector3(-room_width/2, room_height/2, room_depth/4 + 0.5))
	_update_wall("LeftWallBack", Vector3(0.2, room_height, room_depth/2 - 1), 
				Vector3(-room_width/2, room_height/2, -room_depth/4 - 0.5))
	_update_wall("LeftWallTop", Vector3(0.2, 1, 2), 
				Vector3(-room_width/2, room_height - 0.5, 0))
				
	_update_wall("RightWallFront", Vector3(0.2, room_height, room_depth/2 - 1), 
				Vector3(room_width/2, room_height/2, room_depth/4 + 0.5))
	_update_wall("RightWallBack", Vector3(0.2, room_height, room_depth/2 - 1), 
				Vector3(room_width/2, room_height/2, -room_depth/4 - 0.5))
	_update_wall("RightWallTop", Vector3(0.2, 1, 2), 
				Vector3(room_width/2, room_height - 0.5, 0))
	
	# Update door cutouts
	_update_door_cutout("DoorCutout", Vector3(room_width/2, room_height/2 - 0.5, 0))
	
	print("Room resized to: ", room_width, "x", room_depth, "x", room_height)

func _update_wall(wall_name: String, size: Vector3, position: Vector3):
	var combiner = get_node_or_null("RoomCombiner")
	if not combiner:
		return
		
	var wall = combiner.get_node_or_null(wall_name)
	if wall and wall is CSGBox3D:
		wall.size = size
		wall.position = position

func _update_door_cutout(cutout_name: String, position: Vector3):
	var combiner = get_node_or_null("RoomCombiner")
	if not combiner:
		return
		
	var cutout = combiner.get_node_or_null(cutout_name)
	if cutout and cutout is CSGBox3D:
		cutout.position = position