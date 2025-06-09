@tool
extends Node

# Helper script to update room sizes and add waypoints
# This will modify the aurora_station.tscn file

# New room dimensions
var room_sizes = {
    "laboratory": Vector3(14, 4, 14),      # Larger for crime scene
    "medical": Vector3(12, 4, 12),         # Standard room
    "security": Vector3(12, 4, 12),        # Standard room  
    "engineering": Vector3(14, 4, 14),     # Larger for equipment
    "quarters": Vector3(14, 4, 12),        # Wider for beds
    "cafeteria": Vector3(16, 4, 14),       # Largest for tables
}

# Room center positions (adjusted for new sizes)
var room_positions = {
    "laboratory": Vector3(-8, 0, 10),
    "medical": Vector3(8, 0, 5),
    "security": Vector3(-8, 0, -5),
    "engineering": Vector3(8, 0, -10),
    "quarters": Vector3(-8, 0, -15),
    "cafeteria": Vector3(8, 0, -20),
}

# Waypoint configurations per room
var waypoint_configs = {
    "laboratory": [
        {"pos": Vector3(-3, 0.1, 3), "type": "research"},
        {"pos": Vector3(3, 0.1, 3), "type": "equipment"},
        {"pos": Vector3(-3, 0.1, -3), "type": "wander"},
        {"pos": Vector3(3, 0.1, -3), "type": "workstation"},
        {"pos": Vector3(0, 0.1, 5), "type": "wander"},
    ],
    "medical": [
        {"pos": Vector3(-3, 0.1, 3), "type": "examination"},
        {"pos": Vector3(3, 0.1, 3), "type": "supplies"},
        {"pos": Vector3(-3, 0.1, -3), "type": "desk"},
        {"pos": Vector3(3, 0.1, -3), "type": "wander"},
    ],
    "security": [
        {"pos": Vector3(-3, 0.1, 3), "type": "monitors"},
        {"pos": Vector3(3, 0.1, 3), "type": "weapons"},
        {"pos": Vector3(-3, 0.1, -3), "type": "desk"},
        {"pos": Vector3(3, 0.1, -3), "type": "wander"},
    ],
    "engineering": [
        {"pos": Vector3(-4, 0.1, 4), "type": "console"},
        {"pos": Vector3(4, 0.1, 4), "type": "repairs"},
        {"pos": Vector3(-4, 0.1, -4), "type": "storage"},
        {"pos": Vector3(4, 0.1, -4), "type": "wander"},
        {"pos": Vector3(0, 0.1, -5), "type": "wander"},
    ],
    "quarters": [
        {"pos": Vector3(-4, 0.1, 3), "type": "wander"},
        {"pos": Vector3(4, 0.1, 3), "type": "wander"},
        {"pos": Vector3(0, 0.1, -3), "type": "wander"},
    ],
    "cafeteria": [
        {"pos": Vector3(-5, 0.1, 4), "type": "kitchen"},
        {"pos": Vector3(5, 0.1, 4), "type": "tables"},
        {"pos": Vector3(-5, 0.1, -4), "type": "storage"},
        {"pos": Vector3(5, 0.1, -4), "type": "wander"},
        {"pos": Vector3(0, 0.1, 0), "type": "tables"},
    ],
}

func _ready():
    if not Engine.is_editor_hint():
        return
        
    print("Room Update Helper ready. Call update_rooms() to resize rooms and add waypoints.")

func update_rooms():
    if not Engine.is_editor_hint():
        print("This script only works in the editor!")
        return
        
    var scene_path = "res://scenes/levels/aurora_station.tscn"
    var packed_scene = load(scene_path) as PackedScene
    
    if not packed_scene:
        print("Failed to load scene!")
        return
        
    var scene = packed_scene.instantiate()
    
    # Update each room
    _update_room(scene, "Laboratory3", "laboratory")
    _update_room(scene, "MedicalBay", "medical") 
    _update_room(scene, "SecurityOffice", "security")
    _update_room(scene, "Engineering", "engineering")
    _update_room(scene, "CrewQuarters", "quarters")
    _update_room(scene, "Cafeteria", "cafeteria")
    
    # Add waypoints to each room
    _add_waypoints_to_room(scene, "Laboratory3", "laboratory")
    _add_waypoints_to_room(scene, "MedicalBay", "medical")
    _add_waypoints_to_room(scene, "SecurityOffice", "security")
    _add_waypoints_to_room(scene, "Engineering", "engineering") 
    _add_waypoints_to_room(scene, "CrewQuarters", "quarters")
    _add_waypoints_to_room(scene, "Cafeteria", "cafeteria")
    
    # Save the updated scene
    var new_scene = PackedScene.new()
    new_scene.pack(scene)
    ResourceSaver.save(new_scene, scene_path)
    
    print("Rooms updated and waypoints added successfully!")
    scene.queue_free()

