@tool
extends EditorScript

func _run():
    print("=== Activate Saboteur AI ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    print("\nActivating saboteur AI where available:")
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Look for SaboteurPatrolAI
            for child in npc.get_children():
                if child.name == "SaboteurPatrolAI":
                    print("\n- Found SaboteurPatrolAI on ", npc.name)
                    
                    # Activate it
                    child.set("is_active", true)
                    child.set_physics_process(true)
                    
                    # Call set_active if available
                    if child.has_method("set_active"):
                        child.call("set_active", true)
                    
                    # Disable parent physics processing to avoid conflicts
                    npc.set_physics_process(false)
                    
                    print("  ✓ Activated saboteur AI")
                    print("  ✓ Disabled parent physics processing")
                    
                    break
    
    print("\n✓ Saboteur AI activation complete!")
    print("\nNote: Only the Engineer has saboteur AI by default.")
    print("The saboteur AI directly controls movement and works properly.")