@tool
extends EditorScript

# Properly set up collision layers for detection to work

func _run():
    print("=== SETTING UP COLLISION LAYERS ===")
    
    var scene = get_scene()
    if not scene:
        print("ERROR: No scene open")
        return
    
    # Find and setup player
    var player = _find_player(scene)
    if player:
        print("\nPlayer: ", player.name)
        print("  Current collision_layer: ", player.collision_layer)
        player.collision_layer = 2  # Put player on layer 2
        player.collision_mask = 1   # Player collides with environment (layer 1)
        print("  ✓ Set to layer 2, mask 1")
        
        # Ensure player is in the player group
        if not player.is_in_group("player"):
            player.add_to_group("player")
            print("  ✓ Added to 'player' group")
    else:
        print("ERROR: No player found!")
    
    # Find and setup NPCs
    var npcs = []
    _find_npcs(scene, npcs)
    
    print("\nUpdating ", npcs.size(), " NPCs...")
    
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        print("\n", npc_name)
        print("  Current collision_layer: ", npc.collision_layer)
        
        # NPCs should be on layer 3, collide with environment
        npc.collision_layer = 4  # Layer 3 (bitmask 4)
        npc.collision_mask = 1   # Collide with environment
        print("  ✓ Set to layer 3, mask 1")
    
    # Find and update environment/station
    var station = scene.get_node_or_null("Station")
    if station:
        print("\nStation:")
        print("  Current collision_layer: ", station.collision_layer)
        station.collision_layer = 1  # Environment on layer 1
        station.collision_mask = 0   # Environment doesn't need to detect anything
        print("  ✓ Set to layer 1, mask 0")
    
    print("\n=== COLLISION LAYER SUMMARY ===")
    print("Layer 1 (value 1): Environment/Station - What players and NPCs walk on")
    print("Layer 2 (value 2): Player - What NPC detection raycasts look for")
    print("Layer 3 (value 4): NPCs - Separate from player to avoid detection issues")
    print("")
    print("✓ Player is on layer 2 (detected by NPCs)")
    print("✓ NPCs are on layer 3 (not detected by their own raycasts)")
    print("✓ Environment is on layer 1 (provides collision)")
    print("")
    print("NPC raycasts check ONLY layer 2, so they will:")
    print("- Detect the player ✓")
    print("- Ignore environment ✓")
    print("- Ignore other NPCs ✓")
    print("")
    print("IMPORTANT: Save the scene to keep these changes!")

func _find_player(node: Node) -> Node:
    # Look for player by group first
    if node.is_in_group("player"):
        return node
    
    # Then by name
    if node is CharacterBody3D and "player" in node.name.to_lower():
        return node
    
    for child in node.get_children():
        var result = _find_player(child)
        if result:
            return result
    
    return null

func _find_npcs(node: Node, result: Array):
    if node is CharacterBody3D and node.has_method("get") and node.get("npc_name"):
        result.append(node)
    
    for child in node.get_children():
        _find_npcs(child, result)