func _update_room(scene: Node3D, room_node_name: String, room_key: String):
    var rooms_node = scene.get_node_or_null("Rooms")
    if not rooms_node:
        print("No Rooms node found!")
        return
        
    var room_node = rooms_node.get_node_or_null(room_node_name)
    if not room_node:
        print("Room node not found: ", room_node_name)
        return
        
    var combiner = room_node.get_node_or_null("RoomCombiner")
    if not combiner:
        print("No RoomCombiner found in ", room_node_name)
        return
        
    var size = room_sizes[room_key]
    var width = size.x
    var height = size.y
    var depth = size.z
    
    # Update floor
    var floor = combiner.get_node_or_null("Floor")
    if floor and floor is CSGBox3D:
        floor.size = Vector3(width, 0.2, depth)
        
    # Update ceiling
    var ceiling = combiner.get_node_or_null("Ceiling")
    if ceiling and ceiling is CSGBox3D:
        ceiling.size = Vector3(width, 0.2, depth)
        ceiling.position.y = height
        
    # Update walls
    _update_wall(combiner, "LeftWall", Vector3(0.2, height, depth), 
                Vector3(-width/2, height/2, 0))
    _update_wall(combiner, "RightWall", Vector3(0.2, height, depth), 
                Vector3(width/2, height/2, 0))
    _update_wall(combiner, "BackWall", Vector3(width, height, 0.2), 
                Vector3(0, height/2, -depth/2))
    _update_wall(combiner, "FrontWall", Vector3(width, height, 0.2), 
                Vector3(0, height/2, depth/2))
    
    # Update split walls (for doors)
    _update_wall(combiner, "LeftWallFront", Vector3(0.2, height, depth/2 - 1), 
                Vector3(-width/2, height/2, depth/4 + 0.5))
    _update_wall(combiner, "LeftWallBack", Vector3(0.2, height, depth/2 - 1), 
                Vector3(-width/2, height/2, -depth/4 - 0.5))
    _update_wall(combiner, "LeftWallTop", Vector3(0.2, 1, 2), 
                Vector3(-width/2, height - 0.5, 0))
                
    _update_wall(combiner, "RightWallFront", Vector3(0.2, height, depth/2 - 1), 
                Vector3(width/2, height/2, depth/4 + 0.5))
    _update_wall(combiner, "RightWallBack", Vector3(0.2, height, depth/2 - 1), 
                Vector3(width/2, height/2, -depth/4 - 0.5))
    _update_wall(combiner, "RightWallTop", Vector3(0.2, 1, 2), 
                Vector3(width/2, height - 0.5, 0))
    
    # Update door cutout position based on wall side
    var door_cutout = combiner.get_node_or_null("DoorCutout")
    if door_cutout and door_cutout is CSGBox3D:
        # Determine which side the door is on based on room
        if room_key in ["laboratory", "security", "quarters"]:
            # Left side rooms - door on right wall
            door_cutout.position = Vector3(width/2, height/2 - 0.5, 0)
        else:
            # Right side rooms - door on left wall
            door_cutout.position = Vector3(-width/2, height/2 - 0.5, 0)
    
    print("Updated room: ", room_node_name, " to size: ", size)

func _update_wall(combiner: Node, wall_name: String, size: Vector3, position: Vector3):
    var wall = combiner.get_node_or_null(wall_name)
    if wall and wall is CSGBox3D:
        wall.size = size
        wall.position = position

func _add_waypoints_to_room(scene: Node3D, room_node_name: String, room_key: String):
    var rooms_node = scene.get_node_or_null("Rooms")
    if not rooms_node:
        return
        
    var room_node = rooms_node.get_node_or_null(room_node_name)
    if not room_node:
        return
        
    # Create waypoints container if it doesn't exist
    var waypoints_node = room_node.get_node_or_null("Waypoints")
    if not waypoints_node:
        waypoints_node = Node3D.new()
        waypoints_node.name = "Waypoints"
        room_node.add_child(waypoints_node)
        waypoints_node.owner = scene
    
    # Load waypoint scene
    var waypoint_scene = load("res://scenes/navigation/waypoint.tscn") as PackedScene
    if not waypoint_scene:
        print("Failed to load waypoint scene!")
        return
        
    # Add waypoints based on configuration
    if not waypoint_configs.has(room_key):
        return
        
    var configs = waypoint_configs[room_key]
    var index = 1
    
    for config in configs:
        var waypoint = waypoint_scene.instantiate()
        waypoint.name = "Waypoint" + str(index)
        waypoint.position = config.pos
        waypoint.set("waypoint_type", config.type)
        waypoint.set("room_name", room_key)
        
        waypoints_node.add_child(waypoint)
        waypoint.owner = scene
        
        index += 1
    
    print("Added ", configs.size(), " waypoints to ", room_node_name)