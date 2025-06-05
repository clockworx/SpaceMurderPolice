extends Control
class_name CaseFileUI

@onready var evidence_list = $MainPanel/VBoxContainer/TabContainer/Evidence/EvidenceList
@onready var suspects_list = $MainPanel/VBoxContainer/TabContainer/Suspects/SuspectsList
@onready var timeline_list = $MainPanel/VBoxContainer/TabContainer/Timeline/TimelineList
@onready var notes_input = $MainPanel/VBoxContainer/TabContainer/Notes/NotesContainer/NotesInput
@onready var connections_list = $MainPanel/VBoxContainer/TabContainer/Connections/ConnectionsContainer/ConnectionsList
@onready var theories_list = $MainPanel/VBoxContainer/TabContainer/Theories/TheoriesContainer/TheoriesList
@onready var add_theory_button = $MainPanel/VBoxContainer/TabContainer/Theories/TheoriesContainer/AddTheoryButton
@onready var close_button = $MainPanel/VBoxContainer/Header/CloseButton
@onready var case_title = $MainPanel/VBoxContainer/Header/CaseTitle

var evidence_manager: EvidenceManager
var case_data: Dictionary = {}
var theories: Array[Dictionary] = []
var timeline_events: Array[Dictionary] = []
var suspect_profiles: Array[Dictionary] = []
var evidence_connections: Array[Dictionary] = []
var selected_evidence: Array[String] = []  # For connection mode

signal case_file_closed()

func _ready():
    visible = false
    close_button.pressed.connect(_close_case_file)
    add_theory_button.pressed.connect(_add_new_theory)
    
    # Initialize case data
    _initialize_case_data()
    
    # Find evidence manager
    evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    if evidence_manager:
        evidence_manager.evidence_collected.connect(_on_evidence_collected)

func _initialize_case_data():
    case_data = {
        "case_name": "Murder at Aurora Station",
        "victim": "Dr. Elena Vasquez",
        "location": "Aurora Research Station - Laboratory 3",
        "date": "2387.03.15",
        "time_of_death": "~18:30 Station Time",
        "investigating_officers": ["Detective (Player)"],
        "case_status": "Active Investigation"
    }
    
    # Initialize timeline with known events
    timeline_events = [
        {
            "time": "18:00",
            "event": "Dr. Vasquez enters Laboratory 3",
            "source": "Security logs",
            "verified": false
        },
        {
            "time": "18:30",
            "event": "Time of death (estimated)",
            "source": "Autopsy findings",
            "verified": true
        },
        {
            "time": "19:45",
            "event": "Body discovered by maintenance",
            "source": "Incident report",
            "verified": true
        }
    ]
    
    # Initialize suspect profiles
    suspect_profiles = [
        {
            "name": "Riley Kim",
            "role": "Tech Specialist",
            "motive": "Unknown",
            "alibi": "Claims to be in engineering",
            "evidence_against": [],
            "notes": "Has access to all systems. Behavior seems suspicious during night cycles.",
            "suspicion_level": "High"
        },
        {
            "name": "Dr. Marcus Webb",
            "role": "Senior Researcher",
            "motive": "Potential research rivalry",
            "alibi": "Working in his quarters",
            "evidence_against": [],
            "notes": "Colleague of victim. May have had professional disagreements.",
            "suspicion_level": "Medium"
        },
        {
            "name": "Jake Torres",
            "role": "Security Officer",
            "motive": "Unknown",
            "alibi": "On patrol duty",
            "evidence_against": [],
            "notes": "Responsible for station security. Should have security footage access.",
            "suspicion_level": "Low"
        }
    ]

func show_case_file():
    visible = true
    _refresh_all_tabs()
    
    # Register with UIManager
    var ui_manager = UIManager.get_instance()
    if ui_manager:
        ui_manager.register_ui_screen(self)

func _close_case_file():
    visible = false
    case_file_closed.emit()
    
    # Unregister with UIManager
    var ui_manager = UIManager.get_instance()
    if ui_manager:
        ui_manager.unregister_ui_screen(self)

func close_ui():
    _close_case_file()

