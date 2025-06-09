extends Node3D
class_name ModularStationWaypoints

# Creates waypoints for the modular station layout

func _ready():
    _create_waypoint_system()

func _create_waypoint_system():
    var waypoint_scene = load("res://scenes/navigation/waypoint.tscn")
    if not waypoint_scene:
        push_error("ModularStationWaypoints: Failed to load waypoint scene!")
        return
    
    # Main corridor waypoints every 10m
    _create_main_corridor_waypoints(waypoint_scene)
    
    # Cross corridor waypoints
    _create_cross_corridor_waypoints(waypoint_scene)
    
    # Room waypoints
    _create_room_waypoints(waypoint_scene)
    
    # Maintenance tunnel waypoints
    _create_maintenance_waypoints(waypoint_scene)
    
    print("Created modular station waypoint system with ", get_child_count(), " waypoints")

func _create_main_corridor_waypoints(waypoint_scene: PackedScene):
    for z in range(-35, 36, 5):
        var wp = waypoint_scene.instantiate()
        if not wp:
            continue
        wp.name = "MainCorridor_" + str(z)
        wp.position = Vector3(0, 0.1, z)
        wp.room_name = "main_corridor"
        wp.waypoint_type = "transit"
        add_child(wp)

func _create_cross_corridor_waypoints(waypoint_scene: PackedScene):
    var cross_positions = [
        {"z": -40, "name": "south"},
        {"z": -20, "name": "crew"},
        {"z": 0, "name": "medical"},
        {"z": 20, "name": "science"}
    ]
    
    for corridor in cross_positions:
        # Left side
        for x in [-16, -12, -8, -4]:
            var wp = waypoint_scene.instantiate()
            if not wp:
                continue
            wp.name = "Cross_" + corridor.name + "_left_" + str(x)
            wp.position = Vector3(x, 0.1, corridor.z)
            wp.room_name = "cross_" + corridor.name
            wp.waypoint_type = "transit"
            add_child(wp)
        
        # Right side
        for x in [4, 8, 12, 16]:
            var wp = waypoint_scene.instantiate()
            if not wp:
                continue
            wp.name = "Cross_" + corridor.name + "_right_" + str(x)
            wp.position = Vector3(x, 0.1, corridor.z)
            wp.room_name = "cross_" + corridor.name
            wp.waypoint_type = "transit"
            add_child(wp)

func _create_room_waypoints(waypoint_scene: PackedScene):
    var room_configs = {
        # Section A - Command
        "SecurityCenter": {
            "center": Vector3(-16, 0.1, 35),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(-3, 0, -3), "type": "desk"},
                {"offset": Vector3(3, 0, -3), "type": "monitors"},
                {"offset": Vector3(0, 0, 3), "type": "equipment"}
            ]
        },
        "CommunicationsHub": {
            "center": Vector3(12, 0.1, 38),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(2, 0, 2), "type": "console"},
                {"offset": Vector3(-2, 0, -2), "type": "equipment"}
            ]
        },
        # Section B - Science
        "Laboratory1": {
            "center": Vector3(-17, 0.1, 25),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(-4, 0, -3), "type": "workstation"},
                {"offset": Vector3(4, 0, -3), "type": "equipment"},
                {"offset": Vector3(0, 0, 3), "type": "storage"}
            ]
        },
        "Laboratory3_CrimeScene": {
            "center": Vector3(17, 0.1, 25),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(-3, 0, -2), "type": "crime_scene"},
                {"offset": Vector3(3, 0, -2), "type": "workstation"},
                {"offset": Vector3(0, 0, 3), "type": "equipment"}
            ]
        },
        # Section C - Medical
        "MedicalBay": {
            "center": Vector3(17, 0.1, 5),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(-4, 0, -2), "type": "examination"},
                {"offset": Vector3(4, 0, -2), "type": "supplies"},
                {"offset": Vector3(0, 0, 3), "type": "desk"}
            ]
        },
        # Section D - Crew Support
        "Cafeteria": {
            "center": Vector3(18, 0.1, -20),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(-5, 0, -3), "type": "kitchen"},
                {"offset": Vector3(5, 0, -3), "type": "storage"},
                {"offset": Vector3(-3, 0, 3), "type": "tables"},
                {"offset": Vector3(3, 0, 3), "type": "tables"}
            ]
        },
        # Section E - Quarters
        "QuartersBlockA": {
            "center": Vector3(18, 0.1, -35),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(-6, 0, 0), "type": "room1"},
                {"offset": Vector3(-2, 0, 0), "type": "room2"},
                {"offset": Vector3(2, 0, 0), "type": "room3"},
                {"offset": Vector3(6, 0, 0), "type": "room4"}
            ]
        },
        # Section F - Engineering
        "MainEngineering": {
            "center": Vector3(-18, 0.1, -58),
            "waypoints": [
                {"offset": Vector3(0, 0, 0), "type": "entrance"},
                {"offset": Vector3(-5, 0, -4), "type": "console"},
                {"offset": Vector3(5, 0, -4), "type": "power"},
                {"offset": Vector3(0, 0, 4), "type": "repairs"}
            ]
        }
    }
    
    for room_name in room_configs:
        var config = room_configs[room_name]
        for wp_data in config.waypoints:
            var wp = waypoint_scene.instantiate()
            if not wp:
                continue
            wp.name = room_name + "_" + wp_data.type
            wp.position = config.center + wp_data.offset
            wp.room_name = room_name
            wp.waypoint_type = wp_data.type
            add_child(wp)

func _create_maintenance_waypoints(waypoint_scene: PackedScene):
    # Main maintenance tunnel
    for z in range(-30, 31, 10):
        var wp = waypoint_scene.instantiate()
        if not wp:
            continue
        wp.name = "Maintenance_Main_" + str(z)
        wp.position = Vector3(-25, -0.9, z)
        wp.room_name = "maintenance"
        wp.waypoint_type = "tunnel"
        add_child(wp)
    
    # Cross tunnel access points
    var cross_z = [-30, -10, 10, 30]
    for z in cross_z:
        for x in [-20, -15, -10, -5, 0]:
            var wp = waypoint_scene.instantiate()
            if not wp:
                continue
            wp.name = "Maintenance_Cross_" + str(z) + "_" + str(x)
            wp.position = Vector3(x, -0.9, z)
            wp.room_name = "maintenance"
            wp.waypoint_type = "access"
            add_child(wp)