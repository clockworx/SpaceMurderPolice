extends Node
class_name AdvancedNavigationManager

# Advanced navigation system using NavigationServer3D
# Features:
# - Smooth pathfinding with NavigationAgent3D
# - Dynamic obstacle avoidance
# - Multiple movement behaviors (patrol, investigate, chase, flee)
# - Waypoint systems with priorities
# - Group coordination to prevent NPCs bunching up

var navigation_region: NavigationRegion3D
var navigation_mesh: NavigationMesh
var waypoint_graph: Dictionary = {} # Room -> Array of waypoints
var occupied_positions: Dictionary = {} # Position -> NPC
var debug_draw_enabled: bool = true

# Navigation mesh settings for optimal NPC movement
const NAV_MESH_SETTINGS = {
    "cell_size": 0.25,  # Match the navigation map's cell size
    "cell_height": 0.25,
    "agent_height": 2.0,
    "agent_radius": 0.4,
    "agent_max_climb": 0.3,
    "agent_max_slope": 45.0,
    "region_min_size": 2,
    "region_merge_size": 20,
    "edge_max_length": 12.0,
    "edge_max_error": 1.3,
    "vertices_per_polygon": 6,
    "detail_sample_distance": 6.0,
    "detail_sample_max_error": 1.0
}

signal navigation_ready()

func _ready():
    add_to_group("advanced_navigation_manager")
    call_deferred("_setup_navigation")

func _setup_navigation():
    # Create NavigationRegion3D if it doesn't exist
    navigation_region = get_tree().get_first_node_in_group("navigation_region")
    if not navigation_region:
        navigation_region = NavigationRegion3D.new()
        navigation_region.name = "NavigationRegion3D"
        navigation_region.add_to_group("navigation_region")
        get_tree().current_scene.add_child(navigation_region)
        print("AdvancedNavigation: Created NavigationRegion3D")
    
    # Setup navigation mesh with optimal settings
    await _create_navigation_mesh()
    
    # Initialize waypoint system
    _setup_waypoints()
    
    navigation_ready.emit()

func _create_navigation_mesh():
    # Wait for the navigation region to exist first
    if not navigation_region:
        return
        
    navigation_mesh = NavigationMesh.new()
    
    # Apply optimal settings
    for setting in NAV_MESH_SETTINGS:
        navigation_mesh.set(setting, NAV_MESH_SETTINGS[setting])
    
    # Set up geometry parsing
    navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
    navigation_mesh.geometry_collision_mask = 1  # Environment layer
    
    # First set the mesh on the region
    navigation_region.navigation_mesh = navigation_mesh
    
    # Wait a frame for the navigation region to be properly initialized
    await get_tree().physics_frame
    
    # Force immediate navigation map update if the map exists
    var map_rid = NavigationServer3D.region_get_map(navigation_region.get_rid())
    if map_rid.is_valid():
        NavigationServer3D.map_force_update(map_rid)
    
    print("AdvancedNavigation: Navigation mesh configured")

func _setup_waypoints():
    # Define key waypoints for each room with metadata
    waypoint_graph = {
        "laboratory": [
            {"pos": Vector3(-8.5, 0.1, 10.0), "type": "work", "priority": 1},
            {"pos": Vector3(-10.0, 0.1, 8.0), "type": "corner", "priority": 0},
            {"pos": Vector3(-6.0, 0.1, 11.0), "type": "equipment", "priority": 2},
            {"pos": Vector3(-8.0, 0.1, 12.0), "type": "corner", "priority": 0},
            {"pos": Vector3(-7.0, 0.1, 9.0), "type": "entrance", "priority": 1}
        ],
        "medical": [
            {"pos": Vector3(7.0, 0.1, 5.0), "type": "work", "priority": 2},
            {"pos": Vector3(9.0, 0.1, 3.0), "type": "storage", "priority": 1},
            {"pos": Vector3(8.0, 0.1, 7.0), "type": "corner", "priority": 0},
            {"pos": Vector3(5.0, 0.1, 4.0), "type": "entrance", "priority": 1}
        ],
        "security": [
            {"pos": Vector3(-8.0, 0.1, -5.0), "type": "monitors", "priority": 2},
            {"pos": Vector3(-10.0, 0.1, -7.0), "type": "weapons", "priority": 1},
            {"pos": Vector3(-6.0, 0.1, -6.0), "type": "corner", "priority": 0},
            {"pos": Vector3(-7.0, 0.1, -3.0), "type": "entrance", "priority": 1}
        ],
        "engineering": [
            {"pos": Vector3(7.0, 0.1, -10.0), "type": "console", "priority": 2},
            {"pos": Vector3(9.0, 0.1, -12.0), "type": "machinery", "priority": 1},
            {"pos": Vector3(6.0, 0.1, -13.0), "type": "storage", "priority": 1},
            {"pos": Vector3(8.0, 0.1, -8.0), "type": "entrance", "priority": 1}
        ],
        "quarters": [
            {"pos": Vector3(-8.0, 0.1, -15.0), "type": "center", "priority": 1},
            {"pos": Vector3(-10.0, 0.1, -16.0), "type": "beds", "priority": 2},
            {"pos": Vector3(-6.0, 0.1, -14.0), "type": "lockers", "priority": 1},
            {"pos": Vector3(-9.0, 0.1, -17.0), "type": "corner", "priority": 0}
        ],
        "cafeteria": [
            {"pos": Vector3(8.0, 0.1, -20.0), "type": "tables", "priority": 2},
            {"pos": Vector3(9.0, 0.1, -22.0), "type": "kitchen", "priority": 1},
            {"pos": Vector3(6.0, 0.1, -19.0), "type": "seating", "priority": 2},
            {"pos": Vector3(10.0, 0.1, -21.0), "type": "storage", "priority": 0}
        ],
        "hallway": [
            {"pos": Vector3(0.0, 0.1, 15.0), "type": "junction", "priority": 1},
            {"pos": Vector3(0.0, 0.1, 10.0), "type": "corridor", "priority": 0},
            {"pos": Vector3(0.0, 0.1, 5.0), "type": "corridor", "priority": 0},
            {"pos": Vector3(0.0, 0.1, 0.0), "type": "central", "priority": 2},
            {"pos": Vector3(0.0, 0.1, -5.0), "type": "corridor", "priority": 0},
            {"pos": Vector3(0.0, 0.1, -10.0), "type": "corridor", "priority": 0},
            {"pos": Vector3(0.0, 0.1, -15.0), "type": "junction", "priority": 1},
            {"pos": Vector3(0.0, 0.1, -20.0), "type": "junction", "priority": 1},
            {"pos": Vector3(0.0, 0.1, -25.0), "type": "corridor", "priority": 0}
        ]
    }