func _refresh_all_tabs():
    _refresh_evidence_tab()
    _refresh_suspects_tab()
    _refresh_timeline_tab()
    _refresh_connections_tab()
    _refresh_theories_tab()

func _refresh_evidence_tab():
    # Clear existing evidence
    for child in evidence_list.get_children():
        child.queue_free()
    
    var evidence_data = []
    if evidence_manager:
        evidence_data = evidence_manager.collected_evidence
    else:
        # Ship scene - use ship's evidence data
        var ship_interior = get_tree().get_first_node_in_group("ship_interior")
        if ship_interior:
            evidence_data = ShipInterior.current_case_evidence
    
    # Add evidence items
    for evidence in evidence_data:
        var item = _create_evidence_entry(evidence, false)
        evidence_list.add_child(item)

func _create_evidence_entry(evidence: Dictionary, clickable: bool = false) -> Control:
    var container = PanelContainer.new()
    container.custom_minimum_size = Vector2(0, 100)
    
    # Style the container
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.15, 0.2, 0.25, 0.8)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.4, 0.6, 0.8, 0.5)
    style.set_corner_radius_all(5)
    container.add_theme_stylebox_override("panel", style)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    container.add_child(margin)
    
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 5)
    margin.add_child(vbox)
    
    # Evidence name
    var name_label = Label.new()
    name_label.text = evidence.get("name", "Unknown Evidence")
    name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
    name_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(name_label)
    
    # Evidence type and description
    var hbox = HBoxContainer.new()
    vbox.add_child(hbox)
    
    var type_label = Label.new()
    type_label.text = "Type: " + evidence.get("type", "Unknown")
    type_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1))
    type_label.add_theme_font_size_override("font_size", 14)
    hbox.add_child(type_label)
    
    var spacer = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(spacer)
    
    var relevance_label = Label.new()
    var relevance = "Case Relevant" if evidence.get("case_relevant", false) else "Additional"
    relevance_label.text = relevance
    relevance_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4) if evidence.get("case_relevant", false) else Color(0.8, 0.8, 0.8))
    relevance_label.add_theme_font_size_override("font_size", 12)
    hbox.add_child(relevance_label)
    
    # Description
    var desc_label = Label.new()
    desc_label.text = evidence.get("description", "No description available")
    desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
    desc_label.add_theme_font_size_override("font_size", 13)
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(desc_label)
    
    # Add spacing
    var bottom_spacer = Control.new()
    bottom_spacer.custom_minimum_size = Vector2(0, 10)
    vbox.add_child(bottom_spacer)
    
    return container

func _refresh_suspects_tab():
    # Clear existing suspects
    for child in suspects_list.get_children():
        child.queue_free()
    
    for suspect in suspect_profiles:
        var item = _create_suspect_entry(suspect)
        suspects_list.add_child(item)

