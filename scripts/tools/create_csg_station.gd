@tool
extends EditorScript

func _run():
    print("=== Create CSG Station Geometry ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    # Find or create CSGStation node
    var csg_station = edited_scene.find_child("CSGStation", true, false)
    if csg_station:
        csg_station.queue_free()
    
    csg_station = Node3D.new()
    csg_station.name = "CSGStation"
    edited_scene.add_child(csg_station)
    csg_station.owner = edited_scene
    
    print("Creating CSG-based station geometry...")
    
    # Main hallway floor
    var hallway_floor = CSGBox3D.new()
    hallway_floor.name = "HallwayFloor"
    hallway_floor.size = Vector3(6, 0.2, 50)  # 6 units wide, 50 long
    hallway_floor.position = Vector3(0, -0.1, 0)
    hallway_floor.use_collision = true
    csg_station.add_child(hallway_floor)
    hallway_floor.owner = edited_scene
    
    # Hallway walls
    var left_wall = CSGBox3D.new()
    left_wall.name = "LeftWall"
    left_wall.size = Vector3(0.5, 3, 50)
    left_wall.position = Vector3(-3.25, 1.5, 0)
    left_wall.use_collision = true
    csg_station.add_child(left_wall)
    left_wall.owner = edited_scene
    
    var right_wall = CSGBox3D.new()
    right_wall.name = "RightWall"
    right_wall.size = Vector3(0.5, 3, 50)
    right_wall.position = Vector3(3.25, 1.5, 0)
    right_wall.use_collision = true
    csg_station.add_child(right_wall)
    right_wall.owner = edited_scene
    
    # Create rooms on the left side
    var left_rooms = [
        {"name": "Laboratory3", "pos": Vector3(-10, 0, 10), "size": Vector3(12, 3, 10)},
        {"name": "SecurityOffice", "pos": Vector3(-10, 0, -5), "size": Vector3(12, 3, 8)},
        {"name": "CrewQuarters", "pos": Vector3(-10, 0, -15), "size": Vector3(12, 3, 8)}
    ]
    
    for room_data in left_rooms:
        # Room floor
        var room_floor = CSGBox3D.new()
        room_floor.name = room_data.name + "_Floor"
        room_floor.size = Vector3(room_data.size.x, 0.2, room_data.size.z)
        room_floor.position = room_data.pos + Vector3(0, -0.1, 0)
        room_floor.use_collision = true
        csg_station.add_child(room_floor)
        room_floor.owner = edited_scene
        
        # Back wall
        var back_wall = CSGBox3D.new()
        back_wall.name = room_data.name + "_BackWall"
        back_wall.size = Vector3(room_data.size.x, room_data.size.y, 0.5)
        back_wall.position = room_data.pos + Vector3(0, room_data.size.y/2, -room_data.size.z/2 - 0.25)
        back_wall.use_collision = true
        csg_station.add_child(back_wall)
        back_wall.owner = edited_scene
        
        # Front wall
        var front_wall = CSGBox3D.new()
        front_wall.name = room_data.name + "_FrontWall"
        front_wall.size = Vector3(room_data.size.x, room_data.size.y, 0.5)
        front_wall.position = room_data.pos + Vector3(0, room_data.size.y/2, room_data.size.z/2 + 0.25)
        front_wall.use_collision = true
        csg_station.add_child(front_wall)
        front_wall.owner = edited_scene
        
        # Outer wall
        var outer_wall = CSGBox3D.new()
        outer_wall.name = room_data.name + "_OuterWall"
        outer_wall.size = Vector3(0.5, room_data.size.y, room_data.size.z + 1)
        outer_wall.position = room_data.pos + Vector3(-room_data.size.x/2 - 0.25, room_data.size.y/2, 0)
        outer_wall.use_collision = true
        csg_station.add_child(outer_wall)
        outer_wall.owner = edited_scene
        
        # Door opening (subtract from hallway wall)
        var door_opening = CSGBox3D.new()
        door_opening.name = room_data.name + "_DoorOpening"
        door_opening.operation = CSGShape3D.OPERATION_SUBTRACTION
        door_opening.size = Vector3(1, 2.5, 3)
        door_opening.position = Vector3(-3.25, 1.25, room_data.pos.z)
        left_wall.add_child(door_opening)
        door_opening.owner = edited_scene
    
    # Create rooms on the right side
    var right_rooms = [
        {"name": "MedicalBay", "pos": Vector3(10, 0, 5), "size": Vector3(12, 3, 8)},
        {"name": "Engineering", "pos": Vector3(10, 0, -10), "size": Vector3(12, 3, 10)},
        {"name": "Cafeteria", "pos": Vector3(10, 0, -20), "size": Vector3(12, 3, 8)}
    ]
    
    for room_data in right_rooms:
        # Room floor
        var room_floor = CSGBox3D.new()
        room_floor.name = room_data.name + "_Floor"
        room_floor.size = Vector3(room_data.size.x, 0.2, room_data.size.z)
        room_floor.position = room_data.pos + Vector3(0, -0.1, 0)
        room_floor.use_collision = true
        csg_station.add_child(room_floor)
        room_floor.owner = edited_scene
        
        # Back wall
        var back_wall = CSGBox3D.new()
        back_wall.name = room_data.name + "_BackWall"
        back_wall.size = Vector3(room_data.size.x, room_data.size.y, 0.5)
        back_wall.position = room_data.pos + Vector3(0, room_data.size.y/2, -room_data.size.z/2 - 0.25)
        back_wall.use_collision = true
        csg_station.add_child(back_wall)
        back_wall.owner = edited_scene
        
        # Front wall
        var front_wall = CSGBox3D.new()
        front_wall.name = room_data.name + "_FrontWall"
        front_wall.size = Vector3(room_data.size.x, room_data.size.y, 0.5)
        front_wall.position = room_data.pos + Vector3(0, room_data.size.y/2, room_data.size.z/2 + 0.25)
        front_wall.use_collision = true
        csg_station.add_child(front_wall)
        front_wall.owner = edited_scene
        
        # Outer wall
        var outer_wall = CSGBox3D.new()
        outer_wall.name = room_data.name + "_OuterWall"
        outer_wall.size = Vector3(0.5, room_data.size.y, room_data.size.z + 1)
        outer_wall.position = room_data.pos + Vector3(room_data.size.x/2 + 0.25, room_data.size.y/2, 0)
        outer_wall.use_collision = true
        csg_station.add_child(outer_wall)
        outer_wall.owner = edited_scene
        
        # Door opening
        var door_opening = CSGBox3D.new()
        door_opening.name = room_data.name + "_DoorOpening"
        door_opening.operation = CSGShape3D.OPERATION_SUBTRACTION
        door_opening.size = Vector3(1, 2.5, 3)
        door_opening.position = Vector3(3.25, 1.25, room_data.pos.z)
        right_wall.add_child(door_opening)
        door_opening.owner = edited_scene
    
    # Add ceiling
    var ceiling = CSGBox3D.new()
    ceiling.name = "Ceiling"
    ceiling.size = Vector3(30, 0.2, 50)
    ceiling.position = Vector3(0, 3, 0)
    ceiling.use_collision = true
    csg_station.add_child(ceiling)
    ceiling.owner = edited_scene
    
    # Add materials
    var floor_material = StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.3, 0.3, 0.3)
    hallway_floor.material = floor_material
    
    var wall_material = StandardMaterial3D.new()
    wall_material.albedo_color = Color(0.5, 0.5, 0.6)
    left_wall.material = wall_material
    right_wall.material = wall_material
    
    print("\n✓ CSG Station created!")
    print("\nStation layout:")
    print("- Central hallway: 6 units wide, 50 units long")
    print("- Left side rooms: Laboratory 3, Security Office, Crew Quarters")
    print("- Right side rooms: Medical Bay, Engineering, Cafeteria")
    print("- All geometry has proper collision enabled")
    print("\nYou can now:")
    print("1. Disable the original Station mesh")
    print("2. Test NPC movement with CSG geometry")
    print("3. Adjust room sizes/positions as needed")
