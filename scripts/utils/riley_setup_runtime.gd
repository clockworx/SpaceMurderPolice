extends Node

# This script automatically adds RileyCharacterModes to Riley when the game starts
# Add this as an autoload or attach it to a manager node

func _ready():
    # Wait for the scene to be fully loaded
    await get_tree().create_timer(1.0).timeout
    setup_riley_character_modes()

func setup_riley_character_modes():
    print("Riley Setup: Looking for Riley Kim...")
    
    # Find all NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    var riley = null
    
    for npc in npcs:
        if npc.npc_name == "Riley Kim":
            riley = npc
            break
    
    if not riley:
        print("Riley Setup: Riley Kim not found!")
        return
    
    print("Riley Setup: Found Riley at ", riley.get_path())
    
    # Check if RileyCharacterModes already exists
    var character_modes = riley.get_node_or_null("RileyCharacterModes")
    if character_modes:
        print("Riley Setup: RileyCharacterModes already exists")
        return
    
    # Create and add RileyCharacterModes
    character_modes = Node.new()
    character_modes.name = "RileyCharacterModes"
    character_modes.set_script(load("res://scripts/npcs/riley_character_modes.gd"))
    riley.add_child(character_modes)
    
    print("Riley Setup: Added RileyCharacterModes to Riley Kim")
    
    # Set Riley as can_be_saboteur
    riley.can_be_saboteur = true
    
    print("Riley Setup: Setup complete!")