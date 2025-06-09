extends Node

# This script automatically adds SaboteurCharacterModes to saboteur NPCs when the game starts
# Add this as an autoload or attach it to a manager node

func _ready():
    # Wait for the scene to be fully loaded
    await get_tree().create_timer(1.0).timeout
    setup_riley_character_modes()

func setup_riley_character_modes():
    print("Saboteur Setup: Looking for saboteur NPCs...")
    
    # Find all NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    var saboteur = null
    
    for npc in npcs:
        if npc.has("can_be_saboteur") and npc.can_be_saboteur:
            saboteur = npc
            break
    
    if not saboteur:
        print("Saboteur Setup: No saboteur NPC found!")
        return
    
    print("Saboteur Setup: Found saboteur at ", saboteur.get_path())
    
    # Check if SaboteurCharacterModes already exists
    var character_modes = saboteur.get_node_or_null("SaboteurCharacterModes")
    if character_modes:
        print("Saboteur Setup: SaboteurCharacterModes already exists")
        return
    
    # Create and add SaboteurCharacterModes
    character_modes = Node.new()
    character_modes.name = "SaboteurCharacterModes"
    character_modes.set_script(load("res://scripts/npcs/saboteur_character_modes.gd"))
    saboteur.add_child(character_modes)
    
    print("Saboteur Setup: Added SaboteurCharacterModes to saboteur NPC")
    
    # Ensure NPC is marked as saboteur
    saboteur.can_be_saboteur = true
    
    print("Saboteur Setup: Setup complete!")