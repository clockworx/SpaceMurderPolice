@tool
extends EditorScript

# This script adds RileyCharacterModes and RileyPatrolAI to Riley Kim NPC
# Run this in the Godot editor with the aurora_station scene open

func _run():
    var edited_scene = get_scene()
    if not edited_scene:
        print("No scene open")
        return
    
    # Find Riley Kim NPC
    var riley = edited_scene.get_node_or_null("NPCs/EngineerNPC")
    if not riley:
        print("Riley Kim (EngineerNPC) not found")
        return
    
    print("Found Riley Kim at: ", riley.get_path())
    
    # Check if RileyPatrolAI already exists
    var patrol_ai = riley.get_node_or_null("RileyPatrolAI")
    if not patrol_ai:
        # Add RileyPatrolAI
        patrol_ai = Node.new()
        patrol_ai.name = "RileyPatrolAI"
        patrol_ai.set_script(load("res://scripts/npcs/riley_patrol_ai.gd"))
        riley.add_child(patrol_ai)
        patrol_ai.owner = edited_scene
        print("Added RileyPatrolAI")
    else:
        print("RileyPatrolAI already exists")
    
    # Check if RileyCharacterModes already exists
    var character_modes = riley.get_node_or_null("RileyCharacterModes")
    if not character_modes:
        # Add RileyCharacterModes
        character_modes = Node.new()
        character_modes.name = "RileyCharacterModes"
        character_modes.set_script(load("res://scripts/npcs/riley_character_modes.gd"))
        riley.add_child(character_modes)
        character_modes.owner = edited_scene
        print("Added RileyCharacterModes")
    else:
        print("RileyCharacterModes already exists")
    
    # Mark Riley as can_be_saboteur
    riley.can_be_saboteur = true
    
    print("Riley Kim setup complete!")