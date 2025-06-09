extends Node

# This script fixes NPC positions that are outside the station bounds
# Station rooms are roughly between X=-15 and X=15

func _ready():
    print("\n=== FIXING NPC POSITIONS ===")
    
    # Wait for NPCs to be initialized
    await get_tree().process_frame
    
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    # Define correct room positions
    var correct_positions = {
        "Dr. Marcus Webb": Vector3(-8.0, 0.1, 10.0),    # Laboratory 3
        "Dr. Sarah Chen": Vector3(8.0, 0.1, 5.0),        # Medical Bay  
        "Jake Torres": Vector3(-8.0, 0.1, -5.0),         # Security Office
        "Alex Chen": Vector3(8.0, 0.1, -10.0)            # Engineering
    }
    
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        var current_pos = npc.global_position
        
        # Check if position is way outside station bounds
        if abs(current_pos.x) > 20:
            print("ERROR: ", npc_name, " is way outside station at X=", current_pos.x)
            
            # Move to correct position
            if npc_name in correct_positions:
                var new_pos = correct_positions[npc_name]
                print("  Moving ", npc_name, " to correct room position: ", new_pos)
                npc.global_position = new_pos
                
                # Update internal position tracking
                if "initial_position" in npc:
                    npc.initial_position = new_pos
                if "current_target" in npc:
                    npc.current_target = new_pos
            else:
                # Default to hallway center
                var new_pos = Vector3(0, 0.1, 0)
                print("  Moving ", npc_name, " to hallway center: ", new_pos)
                npc.global_position = new_pos
        else:
            print(npc_name, " is in acceptable position at: ", current_pos)
    
    print("=== NPC POSITION FIX COMPLETE ===\n")