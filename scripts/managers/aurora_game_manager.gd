extends Node

func _ready():
    add_to_group("game_manager")
    
    print("\n=== AURORA GAME MANAGER STARTING ===")
    print("Scene root: ", get_tree().current_scene.name)
    
    # Connect player interaction signals if needed
    var player = get_tree().get_first_node_in_group("player")
    var player_ui = get_tree().get_first_node_in_group("player_ui")
    
    if player and player_ui:
        if player.has_signal("interactable_detected"):
            player.interactable_detected.connect(_on_interactable_detected.bind(player_ui))
        if player.has_signal("interactable_lost"):
            player.interactable_lost.connect(_on_interactable_lost.bind(player_ui))

func _on_interactable_detected(interactable, ui):
    if interactable.has_method("interact"):
        var prompt = interactable.get_interaction_prompt() if interactable.has_method("get_interaction_prompt") else "Press [E] to interact"
        ui.show_interaction_prompt(prompt)

func _on_interactable_lost(ui):
    ui.hide_interaction_prompt()
