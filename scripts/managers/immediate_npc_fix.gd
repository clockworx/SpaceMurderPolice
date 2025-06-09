extends Node

# This script immediately fixes NPC positions on load

func _ready():
    # Run IMMEDIATELY - don't wait
    _fix_positions()
    
    # Double-check after physics frame
    await get_tree().physics_frame
    _fix_positions()

func _fix_positions():
    print("\n=== IMMEDIATE NPC FIX ===")
    
    # Define CORRECT room positions
    var correct_positions = {
        "Dr. Marcus Webb": Vector3(-8.0, 0.1, 10.0),    # Laboratory 3 (left side)
        "Dr. Sarah Chen": Vector3(8.0, 0.1, 5.0),        # Medical Bay (right side)
        "Jake Torres": Vector3(-8.0, 0.1, -5.0),         # Security Office (left side)
        "Alex Chen": Vector3(8.0, 0.1, -10.0)            # Engineering (right side)
    }
    
    # Fix NPCs parent first
    var npcs_parent = get_tree().current_scene.get_node_or_null("NPCs")
    if npcs_parent:
        for child in npcs_parent.get_children():
            var npc_name = child.get("npc_name") if child.has_method("get") else ""
            if npc_name in correct_positions:
                var correct_pos = correct_positions[npc_name]
                child.position = correct_pos
                child.global_position = correct_pos
                
                # Force update all position properties
                if "initial_position" in child:
                    child.initial_position = correct_pos
                if "current_target" in child:
                    child.current_target = correct_pos
                    
                print("  Fixed ", npc_name, " to ", correct_pos)
    
    # Also fix any in the npcs group
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        if npc_name in correct_positions:
            var correct_pos = correct_positions[npc_name]
            
            # Only fix if position is wrong
            if abs(npc.global_position.x) > 15:
                print("  ERROR: ", npc_name, " at wrong position: ", npc.global_position)
                npc.global_position = correct_pos
                
                # Update all position references
                if "initial_position" in npc:
                    npc.initial_position = correct_pos
                if "current_target" in npc:
                    npc.current_target = correct_pos
                    
                # Stop any movement
                if "velocity" in npc:
                    npc.velocity = Vector3.ZERO
                if "is_idle" in npc:
                    npc.is_idle = true
                    
                print("    Moved to: ", correct_pos)
    
    print("=== IMMEDIATE FIX COMPLETE ===\n")