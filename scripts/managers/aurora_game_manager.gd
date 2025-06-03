extends Node

func _ready():
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Find player and UI nodes
	var player = get_node_or_null("../Player")
	var player_ui = player.get_node_or_null("UILayer/PlayerUI") if player else null
	
	if not player:
		push_error("Game Manager: Player node not found!")
		return
		
	if not player_ui:
		push_error("Game Manager: PlayerUI node not found!")
		return
	
	# Connect interaction signals
	if player.has_signal("interactable_detected") and player.has_signal("interactable_lost"):
		player.interactable_detected.connect(_on_interactable_detected.bind(player_ui))
		player.interactable_lost.connect(_on_interactable_lost.bind(player_ui))
		print("Game Manager: Connected player interaction signals")
	else:
		push_error("Game Manager: Player missing interaction signals!")

func _on_interactable_detected(interactable, ui):
	print("Interactable detected: ", interactable)
	if interactable.has_method("interact"):
		var prompt = interactable.get_interaction_prompt() if interactable.has_method("get_interaction_prompt") else "Press [E] to interact"
		print("Showing prompt: ", prompt)
		ui.show_interaction_prompt(prompt)

func _on_interactable_lost(ui):
	print("Interactable lost")
	ui.hide_interaction_prompt()