@tool
extends EditorScript

# This script adds SaboteurCharacterModes and SaboteurPatrolAI to saboteur NPCs
# Run this in the Godot editor with the aurora_station scene open

func _run():
    var edited_scene = get_scene()
    if not edited_scene:
        print("No scene open")
        return
    
    # Find saboteur NPC
    var saboteur = edited_scene.get_node_or_null("NPCs/EngineerNPC")
    if not saboteur:
        print("Saboteur NPC (EngineerNPC) not found")
        return
    
    print("Found saboteur NPC at: ", saboteur.get_path())
    
    # Check if SaboteurPatrolAI already exists
    var patrol_ai = saboteur.get_node_or_null("SaboteurPatrolAI")
    if not patrol_ai:
        # Add SaboteurPatrolAI
        patrol_ai = Node.new()
        patrol_ai.name = "SaboteurPatrolAI"
        patrol_ai.set_script(load("res://scripts/npcs/saboteur_patrol_ai.gd"))
        saboteur.add_child(patrol_ai)
        patrol_ai.owner = edited_scene
        print("Added SaboteurPatrolAI")
    else:
        print("SaboteurPatrolAI already exists")
    
    # Check if SaboteurCharacterModes already exists
    var character_modes = saboteur.get_node_or_null("SaboteurCharacterModes")
    if not character_modes:
        # Add SaboteurCharacterModes
        character_modes = Node.new()
        character_modes.name = "SaboteurCharacterModes"
        character_modes.set_script(load("res://scripts/npcs/saboteur_character_modes.gd"))
        saboteur.add_child(character_modes)
        character_modes.owner = edited_scene
        print("Added SaboteurCharacterModes")
    else:
        print("SaboteurCharacterModes already exists")
    
    # Mark NPC as can_be_saboteur
    saboteur.can_be_saboteur = true
    
    print("Saboteur NPC setup complete!")