func create_npc_navigator(npc: Node3D) -> NavigationAgent3D:
    # Create and configure NavigationAgent3D for smooth movement
    var agent = NavigationAgent3D.new()
    agent.name = "NavigationAgent3D"
    
    # Configure agent for smooth movement
    agent.path_desired_distance = 0.5
    agent.target_desired_distance = 1.0
    agent.path_max_distance = 1.0
    agent.avoidance_enabled = true
    agent.radius = 0.4
    agent.height = 1.8
    agent.neighbor_distance = 10.0
    agent.max_neighbors = 10
    agent.time_horizon_agents = 2.0
    agent.time_horizon_obstacles = 1.0
    agent.max_speed = 3.5
    agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
    agent.debug_enabled = debug_draw_enabled
    
    npc.add_child(agent)
    
    # Connect velocity computed signal for avoidance
    # Note: velocity_computed signal passes the NPC as self in the callback
    # We don't need to bind the NPC parameter
    
    return agent

func get_room_waypoint(room: String, waypoint_type: String = "") -> Vector3:
    if not waypoint_graph.has(room):
        return Vector3.ZERO
    
    var waypoints = waypoint_graph[room]
    
    # Filter by type if specified
    if waypoint_type != "":
        var filtered = waypoints.filter(func(w): return w.type == waypoint_type)
        if filtered.size() > 0:
            waypoints = filtered
    
    # Get waypoint based on priority and availability
    var best_waypoint = null
    var best_priority = -1
    
    for waypoint in waypoints:
        var pos = waypoint.pos
        var priority = waypoint.priority
        
        # Check if position is occupied
        var occupied = false
        for occupied_pos in occupied_positions:
            if occupied_pos.distance_to(pos) < 2.0:
                occupied = true
                break
        
        if not occupied and priority > best_priority:
            best_waypoint = waypoint
            best_priority = priority
    
    if best_waypoint:
        return best_waypoint.pos
    
    # Fallback to random waypoint if all are occupied
    return waypoints[randi() % waypoints.size()].pos

func get_random_patrol_point(current_room: String) -> Vector3:
    # Get a random patrol point, preferring different rooms occasionally
    if randf() < 0.3:  # 30% chance to patrol to another room
        var rooms = waypoint_graph.keys()
        rooms.erase(current_room)
        if rooms.size() > 0:
            var target_room = rooms[randi() % rooms.size()]
            return get_room_waypoint(target_room)
    
    # Otherwise patrol within current room
    return get_room_waypoint(current_room)

func register_npc_position(npc: Node3D, position: Vector3):
    # Track NPC positions to prevent bunching
    occupied_positions[position] = npc

func unregister_npc_position(position: Vector3):
    occupied_positions.erase(position)

func get_flee_position(npc_pos: Vector3, threat_pos: Vector3) -> Vector3:
    # Calculate optimal flee position away from threat
    var flee_direction = (npc_pos - threat_pos).normalized()
    var flee_distance = 15.0
    var flee_target = npc_pos + flee_direction * flee_distance
    
    # Find nearest valid navigation point
    var map_rid = navigation_region.get_rid() if navigation_region else RID()
    if map_rid.is_valid():
        return NavigationServer3D.map_get_closest_point(map_rid, flee_target)
    
    return flee_target

func get_intercept_position(npc_pos: Vector3, target_pos: Vector3, target_velocity: Vector3) -> Vector3:
    # Calculate intercept position for chasing
    var distance = npc_pos.distance_to(target_pos)
    var intercept_time = distance / 5.0  # Assume NPC speed of 5 units/s
    var intercept_pos = target_pos + target_velocity * intercept_time
    
    # Ensure it's on the navmesh
    var map_rid = navigation_region.get_rid() if navigation_region else RID()
    if map_rid.is_valid():
        return NavigationServer3D.map_get_closest_point(map_rid, intercept_pos)
    
    return intercept_pos

func debug_draw_waypoints():
    # Visual debugging for waypoints
    if not debug_draw_enabled:
        return
    
    for room in waypoint_graph:
        for waypoint in waypoint_graph[room]:
            var pos = waypoint.pos
            var color = Color.WHITE
            
            match waypoint.type:
                "work": color = Color.GREEN
                "storage": color = Color.BLUE
                "entrance": color = Color.YELLOW
                "corner": color = Color.GRAY
                _: color = Color.WHITE
            
            # Draw waypoint marker (you'd implement actual debug drawing here)
            print("Debug waypoint: ", room, " - ", waypoint.type, " at ", pos)