func _create_suspect_entry(suspect: Dictionary) -> Control:
    var container = PanelContainer.new()
    container.custom_minimum_size = Vector2(0, 130)
    
    # Style based on suspicion level
    var style = StyleBoxFlat.new()
    match suspect.get("suspicion_level", "Low"):
        "High":
            style.bg_color = Color(0.3, 0.15, 0.15, 0.8)
            style.border_color = Color(1, 0.3, 0.3, 0.7)
        "Medium":
            style.bg_color = Color(0.25, 0.2, 0.15, 0.8)
            style.border_color = Color(1, 0.7, 0.3, 0.7)
        _:
            style.bg_color = Color(0.15, 0.2, 0.15, 0.8)
            style.border_color = Color(0.3, 0.8, 0.3, 0.7)
    
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.set_corner_radius_all(5)
    container.add_theme_stylebox_override("panel", style)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    container.add_child(margin)
    
    var vbox = VBoxContainer.new()
    margin.add_child(vbox)
    
    # Header with name and suspicion level
    var header = HBoxContainer.new()
    vbox.add_child(header)
    
    var name_label = Label.new()
    name_label.text = suspect.get("name", "Unknown")
    name_label.add_theme_color_override("font_color", Color(1, 1, 1))
    name_label.add_theme_font_size_override("font_size", 18)
    header.add_child(name_label)
    
    var spacer = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    
    var suspicion_label = Label.new()
    suspicion_label.text = suspect.get("suspicion_level", "Low") + " Suspicion"
    match suspect.get("suspicion_level", "Low"):
        "High":
            suspicion_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
        "Medium":
            suspicion_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
        _:
            suspicion_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
    suspicion_label.add_theme_font_size_override("font_size", 14)
    header.add_child(suspicion_label)
    
    # Role
    var role_label = Label.new()
    role_label.text = "Role: " + suspect.get("role", "Unknown")
    role_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
    role_label.add_theme_font_size_override("font_size", 14)
    vbox.add_child(role_label)
    
    # Motive and Alibi
    var details_grid = GridContainer.new()
    details_grid.columns = 2
    vbox.add_child(details_grid)
    
    var motive_title = Label.new()
    motive_title.text = "Motive:"
    motive_title.add_theme_color_override("font_color", Color(1, 0.7, 0.7))
    motive_title.add_theme_font_size_override("font_size", 13)
    details_grid.add_child(motive_title)
    
    var motive_label = Label.new()
    motive_label.text = suspect.get("motive", "Unknown")
    motive_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
    motive_label.add_theme_font_size_override("font_size", 13)
    details_grid.add_child(motive_label)
    
    var alibi_title = Label.new()
    alibi_title.text = "Alibi:"
    alibi_title.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
    alibi_title.add_theme_font_size_override("font_size", 13)
    details_grid.add_child(alibi_title)
    
    var alibi_label = Label.new()
    alibi_label.text = suspect.get("alibi", "Unknown")
    alibi_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
    alibi_label.add_theme_font_size_override("font_size", 13)
    details_grid.add_child(alibi_label)
    
    # Notes
    var notes_label = Label.new()
    notes_label.text = "Notes: " + suspect.get("notes", "No additional notes")
    notes_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
    notes_label.add_theme_font_size_override("font_size", 12)
    notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(notes_label)
    
    return container

func _refresh_timeline_tab():
    # Clear existing timeline
    for child in timeline_list.get_children():
        child.queue_free()
    
    # Sort timeline events by time
    timeline_events.sort_custom(func(a, b): return a.time < b.time)
    
    for event in timeline_events:
        var item = _create_timeline_entry(event)
        timeline_list.add_child(item)

func _create_timeline_entry(event: Dictionary) -> Control:
    var container = HBoxContainer.new()
    container.custom_minimum_size = Vector2(0, 70)
    
    # Time label
    var time_container = PanelContainer.new()
    time_container.custom_minimum_size = Vector2(120, 0)
    
    var time_style = StyleBoxFlat.new()
    time_style.bg_color = Color(0.2, 0.3, 0.4, 0.8)
    time_style.set_corner_radius_all(5)
    time_container.add_theme_stylebox_override("panel", time_style)
    container.add_child(time_container)
    
    var time_label = Label.new()
    time_label.text = event.get("time", "??:??")
    time_label.add_theme_color_override("font_color", Color(1, 1, 1))
    time_label.add_theme_font_size_override("font_size", 16)
    time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    time_container.add_child(time_label)
    
    # Event details
    var details_container = PanelContainer.new()
    details_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var details_style = StyleBoxFlat.new()
    details_style.bg_color = Color(0.15, 0.15, 0.2, 0.6)
    if event.get("verified", false):
        details_style.border_color = Color(0.3, 0.8, 0.3, 0.8)
    else:
        details_style.border_color = Color(0.8, 0.6, 0.3, 0.8)
    details_style.border_width_left = 3
    details_style.set_corner_radius_all(5)
    details_container.add_theme_stylebox_override("panel", details_style)
    container.add_child(details_container)
    
    var details_margin = MarginContainer.new()
    details_margin.add_theme_constant_override("margin_left", 15)
    details_margin.add_theme_constant_override("margin_right", 15)
    details_margin.add_theme_constant_override("margin_top", 10)
    details_margin.add_theme_constant_override("margin_bottom", 10)
    details_container.add_child(details_margin)
    
    var details_vbox = VBoxContainer.new()
    details_margin.add_child(details_vbox)
    
    var event_label = Label.new()
    event_label.text = event.get("event", "Unknown event")
    event_label.add_theme_color_override("font_color", Color(1, 1, 1))
    event_label.add_theme_font_size_override("font_size", 15)
    details_vbox.add_child(event_label)
    
    var source_label = Label.new()
    var verification = " (Verified)" if event.get("verified", false) else " (Unconfirmed)"
    source_label.text = "Source: " + event.get("source", "Unknown") + verification
    source_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    source_label.add_theme_font_size_override("font_size", 12)
    details_vbox.add_child(source_label)
    
    return container

