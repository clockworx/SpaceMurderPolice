extends Node

# This script ensures NPCs stay exactly where they were placed in the scene
func _ready():
    print("\n=== DISABLE NPC REPOSITIONING ===")
    
    # Wait for scene to load
    await get_tree().process_frame
    
    # Capture initial positions of all NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    var initial_positions = {}
    
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        initial_positions[npc] = npc.global_position
        print("Captured initial position for ", npc_name, ": ", npc.global_position)
    
    # Wait another frame
    await get_tree().process_frame
    
    # Restore positions if they changed
    for npc in npcs:
        if not is_instance_valid(npc):
            continue
            
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        var initial_pos = initial_positions.get(npc, Vector3.ZERO)
        
        if npc.global_position.distance_to(initial_pos) > 0.1:
            print("WARNING: ", npc_name, " was moved! Restoring position.")
            print("  Was at: ", npc.global_position)
            print("  Restoring to: ", initial_pos)
            npc.global_position = initial_pos
            
            # Also update internal position tracking
            if "initial_position" in npc:
                npc.initial_position = initial_pos
            if "current_target" in npc:
                npc.current_target = initial_pos
    
    print("=== NPC REPOSITIONING DISABLED ===\n")