extends Node3D
class_name ExpandedStationWaypoints

# Adds waypoints to the expanded station for NPC navigation

func _ready():
    _create_waypoint_system()

func _create_waypoint_system():
    var waypoint_scene = load("res://scenes/navigation/waypoint.tscn")
    if not waypoint_scene:
        push_error("ExpandedStationWaypoints: Failed to load waypoint scene!")
        return
    
    # Main hallway waypoints (every 10 units)
    for z in range(-35, 36, 10):
        var wp = waypoint_scene.instantiate()
        if not wp:
            push_error("Failed to instantiate waypoint!")
            continue
        wp.name = "Hallway_" + str(z)
        wp.position = Vector3(0, 0.1, z)
        wp.room_name = "hallway"
        add_child(wp)
    
    # Cross corridor waypoints
    var cross_corridors = [
        {"z": -30, "name": "south"},
        {"z": 0, "name": "central"},
        {"z": 30, "name": "north"}
    ]
    
    for corridor in cross_corridors:
        for x in [-15, -10, -5, 0, 5, 10, 15]:
            var wp = waypoint_scene.instantiate()
            wp.name = "Cross_" + corridor.name + "_" + str(x)
            wp.position = Vector3(x, 0.1, corridor.z)
            wp.room_name = "corridor_" + corridor.name
            add_child(wp)
    
    # Room waypoints
    var room_waypoints = {
        "medical_bay": [
            {"pos": Vector3(10, 0.1, 5), "activity": "entrance"},
            {"pos": Vector3(8, 0.1, 3), "activity": "examination"},
            {"pos": Vector3(12, 0.1, 5), "activity": "supplies"},
            {"pos": Vector3(10, 0.1, 7), "activity": "desk"}
        ],
        "surgery_suite": [
            {"pos": Vector3(10, 0.1, -8), "activity": "entrance"},
            {"pos": Vector3(8, 0.1, -10), "activity": "equipment"},
            {"pos": Vector3(12, 0.1, -8), "activity": "supplies"}
        ],
        "laboratory_1": [
            {"pos": Vector3(-10, 0.1, 10), "activity": "entrance"},
            {"pos": Vector3(-8, 0.1, 12), "activity": "workstation"},
            {"pos": Vector3(-12, 0.1, 10), "activity": "equipment"},
            {"pos": Vector3(-10, 0.1, 8), "activity": "research"}
        ],
        "laboratory_2": [
            {"pos": Vector3(-10, 0.1, -2), "activity": "entrance"},
            {"pos": Vector3(-8, 0.1, -4), "activity": "workstation"},
            {"pos": Vector3(-12, 0.1, -2), "activity": "research"}
        ],
        "crew_quarters_1": [
            {"pos": Vector3(-10, 0.1, -15), "activity": "entrance"},
            {"pos": Vector3(-8, 0.1, -17), "activity": "bed1"},
            {"pos": Vector3(-12, 0.1, -15), "activity": "bed2"}
        ],
        "crew_quarters_2": [
            {"pos": Vector3(-10, 0.1, -25), "activity": "entrance"},
            {"pos": Vector3(-8, 0.1, -27), "activity": "bed1"},
            {"pos": Vector3(-12, 0.1, -25), "activity": "bed2"}
        ],
        "cafeteria": [
            {"pos": Vector3(10, 0.1, -20), "activity": "entrance"},
            {"pos": Vector3(8, 0.1, -18), "activity": "tables"},
            {"pos": Vector3(12, 0.1, -20), "activity": "kitchen"},
            {"pos": Vector3(10, 0.1, -22), "activity": "storage"}
        ],
        "recreation": [
            {"pos": Vector3(10, 0.1, -32), "activity": "entrance"},
            {"pos": Vector3(8, 0.1, -34), "activity": "seating"},
            {"pos": Vector3(12, 0.1, -32), "activity": "entertainment"}
        ],
        "fitness_center": [
            {"pos": Vector3(-10, 0.1, -35), "activity": "entrance"},
            {"pos": Vector3(-8, 0.1, -37), "activity": "equipment"},
            {"pos": Vector3(-12, 0.1, -35), "activity": "storage"}
        ],
        "storage_b1": [
            {"pos": Vector3(-10, 0.1, 25), "activity": "entrance"},
            {"pos": Vector3(-8, 0.1, 27), "activity": "shelves"},
            {"pos": Vector3(-12, 0.1, 25), "activity": "crates"}
        ],
        "janitor_closet": [
            {"pos": Vector3(10, 0.1, 25), "activity": "entrance"},
            {"pos": Vector3(8, 0.1, 25), "activity": "supplies"}
        ]
    }
    
    # Create room waypoints
    for room_name in room_waypoints:
        var room_wps = room_waypoints[room_name]
        for i in range(room_wps.size()):
            var wp_data = room_wps[i]
            var wp = waypoint_scene.instantiate()
            wp.name = room_name + "_" + wp_data.activity
            wp.position = wp_data.pos
            wp.room_name = room_name
            wp.waypoint_type = wp_data.activity
            wp.set_meta("activity", wp_data.activity)
            add_child(wp)
            
            # Connect to other waypoints in same room
            if i > 0:
                var prev_wp_name = room_name + "_" + room_wps[i-1].activity
                var prev_wp = get_node_or_null(prev_wp_name)
                if prev_wp:
                    wp.set_meta("connected_to", [prev_wp.get_path()])
                    var prev_connections = prev_wp.get_meta("connected_to", [])
                    prev_connections.append(wp.get_path())
                    prev_wp.set_meta("connected_to", prev_connections)
    
    print("Created waypoint system with ", get_child_count(), " waypoints")