func _refresh_connections_tab():
    # Clear existing connections
    for child in connections_list.get_children():
        child.queue_free()
    
    # Add clickable evidence for making connections
    var evidence_data = []
    if evidence_manager:
        evidence_data = evidence_manager.collected_evidence
    else:
        var ship_interior = get_tree().get_first_node_in_group("ship_interior")
        if ship_interior:
            evidence_data = ShipInterior.current_case_evidence
    
    # Evidence selection area
    var selection_label = Label.new()
    selection_label.text = "Select two pieces of evidence to connect:"
    selection_label.add_theme_color_override("font_color", Color(1, 1, 1))
    selection_label.add_theme_font_size_override("font_size", 16)
    connections_list.add_child(selection_label)
    
    # Add clickable evidence items
    for evidence in evidence_data:
        var item = _create_clickable_evidence_entry(evidence)
        connections_list.add_child(item)
    
    # Separator
    var separator = HSeparator.new()
    separator.custom_minimum_size = Vector2(0, 20)
    connections_list.add_child(separator)
    
    # Existing connections
    var connections_label = Label.new()
    connections_label.text = "Evidence Connections:"
    connections_label.add_theme_color_override("font_color", Color(1, 1, 1))
    connections_label.add_theme_font_size_override("font_size", 16)
    connections_list.add_child(connections_label)
    
    if evidence_connections.size() == 0:
        var no_connections = Label.new()
        no_connections.text = "No connections made yet. Click evidence items above to connect them."
        no_connections.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
        no_connections.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        connections_list.add_child(no_connections)
    else:
        for connection in evidence_connections:
            var connection_item = _create_connection_entry(connection)
            connections_list.add_child(connection_item)

func _create_clickable_evidence_entry(evidence: Dictionary) -> Control:
    var container = PanelContainer.new()
    container.custom_minimum_size = Vector2(0, 80)
    
    var evidence_name = evidence.get("name", "Unknown")
    var is_selected = evidence_name in selected_evidence
    
    # Style based on selection state
    var style = StyleBoxFlat.new()
    if is_selected:
        style.bg_color = Color(0.3, 0.4, 0.6, 0.9)
        style.border_color = Color(0.5, 0.7, 1, 1)
    else:
        style.bg_color = Color(0.15, 0.2, 0.25, 0.8)
        style.border_color = Color(0.4, 0.6, 0.8, 0.5)
    
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.set_corner_radius_all(5)
    container.add_theme_stylebox_override("panel", style)
    
    # Make it clickable
    var button = Button.new()
    button.flat = true
    button.custom_minimum_size = Vector2(0, 80)
    button.pressed.connect(_on_evidence_selected.bind(evidence_name))
    container.add_child(button)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(margin)
    
    var hbox = HBoxContainer.new()
    hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(hbox)
    
    # Evidence name
    var name_label = Label.new()
    name_label.text = evidence_name
    name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4) if not is_selected else Color(1, 1, 1))
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(name_label)
    
    # Selection indicator
    if is_selected:
        var selected_label = Label.new()
        selected_label.text = "SELECTED"
        selected_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
        selected_label.add_theme_font_size_override("font_size", 12)
        hbox.add_child(selected_label)
    
    return container

