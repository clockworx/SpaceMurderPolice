@tool
extends EditorScript

func _run():
    print("=== Enable Saboteur Behavior on All NPCs ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    # Load the saboteur AI script
    var saboteur_script = load("res://scripts/npcs/saboteur_patrol_ai.gd")
    if not saboteur_script:
        print("ERROR: Could not load saboteur_patrol_ai.gd!")
        return
    
    print("\nAdding saboteur behavior to NPCs:")
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Check if already has saboteur AI
            var has_saboteur = false
            for child in npc.get_children():
                if child.name == "SaboteurPatrolAI":
                    has_saboteur = true
                    # Make sure it's active
                    child.set("is_active", true)
                    child.set_physics_process(true)
                    print("- ", npc.name, ": Already has SaboteurPatrolAI (activated)")
                    break
            
            if not has_saboteur:
                # Add saboteur AI
                var saboteur_ai = Node.new()
                saboteur_ai.name = "SaboteurPatrolAI"
                saboteur_ai.set_script(saboteur_script)
                
                npc.add_child(saboteur_ai)
                saboteur_ai.owner = edited_scene
                
                # Configure it
                saboteur_ai.set("is_active", true)
                saboteur_ai.set("patrol_speed", 3.0)
                saboteur_ai.set("detection_range", 10.0)
                
                print("- ", npc.name, ": Added SaboteurPatrolAI")
            
            # Enable saboteur behavior on the NPC itself
            if "enable_saboteur_behavior" in npc:
                npc.set("enable_saboteur_behavior", true)
            if "can_be_saboteur" in npc:
                npc.set("can_be_saboteur", true)
            
            # Disable parent physics processing to avoid conflicts
            npc.set_physics_process(false)
    
    print("\n✓ Saboteur behavior enabled on all NPCs!")
    print("\nWhat this does:")
    print("- Adds SaboteurPatrolAI to NPCs that don't have it")
    print("- Activates the AI and enables physics processing")
    print("- Disables parent physics to avoid conflicts")
    print("\nAll NPCs will now patrol like the Engineer does!")
