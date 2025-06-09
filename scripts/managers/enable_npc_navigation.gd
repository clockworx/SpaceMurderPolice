extends Node

# This script enables proper NavigationAgent3D usage for NPCs

func _ready():
    print("\n=== ENABLING NPC NAVIGATION ===")
    
    # Wait for navigation to be ready
    await get_tree().physics_frame
    await get_tree().physics_frame
    
    # Check if NavigationRegion3D exists
    var nav_region = get_tree().get_first_node_in_group("navigation_region")
    if not nav_region:
        # Try to find it by type
        var nodes = get_tree().get_nodes_in_group("navigation_region")
        if nodes.is_empty():
            # Search for NavigationRegion3D in the scene
            var root = get_tree().current_scene
            nav_region = _find_navigation_region(root)
            
    if nav_region:
        print("Found NavigationRegion3D: ", nav_region.get_path())
        if nav_region.navigation_mesh:
            print("  Navigation mesh is configured")
        else:
            print("  WARNING: No navigation mesh found! NPCs won't navigate properly.")
            print("  To fix: Select the NavigationRegion3D and bake a navigation mesh")
    else:
        print("ERROR: No NavigationRegion3D found in scene!")
        print("  NPCs will use simple movement instead of navigation")
    
    # Configure NPCs to use navigation
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("\nConfiguring ", npcs.size(), " NPCs for navigation:")
    
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        
        # Check if NPC has NavigationAgent3D
        var nav_agent = npc.get_node_or_null("NavigationAgent3D")
        if not nav_agent:
            # Create one if missing
            nav_agent = NavigationAgent3D.new()
            nav_agent.name = "NavigationAgent3D"
            npc.add_child(nav_agent)
            print("  Added NavigationAgent3D to ", npc_name)
        else:
            print("  ", npc_name, " already has NavigationAgent3D")
        
        # Configure the navigation agent
        nav_agent.radius = 0.5
        nav_agent.height = 1.8
        nav_agent.max_neighbors = 10
        nav_agent.time_horizon_agents = 2.0
        nav_agent.time_horizon_obstacles = 1.0
        nav_agent.max_speed = 2.0
        nav_agent.path_desired_distance = 0.5
        nav_agent.target_desired_distance = 1.0
        nav_agent.path_max_distance = 3.0
        nav_agent.navigation_layers = 1
        nav_agent.avoidance_enabled = true
        
        # Store reference in NPC
        if "navigation_agent" in npc:
            npc.navigation_agent = nav_agent
            
        # Enable navigation in NPC
        if "is_navigating" in npc:
            npc.is_navigating = true
            
        print("    Configured navigation for ", npc_name)
    
    print("=== NPC NAVIGATION ENABLED ===\n")

func _find_navigation_region(node: Node) -> NavigationRegion3D:
    if node is NavigationRegion3D:
        return node
    for child in node.get_children():
        var result = _find_navigation_region(child)
        if result:
            return result
    return null