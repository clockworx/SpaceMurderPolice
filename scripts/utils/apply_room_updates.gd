extends Node

# Script to generate updated room configurations
# Run this to get the modifications needed for aurora_station.tscn

func print_room_updates():
    print("\n=== ROOM SIZE UPDATES FOR AURORA_STATION.TSCN ===\n")
    
    # Laboratory3 - 14x14
    print("Laboratory3 Updates:")
    print("  Floor size: Vector3(14, 0.2, 14)")
    print("  Ceiling size: Vector3(14, 0.2, 14)")
    print("  LeftWall position: Vector3(-7, 2, 0), size: Vector3(0.2, 4, 14)")
    print("  RightWall split for door - RightWallLeft position: Vector3(7, 2, -4), size: Vector3(0.2, 4, 6)")
    print("  RightWallRight position: Vector3(7, 2, 4), size: Vector3(0.2, 4, 6)")
    print("  BackWall position: Vector3(0, 2, -7), size: Vector3(14, 4, 0.2)")
    print("  FrontWall position: Vector3(0, 2, 7), size: Vector3(14, 4, 0.2)")
    print("  DoorCutout position: Vector3(7, 1.5, 0)")
    print("")
    
    # Medical Bay - 12x12
    print("MedicalBay Updates:")
    print("  Floor size: Vector3(12, 0.2, 12)")
    print("  Ceiling size: Vector3(12, 0.2, 12)")
    print("  RightWall position: Vector3(6, 2, 0), size: Vector3(0.2, 4, 12)")
    print("  LeftWall split for door - LeftWallFront position: Vector3(-6, 2, 4), size: Vector3(0.2, 4, 4)")
    print("  LeftWallBack position: Vector3(-6, 2, -4), size: Vector3(0.2, 4, 4)")
    print("  BackWall position: Vector3(0, 2, -6), size: Vector3(12, 4, 0.2)")
    print("  FrontWall position: Vector3(0, 2, 6), size: Vector3(12, 4, 0.2)")
    print("  DoorCutout position: Vector3(-6, 1.5, 0)")
    print("")
    
    # Security Office - 12x12
    print("SecurityOffice Updates:")
    print("  Floor size: Vector3(12, 0.2, 12)")
    print("  Ceiling size: Vector3(12, 0.2, 12)")
    print("  LeftWall position: Vector3(-6, 2, 0), size: Vector3(0.2, 4, 12)")
    print("  RightWall split for door")
    print("  BackWall position: Vector3(0, 2, -6), size: Vector3(12, 4, 0.2)")
    print("  FrontWall position: Vector3(0, 2, 6), size: Vector3(12, 4, 0.2)")
    print("  DoorCutout position: Vector3(6, 1.5, 0)")
    print("")
    
    # Engineering - 14x14
    print("Engineering Updates:")
    print("  Floor size: Vector3(14, 0.2, 14)")
    print("  Ceiling size: Vector3(14, 0.2, 14)")
    print("  RightWall position: Vector3(7, 2, 0), size: Vector3(0.2, 4, 14)")
    print("  LeftWall split for door")
    print("  BackWall position: Vector3(0, 2, -7), size: Vector3(14, 4, 0.2)")
    print("  FrontWall position: Vector3(0, 2, 7), size: Vector3(14, 4, 0.2)")
    print("  DoorCutout position: Vector3(-7, 1.5, 0)")
    print("")
    
    # Crew Quarters - 14x12
    print("CrewQuarters Updates:")
    print("  Floor size: Vector3(14, 0.2, 12)")
    print("  Ceiling size: Vector3(14, 0.2, 12)")
    print("  LeftWall position: Vector3(-7, 2, 0), size: Vector3(0.2, 4, 12)")
    print("  RightWall split for door")
    print("  BackWall position: Vector3(0, 2, -6), size: Vector3(14, 4, 0.2)")
    print("  FrontWall position: Vector3(0, 2, 6), size: Vector3(14, 4, 0.2)")
    print("  DoorCutout position: Vector3(7, 1.5, 0)")
    print("")
    
    # Cafeteria - 16x14
    print("Cafeteria Updates:")
    print("  Floor size: Vector3(16, 0.2, 14)")
    print("  Ceiling size: Vector3(16, 0.2, 14)")
    print("  RightWall position: Vector3(8, 2, 0), size: Vector3(0.2, 4, 14)")
    print("  LeftWall split for door")
    print("  BackWall position: Vector3(0, 2, -7), size: Vector3(16, 4, 0.2)")
    print("  FrontWall position: Vector3(0, 2, 7), size: Vector3(16, 4, 0.2)")
    print("  DoorCutout position: Vector3(-8, 1.5, 0)")
    print("")
    
    print("\n=== DOOR POSITION UPDATES ===\n")
    print("Laboratory3Door: transform = Transform3D(-4.37114e-08, 0, 1, 0, 1, 0, -1, 0, -4.37114e-08, -3, 0.1, 10)")
    print("MedicalDoor: transform = Transform3D(-4.37114e-08, 0, -1, 0, 1, 0, 1, 0, -4.37114e-08, 3, 0.1, 5)")
    print("SecurityDoor: transform = Transform3D(-4.37114e-08, 0, 1, 0, 1, 0, -1, 0, -4.37114e-08, -3, 0.1, -5)")
    print("EngineeringDoor: transform = Transform3D(-4.37114e-08, 0, -1, 0, 1, 0, 1, 0, -4.37114e-08, 3, 0.1, -10)")
    print("CrewQuartersDoor: transform = Transform3D(-4.37114e-08, 0, 1, 0, 1, 0, -1, 0, -4.37114e-08, -3, 0.1, -15)")
    print("CafeteriaDoor: transform = Transform3D(-4.37114e-08, 0, -1, 0, 1, 0, 1, 0, -4.37114e-08, 3, 0.1, -20)")
    
    print("\n=== WAYPOINT PLACEMENTS ===\n")
    print("Add these waypoints to each room's Waypoints node:")
    print("")
    print("Laboratory3/Waypoints:")
    print("  Waypoint1: position = Vector3(-5, 0.1, 5), waypoint_type = \"research\", room_name = \"laboratory\"")
    print("  Waypoint2: position = Vector3(5, 0.1, 5), waypoint_type = \"equipment\", room_name = \"laboratory\"")
    print("  Waypoint3: position = Vector3(-5, 0.1, -5), waypoint_type = \"workstation\", room_name = \"laboratory\"")
    print("  Waypoint4: position = Vector3(5, 0.1, -5), waypoint_type = \"wander\", room_name = \"laboratory\"")
    print("  Waypoint5: position = Vector3(0, 0.1, 0), waypoint_type = \"wander\", room_name = \"laboratory\"")
    print("")
    
    print("MedicalBay/Waypoints:")
    print("  Waypoint1: position = Vector3(-4, 0.1, 4), waypoint_type = \"examination\", room_name = \"medical\"")
    print("  Waypoint2: position = Vector3(4, 0.1, 4), waypoint_type = \"supplies\", room_name = \"medical\"")
    print("  Waypoint3: position = Vector3(-4, 0.1, -4), waypoint_type = \"desk\", room_name = \"medical\"")
    print("  Waypoint4: position = Vector3(4, 0.1, -4), waypoint_type = \"wander\", room_name = \"medical\"")
    print("")
    
    print("\n=== NPC POSITION UPDATES ===\n")
    print("Update NPC starting positions for larger rooms:")
    print("ChiefScientistNPC: transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, 0.1, 10)")
    print("MedicalOfficerNPC: transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 12, 0.1, 5)")
    print("SecurityChiefNPC: transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -10, 0.1, -5)")
    print("EngineerNPC (Riley): transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 10, 0.1, -10)")
    print("SecurityNPC: transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -10, 0.1, -15)")
    print("AISpecialistNPC: transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 12, 0.1, -20)")

# Also update room bounds in npc_base.gd
func print_room_bounds_update():
    print("\n=== UPDATE FOR NPC_BASE.GD ===\n")
    print("room_bounds = {")
    print('    "laboratory": {"min_x": -15.0, "max_x": -1.0, "min_z": 3.0, "max_z": 17.0},')
    print('    "medical": {"min_x": 2.0, "max_x": 14.0, "min_z": -1.0, "max_z": 11.0},')
    print('    "security": {"min_x": -14.0, "max_x": -2.0, "min_z": -11.0, "max_z": 1.0},')
    print('    "engineering": {"min_x": 1.0, "max_x": 15.0, "min_z": -17.0, "max_z": -3.0},')
    print('    "quarters": {"min_x": -15.0, "max_x": -1.0, "min_z": -21.0, "max_z": -9.0},')
    print('    "cafeteria": {"min_x": 0.0, "max_x": 16.0, "min_z": -27.0, "max_z": -13.0},')
    print('    "hallway": {"min_x": -3.0, "max_x": 3.0, "min_z": -30.0, "max_z": 22.5}')
    print("}")