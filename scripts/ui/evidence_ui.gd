extends Control
class_name EvidenceUI

@onready var evidence_list = $Panel/VBoxContainer/ScrollContainer/EvidenceList
@onready var evidence_count_label = $Panel/VBoxContainer/HeaderPanel/CountLabel
@onready var panel = $Panel

var evidence_manager: EvidenceManager

func _ready():
    visible = false
    
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

func _input(event):
    if event.is_action_pressed("toggle_evidence"):
        toggle_visibility()

func toggle_visibility():
    visible = !visible
    if visible:
        update_evidence_display()
        # Register with UIManager when opened
        var ui_manager = UIManager.get_instance()
        if ui_manager:
            ui_manager.register_ui_screen(self)
    else:
        # Unregister when closed
        var ui_manager = UIManager.get_instance()
        if ui_manager:
            ui_manager.unregister_ui_screen(self)

func _on_evidence_collected(evidence_data: Dictionary):
    print("Evidence UI: Evidence collected signal received - ", evidence_data.get("name", "Unknown"))
    if visible:
        update_evidence_display()
    else:
        # Flash a notification or something to indicate collection
        print("Evidence collected: ", evidence_data.get("name", "Unknown"))

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
    
    evidence_count_label.text = "CASE EVIDENCE (" + str(collected) + ")"
    print("Evidence UI: Displaying ", collected, " evidence items")
    
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

func close_ui():
    visible = false
    
    # Unregister with UIManager
    var ui_manager = UIManager.get_instance()
    if ui_manager:
        ui_manager.unregister_ui_screen(self)
