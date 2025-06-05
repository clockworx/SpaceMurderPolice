extends Control
class_name PlayerUI

@onready var evidence_ui = $EvidenceUI
@onready var case_file_ui = $CaseFileUI
@onready var oxygen_time_label = $LifeSupportPanel/VBoxContainer/OxygenTime
@onready var status_label = $LifeSupportPanel/VBoxContainer/StatusLabel
@onready var life_support_panel = $LifeSupportPanel
@onready var interaction_prompt = $InteractionPrompt
@onready var interaction_label = $InteractionPrompt/Label

var life_support_manager: LifeSupportManager

func _ready():
	# Find life support manager
	life_support_manager = get_tree().get_first_node_in_group("life_support_manager")
	if life_support_manager:
		life_support_manager.life_support_warning.connect(_on_life_support_warning)
		life_support_manager.life_support_critical.connect(_on_life_support_critical)
		life_support_manager.emergency_power_activated.connect(_on_emergency_power)
	else:
		# Hide life support panel if no manager
		life_support_panel.visible = false

func _process(delta):
	# Update life support display
	if life_support_manager:
		oxygen_time_label.text = life_support_manager.get_remaining_time_formatted()
		
		# Update colors based on remaining time
		var minutes_remaining = life_support_manager.get_remaining_time_minutes()
		if minutes_remaining <= 2.0:
			oxygen_time_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))  # Critical red
			status_label.text = "CRITICAL"
			status_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		elif minutes_remaining <= 5.0:
			oxygen_time_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))  # Warning orange
			status_label.text = "WARNING"
			status_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
		elif minutes_remaining <= 15.0:
			oxygen_time_label.add_theme_color_override("font_color", Color(1, 1, 0.2))  # Caution yellow
			status_label.text = "CAUTION"
			status_label.add_theme_color_override("font_color", Color(1, 1, 0.2))
		elif not life_support_manager.is_life_support_active:
			oxygen_time_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))  # Normal blue
			status_label.text = "BACKUP POWER"
			status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
		else:
			oxygen_time_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))  # Good green
			status_label.text = "OPERATIONAL"
			status_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))

func _input(event):
	if event.is_action_pressed("toggle_evidence"):
		if evidence_ui:
			evidence_ui.toggle_visibility()
	
	if event.is_action_pressed("toggle_case_file"):
		if case_file_ui:
			case_file_ui.show_case_file()

func _on_life_support_warning(minutes_remaining: float):
	print("Life support warning: ", minutes_remaining, " minutes remaining")

func _on_life_support_critical(minutes_remaining: float):
	print("CRITICAL life support warning: ", minutes_remaining, " minutes remaining")

func _on_emergency_power():
	print("Emergency power activated")

func show_interaction_prompt(prompt_text: String = "Press [E] to interact"):
	if interaction_label:
		interaction_label.text = prompt_text
	if interaction_prompt:
		interaction_prompt.visible = true

func hide_interaction_prompt():
	if interaction_prompt:
		interaction_prompt.visible = false