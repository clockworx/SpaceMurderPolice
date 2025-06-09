extends Node

func _ready():
    # Wait a frame for everything to initialize
    await get_tree().process_frame
    
    print("\n=== NPC DEBUG REPORT ===")
    
    # Check scene structure
    var scene_root = get_tree().current_scene
    print("Scene root: ", scene_root.name)
    
    # Check NPCs parent node
    var npcs_parent = scene_root.get_node_or_null("NPCs")
    if npcs_parent:
        print("\nNPCs parent node found!")
        print("Children count: ", npcs_parent.get_child_count())
        print("Visible: ", npcs_parent.visible)
        print("Position: ", npcs_parent.position)
        
        for child in npcs_parent.get_children():
            print("\n  Child: ", child.name)
            print("    Class: ", child.get_class())
            print("    Visible: ", child.visible)
            print("    Global Position: ", child.global_position)
            if child.has_method("get_property_list"):
                for prop in child.get_property_list():
                    if prop.name == "npc_name":
                        print("    NPC Name: ", child.get("npc_name"))
    else:
        print("ERROR: NPCs parent node NOT FOUND!")
    
    # Check NPCs in group
    print("\n\nNPCs in 'npcs' group:")
    var npcs_in_group = get_tree().get_nodes_in_group("npcs")
    print("Count: ", npcs_in_group.size())
    
    for npc in npcs_in_group:
        print("\n  NPC: ", npc.name)
        print("    Path: ", npc.get_path())
        print("    NPC Name: ", npc.get("npc_name") if npc.has_method("get") else "?")
        print("    Position: ", npc.global_position)
        print("    Visible: ", npc.visible)
        print("    Parent: ", npc.get_parent().name if npc.get_parent() else "None")
        
        # Check if NPC has navigation agent
        var nav_agent = npc.get_node_or_null("NavigationAgent3D")
        if nav_agent:
            print("    Has NavigationAgent3D: true")
            print("    Nav enabled: ", nav_agent.avoidance_enabled)
        else:
            print("    Has NavigationAgent3D: false")
        
        # Check current activity
        if npc.has_method("get"):
            print("    Current activity: ", npc.get("current_activity"))
            print("    Is idle: ", npc.get("is_idle"))
            print("    Current target: ", npc.get("current_target"))
            print("    Velocity: ", npc.velocity if "velocity" in npc else "N/A")
    
    # Check navigation setup
    print("\n\nNavigation Setup:")
    var nav_region = get_tree().get_first_node_in_group("navigation_region")
    if nav_region:
        print("NavigationRegion3D found!")
        print("  Has navigation mesh: ", nav_region.navigation_mesh != null)
    else:
        print("No NavigationRegion3D found!")
    
    print("\n=== END NPC DEBUG ===\n")
