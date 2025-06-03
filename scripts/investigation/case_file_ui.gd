extends Control

@onready var interaction_prompt = $InteractionPrompt
@onready var interaction_label = $InteractionPrompt/Label

func show_interaction_prompt(prompt_text: String = "Press [E] to interact"):
	interaction_label.text = prompt_text
	interaction_prompt.visible = true

func hide_interaction_prompt():
	interaction_prompt.visible = false