func _on_evidence_selected(evidence_name: String):
    if evidence_name in selected_evidence:
        # Deselect
        selected_evidence.erase(evidence_name)
    else:
        # Select (max 2)
        if selected_evidence.size() < 2:
            selected_evidence.append(evidence_name)
        else:
            # Replace first selection
            selected_evidence[0] = selected_evidence[1]
            selected_evidence[1] = evidence_name
    
    # Check if we can make a connection
    if selected_evidence.size() == 2:
        _create_evidence_connection(selected_evidence[0], selected_evidence[1])
        selected_evidence.clear()
    
    _refresh_connections_tab()

func _create_evidence_connection(evidence1: String, evidence2: String):
    # Check if connection already exists
    for connection in evidence_connections:
        if (connection.evidence1 == evidence1 and connection.evidence2 == evidence2) or \
           (connection.evidence1 == evidence2 and connection.evidence2 == evidence1):
            return  # Connection already exists
    
    # Create connection dialog
    var dialog = AcceptDialog.new()
    dialog.title = "Create Evidence Connection"
    dialog.custom_minimum_size = Vector2(500, 200)
    
    var vbox = VBoxContainer.new()
    
    var info_label = Label.new()
    info_label.text = "Connecting: " + evidence1 + " ↔ " + evidence2
    info_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(info_label)
    
    var description_label = Label.new()
    description_label.text = "How are these pieces of evidence related?"
    vbox.add_child(description_label)
    
    var description_input = TextEdit.new()
    description_input.placeholder_text = "Describe the connection between these evidence pieces..."
    description_input.custom_minimum_size = Vector2(0, 100)
    vbox.add_child(description_input)
    
    dialog.add_child(vbox)
    get_tree().root.add_child(dialog)
    
    dialog.confirmed.connect(func():
        if description_input.text.strip_edges() != "":
            var new_connection = {
                "evidence1": evidence1,
                "evidence2": evidence2,
                "description": description_input.text.strip_edges(),
                "created_time": Time.get_unix_time_from_system(),
                "strength": _calculate_connection_strength(evidence1, evidence2)
            }
            evidence_connections.append(new_connection)
            _refresh_connections_tab()
        dialog.queue_free()
    )
    
    dialog.canceled.connect(func(): dialog.queue_free())

func _calculate_connection_strength(evidence1: String, evidence2: String) -> String:
    # Simple heuristic based on evidence types and names
    var strong_connections = [
        ["Plasma Cutter", "Autopsy Report"],
        ["Riley's Keycard", "Security Logs"],
        ["Bloody Footprints", "Autopsy Report"]
    ]
    
    for strong_pair in strong_connections:
        if (evidence1.contains(strong_pair[0]) and evidence2.contains(strong_pair[1])) or \
           (evidence1.contains(strong_pair[1]) and evidence2.contains(strong_pair[0])):
            return "Strong"
    
    return "Moderate"

func _create_connection_entry(connection: Dictionary) -> Control:
    var container = PanelContainer.new()
    container.custom_minimum_size = Vector2(0, 100)
    
    # Style based on connection strength
    var style = StyleBoxFlat.new()
    match connection.get("strength", "Moderate"):
        "Strong":
            style.bg_color = Color(0.2, 0.3, 0.2, 0.8)
            style.border_color = Color(0.4, 0.8, 0.4, 0.8)
        _:
            style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
            style.border_color = Color(0.6, 0.6, 0.8, 0.8)
    
    style.border_width_left = 3
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.set_corner_radius_all(5)
    container.add_theme_stylebox_override("panel", style)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    container.add_child(margin)
    
    var vbox = VBoxContainer.new()
    margin.add_child(vbox)
    
    # Connection header
    var header = HBoxContainer.new()
    vbox.add_child(header)
    
    var connection_label = Label.new()
    connection_label.text = connection.evidence1 + " ↔ " + connection.evidence2
    connection_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
    connection_label.add_theme_font_size_override("font_size", 15)
    connection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(connection_label)
    
    var strength_label = Label.new()
    strength_label.text = connection.get("strength", "Moderate") + " Connection"
    match connection.get("strength", "Moderate"):
        "Strong":
            strength_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
        _:
            strength_label.add_theme_color_override("font_color", Color(0.7, 0.7, 1))
    strength_label.add_theme_font_size_override("font_size", 12)
    header.add_child(strength_label)
    
    # Connection description
    var desc_label = Label.new()
    desc_label.text = connection.get("description", "No description")
    desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
    desc_label.add_theme_font_size_override("font_size", 13)
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(desc_label)
    
    return container

