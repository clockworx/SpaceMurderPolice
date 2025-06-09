extends Node

# This script provides simple movement for NPCs when navigation fails

func _ready():
    print("\n=== SIMPLE NPC MOVEMENT ===")
    
    # Wait for NPCs to initialize
    await get_tree().create_timer(0.5).timeout
    
    # Check if navigation is working
    var nav_region = get_tree().get_first_node_in_group("navigation_region")
    var use_simple_movement = false
    
    if not nav_region:
        print("No NavigationRegion3D found - using simple movement")
        use_simple_movement = true
    elif not nav_region.navigation_mesh:
        print("NavigationRegion3D has no mesh - using simple movement")  
        use_simple_movement = true
    else:
        print("NavigationRegion3D found - NPCs should use navigation")
    
    if use_simple_movement:
        # Disable navigation for all NPCs
        var npcs = get_tree().get_nodes_in_group("npcs")
        for npc in npcs:
            if "is_navigating" in npc:
                npc.is_navigating = false
            
            # Disable NavigationAgent3D
            var nav_agent = npc.get_node_or_null("NavigationAgent3D")
            if nav_agent:
                nav_agent.set_process(false)
                nav_agent.set_physics_process(false)
                
            print("  ", npc.get("npc_name"), " will use simple movement")
    
    print("=== SIMPLE MOVEMENT SETUP COMPLETE ===\n")