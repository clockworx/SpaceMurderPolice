extends Node

func _ready():
    # Wait for scene to fully load
    await get_tree().process_frame
    await get_tree().create_timer(0.5).timeout
    
    print("\n=== COMPREHENSIVE NPC FIX ===")
    
    var scene_root = get_tree().current_scene
    var npcs_parent = scene_root.get_node_or_null("NPCs")
    
    # First, ensure NPCs parent is visible
    if npcs_parent:
        npcs_parent.visible = true
        print("NPCs parent found and set visible")
        
        # Make sure all children are visible
        for child in npcs_parent.get_children():
            child.visible = true
            _ensure_npc_setup(child)
    
    # Also check nodes in npcs group
    var npcs_in_group = get_tree().get_nodes_in_group("npcs")
    print("Found ", npcs_in_group.size(), " NPCs in group")
    
    # Define proper room positions
    var room_positions = {
        "Dr. Marcus Webb": Vector3(-8, 0.1, 10),      # Laboratory 3
        "Dr. Sarah Chen": Vector3(8, 0.1, 5),         # Medical Bay
        "Jake Torres": Vector3(-8, 0.1, -3),          # Security Office
        "Alex Chen": Vector3(8, 0.1, -10)             # Engineering
    }
    
    for npc in npcs_in_group:
        if not npc.visible:
            print("Making ", npc.name, " visible")
            npc.visible = true
            
        # Check if NPC has valid position
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        
        # DISABLED: User has manually positioned NPCs
        # Just log current position
        print("NPC ", npc_name, " is at: ", npc.global_position)
                
        _ensure_npc_setup(npc)
        
    print("=== NPC FIX COMPLETE ===\n")

func _ensure_npc_setup(npc):
    # Ensure all visual components are visible
    var mesh = npc.get_node_or_null("MeshInstance3D")
    if mesh:
        mesh.visible = true
        
    var head = npc.get_node_or_null("Head")
    if head:
        head.visible = true
        for child in head.get_children():
            child.visible = true
            
    # Ensure NPC is on ground
    if npc.global_position.y < 0 or npc.global_position.y > 2:
        npc.global_position.y = 0.1
        
    # Ensure NPC has reasonable walk speed
    if "walk_speed" in npc:
        if npc.walk_speed <= 0:
            npc.walk_speed = 2.0
            
    # Force idle state to trigger movement
    if "is_idle" in npc:
        npc.is_idle = true
    if "idle_timer" in npc:
        npc.idle_timer = 0.5