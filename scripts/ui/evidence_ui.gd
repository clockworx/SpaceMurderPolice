extends Control

@onready var evidence_list = $Panel/VBoxContainer/ScrollContainer/EvidenceList
@onready var evidence_count_label = $Panel/VBoxContainer/HeaderPanel/CountLabel
@onready var panel = $Panel

var evidence_manager: EvidenceManager

func _ready():
	visible = false
	
	# Find evidence manager
	evidence_manager = get_node_or_null("/root/AuroraStation/EvidenceManager")
	if evidence_manager:
		evidence_manager.evidence_collected.connect(_on_evidence_collected)
		print("Evidence UI: Connected to Evidence Manager")
	else:
		push_error("Evidence UI: Could not find Evidence Manager!")
		# Try alternative path
		await get_tree().process_frame
		evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
		if evidence_manager:
			evidence_manager.evidence_collected.connect(_on_evidence_collected)
			print("Evidence UI: Found Evidence Manager via group")

func _input(event):
	if event.is_action_pressed("toggle_evidence"):
		toggle_visibility()

func toggle_visibility():
	visible = !visible
	if visible:
		update_evidence_display()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_evidence_collected(evidence_data: Dictionary):
	print("Evidence UI: Evidence collected signal received - ", evidence_data.get("name", "Unknown"))
	if visible:
		update_evidence_display()
	else:
		# Flash a notification or something to indicate collection
		print("Evidence collected: ", evidence_data.get("name", "Unknown"))

func update_evidence_display():
	if not evidence_manager:
		print("Evidence UI: No evidence manager found during update")
		return
	
	# Clear existing items
	for child in evidence_list.get_children():
		child.queue_free()
	
	# Update count
	var collected = evidence_manager.collected_evidence.size()
	var total = evidence_manager.total_evidence_count
	evidence_count_label.text = "Evidence: " + str(collected) + "/" + str(total)
	print("Evidence UI: Displaying ", collected, " of ", total, " evidence items")
	
	# Add evidence items
	for evidence in evidence_manager.collected_evidence:
		var item = create_evidence_item(evidence)
		evidence_list.add_child(item)
		print("Evidence UI: Added item - ", evidence.get("name", "Unknown"))

func create_evidence_item(evidence_data: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(350, 80)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	container.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = evidence_data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	vbox.add_child(name_label)
	
	var type_label = Label.new()
	type_label.text = "Type: " + evidence_data.get("type", "Unknown")
	type_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(type_label)
	
	var desc_label = Label.new()
	desc_label.text = evidence_data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	return container
