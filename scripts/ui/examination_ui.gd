extends Control
class_name ExaminationUI

@onready var victim_name_label = $ExaminationPanel/VBoxContainer/VictimName
@onready var status_label = $ExaminationPanel/VBoxContainer/StatusLabel
@onready var progress_label = $ExaminationPanel/VBoxContainer/ProgressContainer/ProgressLabel
@onready var progress_bar = $ExaminationPanel/VBoxContainer/ProgressContainer/ProgressBar
@onready var findings_list = $ExaminationPanel/VBoxContainer/FindingsArea/FindingsList
@onready var cancel_button = $ExaminationPanel/VBoxContainer/ButtonContainer/CancelButton
@onready var complete_button = $ExaminationPanel/VBoxContainer/ButtonContainer/CompleteButton

var examination_data: Dictionary = {}
var examination_duration: float = 3.0
var examination_timer: float = 0.0
var is_examining: bool = false
var findings_revealed: int = 0

signal examination_finished()

func _ready():
	cancel_button.pressed.connect(_cancel_examination)
	complete_button.pressed.connect(_complete_examination)
	
	# Register with UI manager
	var ui_manager = UIManager.get_instance()
	if ui_manager:
		ui_manager.register_ui_screen(self)

func start_examination(data: Dictionary, duration: float):
	examination_data = data
	examination_duration = duration
	
	victim_name_label.text = "Subject: " + data.get("victim_name", "Unknown")
	progress_bar.value = 0
	findings_revealed = 0
	
	is_examining = true
	_update_status("Beginning examination...")

func _process(delta):
	if not is_examining:
		return
	
	examination_timer += delta
	var progress = examination_timer / examination_duration
	progress = clamp(progress, 0.0, 1.0)
	
	progress_bar.value = progress * 100
	progress_label.text = "Progress: " + str(int(progress * 100)) + "%"
	
	# Reveal findings progressively
	_reveal_findings_progressively(progress)
	
	# Check if examination is complete
	if progress >= 1.0:
		_examination_complete()

func _reveal_findings_progressively(progress: float):
	var initial_observations = examination_data.get("initial_observations", [])
	var detailed_findings = examination_data.get("detailed_findings", [])
	
	var total_findings = initial_observations.size() + detailed_findings.size()
	var findings_to_show = int(progress * total_findings)
	
	# Add new findings as they're revealed
	while findings_revealed < findings_to_show:
		if findings_revealed < initial_observations.size():
			# Show initial observations first
			_add_finding("Initial Observation", initial_observations[findings_revealed], Color(0.8, 0.8, 1))
			_update_status("Conducting visual examination...")
		else:
			# Then show detailed findings
			var detailed_index = findings_revealed - initial_observations.size()
			if detailed_index < detailed_findings.size():
				_add_finding("Medical Finding", detailed_findings[detailed_index], Color(1, 0.8, 0.8))
				_update_status("Analyzing detailed findings...")
		
		findings_revealed += 1

func _add_finding(category: String, text: String, color: Color):
	var container = VBoxContainer.new()
	
	# Category label
	var category_label = Label.new()
	category_label.text = "• " + category + ":"
	category_label.add_theme_color_override("font_color", color)
	category_label.add_theme_font_size_override("font_size", 14)
	container.add_child(category_label)
	
	# Finding text
	var finding_label = Label.new()
	finding_label.text = "  " + text
	finding_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	finding_label.add_theme_font_size_override("font_size", 13)
	finding_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(finding_label)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	container.add_child(spacer)
	
	findings_list.add_child(container)

func _update_status(text: String):
	status_label.text = text

func _examination_complete():
	is_examining = false
	complete_button.disabled = false
	_update_status("Examination complete. Review findings and conclude.")
	
	# Show conclusions
	var conclusions = examination_data.get("conclusions", [])
	if conclusions.size() > 0:
		_add_finding("Conclusion", "Analysis complete:", Color(0.8, 1, 0.8))
		for conclusion in conclusions:
			_add_finding("", conclusion, Color(0.8, 1, 0.8))

func _complete_examination():
	_close_examination()
	examination_finished.emit()

func _cancel_examination():
	_close_examination()

func _close_examination():
	# Unregister with UI manager
	var ui_manager = UIManager.get_instance()
	if ui_manager:
		ui_manager.unregister_ui_screen(self)
	
	queue_free()

func close_ui():
	_close_examination()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_cancel_examination()