func _refresh_theories_tab():
    # Clear existing theories
    for child in theories_list.get_children():
        child.queue_free()
    
    if theories.size() == 0:
        var no_theories = Label.new()
        no_theories.text = "No theories created yet. Click 'Add New Theory' to start building your case."
        no_theories.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
        no_theories.add_theme_font_size_override("font_size", 16)
        no_theories.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        theories_list.add_child(no_theories)
        return
    
    for i in range(theories.size()):
        var theory = theories[i]
        var item = _create_theory_entry(theory, i)
        theories_list.add_child(item)

func _create_theory_entry(theory: Dictionary, index: int) -> Control:
    var container = PanelContainer.new()
    container.custom_minimum_size = Vector2(0, 100)
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.15, 0.25, 0.8)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.6, 0.4, 0.8, 0.7)
    style.set_corner_radius_all(5)
    container.add_theme_stylebox_override("panel", style)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    container.add_child(margin)
    
    var vbox = VBoxContainer.new()
    margin.add_child(vbox)
    
    # Header with theory name and delete button
    var header = HBoxContainer.new()
    vbox.add_child(header)
    
    var title_label = Label.new()
    title_label.text = "Theory " + str(index + 1) + ": " + theory.get("title", "Untitled")
    title_label.add_theme_color_override("font_color", Color(1, 0.9, 1))
    title_label.add_theme_font_size_override("font_size", 16)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_label)
    
    var delete_button = Button.new()
    delete_button.text = "Delete"
    delete_button.custom_minimum_size = Vector2(80, 30)
    delete_button.pressed.connect(_delete_theory.bind(index))
    header.add_child(delete_button)
    
    # Theory content
    var content_label = Label.new()
    content_label.text = theory.get("content", "No theory details provided")
    content_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
    content_label.add_theme_font_size_override("font_size", 14)
    content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(content_label)
    
    return container

func _add_new_theory():
    var theory_dialog = _create_theory_dialog()
    get_tree().root.add_child(theory_dialog)

func _create_theory_dialog() -> Control:
    var dialog = AcceptDialog.new()
    dialog.title = "Add New Theory"
    dialog.custom_minimum_size = Vector2(500, 300)
    
    var vbox = VBoxContainer.new()
    
    var title_label = Label.new()
    title_label.text = "Theory Title:"
    vbox.add_child(title_label)
    
    var title_input = LineEdit.new()
    title_input.placeholder_text = "Enter theory title..."
    vbox.add_child(title_input)
    
    var content_label = Label.new()
    content_label.text = "Theory Details:"
    vbox.add_child(content_label)
    
    var content_input = TextEdit.new()
    content_input.placeholder_text = "Describe your theory about what happened..."
    content_input.custom_minimum_size = Vector2(0, 150)
    vbox.add_child(content_input)
    
    dialog.add_child(vbox)
    
    dialog.confirmed.connect(func():
        if title_input.text.strip_edges() != "":
            var new_theory = {
                "title": title_input.text.strip_edges(),
                "content": content_input.text.strip_edges(),
                "created_time": Time.get_unix_time_from_system()
            }
            theories.append(new_theory)
            _refresh_theories_tab()
        dialog.queue_free()
    )
    
    dialog.canceled.connect(func(): dialog.queue_free())
    
    return dialog

func _delete_theory(index: int):
    if index >= 0 and index < theories.size():
        theories.remove_at(index)
        _refresh_theories_tab()

func _on_evidence_collected(evidence_data: Dictionary):
    # Refresh evidence tab when new evidence is collected
    if visible:
        _refresh_evidence_tab()

func _input(event):
    if event.is_action_pressed("ui_cancel") and visible:
        _close_case_file()
