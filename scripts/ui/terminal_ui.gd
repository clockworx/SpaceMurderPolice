extends Control
class_name TerminalUI

@onready var terminal_name_label = $TerminalPanel/VBoxContainer/TerminalName
@onready var content_tabs = $TerminalPanel/VBoxContainer/ContentArea
@onready var logs_list = $TerminalPanel/VBoxContainer/ContentArea/SystemLogs/LogsList
@onready var files_list = $TerminalPanel/VBoxContainer/ContentArea/Files/FilesList
@onready var close_button = $TerminalPanel/VBoxContainer/ButtonContainer/CloseButton

var terminal_data: Dictionary = {}

func _ready():
	close_button.pressed.connect(_close_terminal)
	
	# Register with UI manager for proper mouse handling
	var ui_manager = UIManager.get_instance()
	if ui_manager:
		ui_manager.register_ui_screen(self)

func setup_terminal(data: Dictionary):
	terminal_data = data
	terminal_name_label.text = data.get("name", "Unknown Terminal")
	
	_populate_logs()
	_populate_files()

func _populate_logs():
	# Clear existing logs
	for child in logs_list.get_children():
		child.queue_free()
	
	var logs = terminal_data.get("logs", [])
	
	if logs.size() == 0:
		var no_logs = Label.new()
		no_logs.text = "No log entries found."
		no_logs.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		logs_list.add_child(no_logs)
		return
	
	for log in logs:
		var log_container = _create_log_entry(log)
		logs_list.add_child(log_container)

func _populate_files():
	# Clear existing files
	for child in files_list.get_children():
		child.queue_free()
	
	var files = terminal_data.get("files", [])
	
	if files.size() == 0:
		var no_files = Label.new()
		no_files.text = "No files available."
		no_files.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		files_list.add_child(no_files)
		return
	
	for file in files:
		var file_container = _create_file_entry(file)
		files_list.add_child(file_container)

func _create_log_entry(log_data: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 100)
	
	# Create panel background
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0.15, 0, 0.3)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0, 0.6, 0, 0.5)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Header with timestamp and author
	var header = HBoxContainer.new()
	
	var timestamp = Label.new()
	timestamp.text = log_data.get("timestamp", "Unknown Time")
	timestamp.add_theme_color_override("font_color", Color(0, 1, 0))
	timestamp.add_theme_font_size_override("font_size", 14)
	header.add_child(timestamp)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var author = Label.new()
	author.text = "by " + log_data.get("author", "Unknown")
	author.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	author.add_theme_font_size_override("font_size", 12)
	header.add_child(author)
	
	vbox.add_child(header)
	
	# Title
	var title = Label.new()
	title.text = log_data.get("title", "Untitled")
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Content
	var content = Label.new()
	content.text = log_data.get("content", "No content")
	content.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content.add_theme_font_size_override("font_size", 14)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(content)
	
	# Add margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(panel)
	
	container.add_child(margin)
	
	# Add spacing
	var spacer_bottom = Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 10)
	container.add_child(spacer_bottom)
	
	return container

func _create_file_entry(file_data: Dictionary) -> Control:
	var container = VBoxContainer.new()
	
	# Create panel background
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.3)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.8, 0.5)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# File title
	var title = Label.new()
	title.text = "📄 " + file_data.get("title", "Unknown File")
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 1))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# File content
	var content = Label.new()
	content.text = file_data.get("content", "No content available")
	content.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content.add_theme_font_size_override("font_size", 14)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(content)
	
	# Add margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(panel)
	
	container.add_child(margin)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	container.add_child(spacer)
	
	return container

func _close_terminal():
	# Unregister with UI manager
	var ui_manager = UIManager.get_instance()
	if ui_manager:
		ui_manager.unregister_ui_screen(self)
	
	queue_free()

func close_ui():
	_close_terminal()

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		_close_terminal()