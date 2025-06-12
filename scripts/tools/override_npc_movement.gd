@tool
extends EditorScript

func _run():
    print("=== Override NPC Movement to Long Distance ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    # Find NPCs
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    print("\nOverriding NPC movement settings:")
    
    # Give each NPC a different large movement pattern
    var npc_positions = {
        "MedicalOfficer": [Vector3(40, 0.5, 0), Vector3(30, 0.5, 30), Vector3(0, 0.5, 20)],
        "ChiefScientist": [Vector3(-30, 0.5, -30), Vector3(0, 0.5, -20), Vector3(30, 0.5, -30)],
        "Engineer": [Vector3(-40, 0.5, 0), Vector3(-30, 0.5, -30), Vector3(-30, 0.5, 30)],
        "SecurityChief": [Vector3(0, 0.5, 0), Vector3(20, 0.5, 20), Vector3(-20, 0.5, -20)],
        "AISpecialist": [Vector3(30, 0.5, 0), Vector3(30, 0.5, -20), Vector3(10, 0.5, -30)],
        "SecurityOfficer": [Vector3(-20, 0.5, 20), Vector3(20, 0.5, -20), Vector3(0, 0.5, 0)]
    }
    
    var index = 0
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Set large wander radius to force movement
            if "wander_radius" in npc:
                npc.set("wander_radius", 30.0)  # Very large radius
                print("  - ", npc.name, ": Set wander_radius to 30.0")
            
            # Set to wandering state
            if "current_state" in npc:
                npc.set("current_state", 1)  # WANDERING state
            
            # Move to a starting position
            if npc.name in npc_positions:
                var positions = npc_positions[npc.name]
                npc.position = positions[0]
                npc.position.y = 0.5
                print("  - ", npc.name, ": Moved to starting position ", positions[0])
            
            index += 1
    
    print("\n✓ Movement overrides applied!")
    print("\nNPCs now have:")
    print("- Very large wander radius (30 units)")
    print("- Different starting positions")
    print("- Should move much larger distances")
    print("\nThis forces them to move across the station instead of tiny movements.")
