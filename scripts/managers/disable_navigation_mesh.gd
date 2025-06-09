extends Node

# This script completely disables NavigationRegion3D to stop the errors

func _ready():
    print("\n=== DISABLING NAVIGATION MESH ===")
    
    # Find and disable ALL NavigationRegion3D nodes
    var disabled_count = 0
    var all_nav_regions = []
    _find_all_nav_regions(get_tree().root, all_nav_regions)
    
    for nav_region in all_nav_regions:
        print("Disabling NavigationRegion3D at: ", nav_region.get_path())
        nav_region.enabled = false
        nav_region.set_process(false)
        nav_region.set_physics_process(false)
        
        # Clear the navigation mesh to prevent errors
        if nav_region.navigation_mesh:
            nav_region.navigation_mesh = null
        
        disabled_count += 1
    
    print("Disabled ", disabled_count, " NavigationRegion3D nodes")
    
    # Force all NPCs to use simple movement
    await get_tree().process_frame
    
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("\nForcing ", npcs.size(), " NPCs to use simple movement:")
    
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        
        # Disable navigation
        if "is_navigating" in npc:
            npc.is_navigating = false
            
        # Disable NavigationAgent3D completely
        var nav_agent = npc.get_node_or_null("NavigationAgent3D") 
        if not nav_agent:
            # Try to find it as child
            for child in npc.get_children():
                if child is NavigationAgent3D:
                    nav_agent = child
                    break
                    
        if nav_agent:
            # NavigationAgent3D doesn't have 'enabled' property - just disable processing
            nav_agent.set_process(false)
            nav_agent.set_physics_process(false)
            nav_agent.avoidance_enabled = false
            # Set target to current position to stop movement
            nav_agent.target_position = npc.global_position
            print("  Disabled NavigationAgent3D for ", npc_name)
        
        # Clear navigation agent reference
        if "navigation_agent" in npc:
            npc.navigation_agent = null
            
        print("  ", npc_name, " will use simple movement only")
    
    print("\n=== NAVIGATION MESH DISABLED ===")
    print("NPCs will use simple random movement within their areas\n")

func _find_all_nav_regions(node: Node, result: Array):
    if node is NavigationRegion3D:
        result.append(node)
    for child in node.get_children():
        _find_all_nav_regions(child, result)
