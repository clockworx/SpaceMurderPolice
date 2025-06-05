extends Control

@onready var evidence_list = $Panel/VBoxContainer/ScrollContainer/EvidenceList
@onready var evidence_count_label = $Panel/VBoxContainer/HeaderPanel/CountLabel
@onready var panel = $Panel

var evidence_manager: EvidenceManager
var day_night_manager: DayNightManager
var night_progress_label: Label

func _ready():
    visible = false
    
    # Create night progress indicator
    _create_night_progress_indicator()
    
    # Find evidence manager (may not exist in ship scenes)
    evidence_manager = get_node_or_null("/root/AuroraStation/EvidenceManager")
    if evidence_manager:
        evidence_manager.evidence_collected.connect(_on_evidence_collected)
        print("Evidence UI: Connected to Evidence Manager")
    else:
        # Try alternative path
        await get_tree().process_frame
        evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
        if evidence_manager:
            evidence_manager.evidence_collected.connect(_on_evidence_collected)
            print("Evidence UI: Found Evidence Manager via group")
        else:
            print("Evidence UI: No Evidence Manager found (normal for ship scenes)")
        
        # Find day/night manager
        day_night_manager = get_tree().get_first_node_in_group("day_night_manager")
        if day_night_manager:
            day_night_manager.night_started.connect(_on_night_started)

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
    
    # Update night progress
    if day_night_manager and day_night_manager.is_day_time() and night_progress_label:
        var progress = day_night_manager.get_evidence_progress()
        var collected = day_night_manager.evidence_collected
        var threshold = day_night_manager.evidence_threshold
        night_progress_label.text = "Evidence Progress: " + str(collected) + "/" + str(threshold)
        
        # Change color as approaching night
        if progress >= 0.8:
            night_progress_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
        elif progress >= 0.6:
            night_progress_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))

func update_evidence_display():
    # Clear existing items
    for child in evidence_list.get_children():
        child.queue_free()
    
    var collected = 0
    var evidence_data = []
    
    if evidence_manager:
        # Normal mission scene - use evidence manager
        collected = evidence_manager.collected_evidence.size()
        evidence_data = evidence_manager.collected_evidence
    else:
        # Ship scene - use ship's static evidence data
        var ship_interior = get_tree().get_first_node_in_group("ship_interior")
        if ship_interior:
            evidence_data = ShipInterior.current_case_evidence
            collected = evidence_data.size()
        else:
            print("Evidence UI: No evidence source available")
            return
    
    var total = 6  # Default total evidence count
    if evidence_manager:
        total = evidence_manager.total_evidence_count
    
    evidence_count_label.text = "Evidence: " + str(collected) + "/" + str(total)
    print("Evidence UI: Displaying ", collected, " of ", total, " evidence items")
    
    # Add evidence items
    for evidence in evidence_data:
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

func _create_night_progress_indicator():
    night_progress_label = Label.new()
    night_progress_label.text = "Evidence Progress: 0/6"
    night_progress_label.add_theme_font_size_override("font_size", 18)
    night_progress_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
    night_progress_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
    night_progress_label.add_theme_constant_override("shadow_offset_x", 2)
    night_progress_label.add_theme_constant_override("shadow_offset_y", 2)
    night_progress_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    night_progress_label.position.x -= 200
    night_progress_label.position.y += 20
    add_child(night_progress_label)

func _on_night_started():
    if night_progress_label:
        night_progress_label.visible = false
