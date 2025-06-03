extends Node

func _ready():
	var player = get_node_or_null("Player")
	var player_ui = get_node_or_null("PlayerUI")
	
	if player and player_ui:
		player.interactable_detected.connect(_on_interactable_detected.bind(player_ui))
		player.interactable_lost.connect(_on_interactable_lost.bind(player_ui))

func _on_interactable_detected(interactable, ui):
	if interactable.has_method("interact"):
		var prompt = interactable.get_interaction_prompt() if interactable.has_method("get_interaction_prompt") else "Press [E] to interact"
		ui.show_interaction_prompt(prompt)

func _on_interactable_lost(ui):
	ui.hide_interaction_prompt()