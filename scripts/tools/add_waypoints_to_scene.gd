extends Node

# Script to add waypoints programmatically
# Attach this to a temporary node in the scene and run it

func _ready():
    # Find Waypoints parent
    var waypoints_parent = get_node("/root/NewStation/Waypoints")
    if not waypoints_parent:
        print("Waypoints node not found!")
        return
    
    # Waypoint definitions
    var waypoints = [
        # Room centers
        {"name": "Laboratory_Center", "pos": Vector3(0.0, 0.0, 10.0), "group": "Laboratory_Waypoint"},
        {"name": "MedicalBay_Center", "pos": Vector3(40.2, 0.0, -2.3), "group": "MedicalBay_Waypoint"},
        {"name": "Security_Center", "pos": Vector3(-12.3, 0.0, 8.0), "group": "Security_Waypoint"},
        {"name": "Engineering_Center", "pos": Vector3(-13.0, 0.0, 10.0), "group": "Engineering_Waypoint"},
        {"name": "CrewQuarters_Center", "pos": Vector3(4.0, 0.0, -28.0), "group": "CrewQuarters_Waypoint"},
        {"name": "Cafeteria_Center", "pos": Vector3(6.0, 0.0, 18.0), "group": "Cafeteria_Waypoint"},
        
        # Main hallway
        {"name": "Hallway_LabExit", "pos": Vector3(6.0, 0.0, 4.0), "group": "hallway"},
        {"name": "Hallway_Central", "pos": Vector3(0.0, 0.0, 4.0), "group": "hallway"},
        {"name": "Hallway_East", "pos": Vector3(15.0, 0.0, 4.0), "group": "hallway"},
        {"name": "Hallway_FarEast", "pos": Vector3(25.0, 0.0, 4.0), "group": "hallway"},
        {"name": "Hallway_MedicalApproach", "pos": Vector3(35.0, 0.0, 3.5), "group": "hallway"},
        {"name": "Hallway_West", "pos": Vector3(-10.0, 0.0, 4.0), "group": "hallway"},
        
        # South corridor
        {"name": "Hallway_SouthTurn", "pos": Vector3(0.0, 0.0, 0.0), "group": "hallway"},
        {"name": "Hallway_South", "pos": Vector3(0.0, 0.0, -4.0), "group": "hallway"},
        {"name": "Hallway_CrewTurn", "pos": Vector3(3.87, 0.0, -4.0), "group": "hallway"},
        {"name": "Hallway_CrewApproach", "pos": Vector3(3.87, 0.0, -20.0), "group": "hallway"},
        
        # North to cafeteria
        {"name": "Hallway_CafeteriaApproach", "pos": Vector3(6.0, 0.0, 10.0), "group": "hallway"}
    ]
    
    # Create waypoints
    for wp_data in waypoints:
        var waypoint = Node3D.new()
        waypoint.name = wp_data["name"]
        waypoint.position = wp_data["pos"]
        waypoint.add_to_group(wp_data["group"])
        waypoints_parent.add_child(waypoint)
        
        print("Created waypoint: ", wp_data["name"], " at ", wp_data["pos"])
    
    print("Total waypoints created: ", waypoints.size())
    
    # Self-destruct after creating waypoints
    queue_free()