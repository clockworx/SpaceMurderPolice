extends Control

@export var toggle_key: String = "F1"  # Key to toggle debug UI

@onready var schedule_manager: ScheduleManager = get_tree().get_first_node_in_group("schedule_manager")

# Try both paths for compatibility
@onready var time_label: Label = get_node_or_null("ScrollContainer/VBoxContainer/TimeLabel") if get_node_or_null("ScrollContainer/VBoxContainer/TimeLabel") else get_node_or_null("VBoxContainer/TimeLabel")
@onready var period_label: Label = get_node_or_null("ScrollContainer/VBoxContainer/PeriodLabel") if get_node_or_null("ScrollContainer/VBoxContainer/PeriodLabel") else get_node_or_null("VBoxContainer/PeriodLabel") 
@onready var time_speed_slider: HSlider = get_node_or_null("ScrollContainer/VBoxContainer/TimeSpeedContainer/TimeSpeedSlider") if get_node_or_null("ScrollContainer/VBoxContainer/TimeSpeedContainer/TimeSpeedSlider") else get_node_or_null("VBoxContainer/TimeSpeedContainer/TimeSpeedSlider")
@onready var time_speed_label: Label = get_node_or_null("ScrollContainer/VBoxContainer/TimeSpeedContainer/TimeSpeedLabel") if get_node_or_null("ScrollContainer/VBoxContainer/TimeSpeedContainer/TimeSpeedLabel") else get_node_or_null("VBoxContainer/TimeSpeedContainer/TimeSpeedLabel")
@onready var pause_button: Button = get_node_or_null("ScrollContainer/VBoxContainer/PauseButton") if get_node_or_null("ScrollContainer/VBoxContainer/PauseButton") else get_node_or_null("VBoxContainer/PauseButton")
@onready var room_option_button: OptionButton = get_node_or_null("ScrollContainer/VBoxContainer/RoomContainer/RoomOptionButton") if get_node_or_null("ScrollContainer/VBoxContainer/RoomContainer/RoomOptionButton") else get_node_or_null("VBoxContainer/RoomContainer/RoomOptionButton")
@onready var force_move_button: Button = get_node_or_null("ScrollContainer/VBoxContainer/RoomContainer/ForceMoveButton") if get_node_or_null("ScrollContainer/VBoxContainer/RoomContainer/ForceMoveButton") else get_node_or_null("VBoxContainer/RoomContainer/ForceMoveButton")
@onready var npc_status_label: Label = get_node_or_null("ScrollContainer/VBoxContainer/NPCStatusLabel") if get_node_or_null("ScrollContainer/VBoxContainer/NPCStatusLabel") else get_node_or_null("VBoxContainer/NPCStatusLabel")
# @onready var movement_toggle_button: Button = $VBoxContainer/MovementToggleButton

# Waypoint visualization controls
var waypoint_viz_checkbox: CheckBox
var waypoint_network_manager: WaypointNetworkManager
var debug_markers_visible: bool = false

var selected_npc: NPCBase
var npc_dropdown: OptionButton
var available_npcs: Array[NPCBase] = []

func _ready():
    # print("Schedule Debug UI: Initializing...")
    
    # Add to group so it can be found
    add_to_group("schedule_debug_ui")
    
    if not schedule_manager:
        # print("Schedule Debug UI: ERROR - No schedule manager found!")
        queue_free()
        return
    
    # Start hidden
    visible = false
    
    # Set a more visible position and size
    # Force absolute positioning
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    position = Vector2(50, 20)  # Move further right to avoid cutoff
    size = Vector2(450, 600)  # Make wider to accommodate content
    
    # Enable clipping
    clip_contents = true
    
    # Make panel more visible
    var panel = $Panel
    if panel:
        # Create a dark background style
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
        style.corner_radius_top_left = 5
        style.corner_radius_top_right = 5
        style.corner_radius_bottom_left = 5
        style.corner_radius_bottom_right = 5
        panel.add_theme_stylebox_override("panel", style)
        
        # Ensure panel fills the control
        panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        panel.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
    
    # Fix container alignment - check for both possible paths
    var vbox = get_node_or_null("ScrollContainer/VBoxContainer")
    var scroll_container = get_node_or_null("ScrollContainer")
    
    if not vbox:
        vbox = get_node_or_null("VBoxContainer")
    
    # If we have a scroll container, configure it
    if scroll_container:
        scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        scroll_container.offset_left = 10
        scroll_container.offset_top = 10
        scroll_container.offset_right = -10
        scroll_container.offset_bottom = -10
    
    if vbox:
        # Make text smaller
        var theme = Theme.new()
        theme.default_font_size = 12
        vbox.theme = theme
        
        # Reset VBox positioning
        if not scroll_container:
            # If no scroll container, position VBox directly
            vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            vbox.position = Vector2(50, 10)  # Force positive position
            vbox.size = Vector2(340, 580)
        else:
            # If in scroll container, ensure proper positioning
            vbox.position = Vector2(0, 0)  # Reset position within scroll container
            vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
            vbox.custom_minimum_size = Vector2(400, 0)  # Ensure minimum width
    
    # Connect signals
    schedule_manager.time_changed.connect(_on_time_changed)
    schedule_manager.time_period_changed.connect(_on_time_period_changed)
    
    if time_speed_slider:
        time_speed_slider.value_changed.connect(_on_time_speed_changed)
    else:
        # print("Schedule Debug UI: Warning - time_speed_slider not found")
        pass
    if pause_button:
        pause_button.pressed.connect(_on_pause_pressed)
    else:
        # print("Schedule Debug UI: Warning - pause_button not found")
        pass
    if force_move_button:
        force_move_button.pressed.connect(_on_force_move_pressed)
        # print("Schedule Debug UI: Force move button connected")
    else:
        # print("Schedule Debug UI: ERROR - force_move_button not found!")
        pass
    
    # Add movement toggle button if it doesn't exist
    # if not movement_toggle_button:
    #     movement_toggle_button = Button.new()
    #     movement_toggle_button.text = "Toggle Movement System"
    #     $VBoxContainer.add_child(movement_toggle_button)
    # 
    # movement_toggle_button.pressed.connect(_on_movement_toggle_pressed)
    
    # Add toggle key to input map if not exists
    if not InputMap.has_action("toggle_schedule_debug"):
        InputMap.add_action("toggle_schedule_debug")
        var event = InputEventKey.new()
        event.keycode = KEY_F1
        InputMap.action_add_event("toggle_schedule_debug", event)
    
    # Setup room options
    _setup_room_options()
    
    # Fix room container layout
    var room_container = $VBoxContainer/RoomContainer
    if room_container:
        room_container.custom_minimum_size = Vector2(300, 40)
        
        # Fix the dropdown and button sizes
        if room_option_button:
            room_option_button.custom_minimum_size = Vector2(180, 30)
            room_option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            
        if force_move_button:
            force_move_button.custom_minimum_size = Vector2(80, 30)
            force_move_button.size_flags_horizontal = Control.SIZE_SHRINK_END
    
    # Setup time period buttons
    for i in range(ScheduleManager.TimePeriod.size()):
        var button = Button.new()
        button.text = schedule_manager.get_time_period_name(i)
        button.pressed.connect(_on_time_period_button_pressed.bind(i))
        $VBoxContainer/TimePeriodButtons.add_child(button)
    
    # Initial update
    _update_ui()
    
    # Force proper positioning after everything is loaded
    call_deferred("_fix_positioning")
    
    # Find NPCs and setup selector
    _setup_npc_selector()
    
    # Add toggle schedule button
    var schedule_toggle = Button.new()
    schedule_toggle.name = "ScheduleToggleButton"
    schedule_toggle.text = "Schedule: " + ("ON" if selected_npc and selected_npc.use_schedule else "OFF")
    schedule_toggle.pressed.connect(_on_schedule_toggle_pressed)
    
    # Find the correct VBoxContainer
    var vbox_for_button = get_node_or_null("ScrollContainer/VBoxContainer")
    if not vbox_for_button:
        vbox_for_button = get_node_or_null("VBoxContainer")
    if vbox_for_button:
        vbox_for_button.add_child(schedule_toggle)
        
        # Add separator
        var sep = HSeparator.new()
        vbox_for_button.add_child(sep)
        
        # Add waypoint visualization checkbox
        waypoint_viz_checkbox = CheckBox.new()
        waypoint_viz_checkbox.name = "WaypointVizCheckbox"
        waypoint_viz_checkbox.text = "Show Waypoint Debug Visualization"
        waypoint_viz_checkbox.set_pressed(false)  # Start with visualization off
        waypoint_viz_checkbox.toggled.connect(_on_waypoint_viz_toggled)
        vbox_for_button.add_child(waypoint_viz_checkbox)
        
        # Add separator for saboteur controls
        var sep2 = HSeparator.new()
        vbox_for_button.add_child(sep2)
        
        # Add saboteur controls section
        var saboteur_label = Label.new()
        saboteur_label.text = "Saboteur Controls:"
        vbox_for_button.add_child(saboteur_label)
        
        # Add activate saboteur button
        var activate_saboteur_btn = Button.new()
        activate_saboteur_btn.name = "ActivateSaboteurButton"
        activate_saboteur_btn.text = "Activate Saboteur"
        activate_saboteur_btn.pressed.connect(_on_activate_saboteur_pressed)
        vbox_for_button.add_child(activate_saboteur_btn)
        
        # Add deactivate saboteur button
        var deactivate_saboteur_btn = Button.new()
        deactivate_saboteur_btn.name = "DeactivateSaboteurButton"
        deactivate_saboteur_btn.text = "Deactivate Saboteur"
        deactivate_saboteur_btn.pressed.connect(_on_deactivate_saboteur_pressed)
        vbox_for_button.add_child(deactivate_saboteur_btn)
        
        # Add saboteur status label
        var saboteur_status = Label.new()
        saboteur_status.name = "SaboteurStatusLabel"
        saboteur_status.text = "Saboteur: Not Selected"
        saboteur_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        vbox_for_button.add_child(saboteur_status)
        
        # Add separator for saboteur visualization
        var sep3 = HSeparator.new()
        vbox_for_button.add_child(sep3)
        
        # Add saboteur visualization label
        var viz_label = Label.new()
        viz_label.text = "Saboteur Debug Visualization:"
        vbox_for_button.add_child(viz_label)
        
        # Add visualization checkboxes
        var awareness_checkbox = CheckBox.new()
        awareness_checkbox.name = "AwarenessCheckbox"
        awareness_checkbox.text = "Show Detection Range"
        awareness_checkbox.toggled.connect(_on_awareness_toggled)
        vbox_for_button.add_child(awareness_checkbox)
        
        var vision_checkbox = CheckBox.new()
        vision_checkbox.name = "VisionCheckbox"
        vision_checkbox.text = "Show Vision Cone"
        vision_checkbox.toggled.connect(_on_vision_toggled)
        vbox_for_button.add_child(vision_checkbox)
        
        var sound_checkbox = CheckBox.new()
        sound_checkbox.name = "SoundCheckbox"
        sound_checkbox.text = "Show Sound Detection"
        sound_checkbox.toggled.connect(_on_sound_toggled)
        vbox_for_button.add_child(sound_checkbox)
        
        var state_checkbox = CheckBox.new()
        state_checkbox.name = "StateCheckbox"
        state_checkbox.text = "Show AI State"
        state_checkbox.toggled.connect(_on_state_toggled)
        vbox_for_button.add_child(state_checkbox)
        
        var path_checkbox = CheckBox.new()
        path_checkbox.name = "PathCheckbox"
        path_checkbox.text = "Show Patrol Path"
        path_checkbox.toggled.connect(_on_path_toggled)
        vbox_for_button.add_child(path_checkbox)
    
    # Get waypoint network manager
    waypoint_network_manager = get_tree().get_first_node_in_group("waypoint_network_manager")

func _setup_npc_selector():
    # Get all NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    available_npcs.clear()
    
    # Find or create the VBox container
    var vbox = get_node_or_null("ScrollContainer/VBoxContainer")
    if not vbox:
        vbox = get_node_or_null("VBoxContainer")
    
    if vbox:
        # Add separator
        var separator = HSeparator.new()
        vbox.add_child(separator)
        vbox.move_child(separator, 0)
        
        # Add NPC selector label
        var npc_label = Label.new()
        npc_label.text = "Select NPC:"
        vbox.add_child(npc_label)
        vbox.move_child(npc_label, 1)
        
        # Add NPC dropdown
        npc_dropdown = OptionButton.new()
        npc_dropdown.name = "NPCSelector"
        
        for npc in npcs:
            if npc is NPCBase:
                available_npcs.append(npc)
                npc_dropdown.add_item(npc.npc_name)
        
        if available_npcs.size() > 0:
            selected_npc = available_npcs[0]
            npc_dropdown.select(0)
            
        npc_dropdown.item_selected.connect(_on_npc_selected)
        vbox.add_child(npc_dropdown)
        vbox.move_child(npc_dropdown, 2)
        
        # Add separator after NPC selector
        var separator2 = HSeparator.new()
        vbox.add_child(separator2)
        vbox.move_child(separator2, 3)
        
        # print("Schedule Debug UI: Found ", available_npcs.size(), " NPCs")

func _setup_room_options():
    room_option_button.clear()
    for i in range(ScheduleManager.Room.size()):
        room_option_button.add_item(schedule_manager.get_room_name(i))
    
    # Select first room by default
    if room_option_button.get_item_count() > 0:
        room_option_button.select(0)
        # print("Schedule Debug UI: Room dropdown populated with ", room_option_button.get_item_count(), " rooms")

func _input(event):
    if event.is_action_pressed("toggle_schedule_debug"):
        visible = not visible
        # print("Schedule Debug UI: Toggled visibility to ", visible)
        if visible:
            # Release mouse when showing debug UI
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            # print("Schedule Debug UI: Force move button exists: ", force_move_button != null)
            if force_move_button:
                # print("  Button text: ", force_move_button.text)
                # print("  Button disabled: ", force_move_button.disabled)
                pass
            
            # Make sure the UI is visible
            z_index = 100
            
            # Print UI position and size
            # print("Schedule Debug UI position: ", position)
            # print("Schedule Debug UI size: ", size)
            # print("Schedule Debug UI global position: ", global_position)
            
            # Debug the button's actual position
            if force_move_button:
                # print("Force move button global position: ", force_move_button.global_position)
                # print("Force move button position: ", force_move_button.position)
                # print("Force move button size: ", force_move_button.size)
                # print("Force move button visible: ", force_move_button.visible)
                pass
            # Debug room dropdown
            if room_option_button:
                # print("Room dropdown selected: ", room_option_button.selected)
                # print("Room dropdown item count: ", room_option_button.get_item_count())
                pass
            # Debug VBox position
            var vbox_debug = get_node_or_null("ScrollContainer/VBoxContainer")
            if not vbox_debug:
                vbox_debug = get_node_or_null("VBoxContainer")
            if vbox_debug:
                # print("VBox global position: ", vbox_debug.global_position)
                # print("VBox position: ", vbox_debug.position)
                # print("VBox size: ", vbox_debug.size)
                pass
        else:
            # Capture mouse when hiding debug UI
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
    if visible:
        if selected_npc:
            _update_ui()
        _update_saboteur_status()

func _update_ui():
    if not schedule_manager:
        return
        
    if time_label:
        time_label.text = "Time: " + schedule_manager.get_formatted_time()
        time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        
    if period_label:
        period_label.text = "Period: " + schedule_manager.get_time_period_name(schedule_manager.get_current_time_period())
        period_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        
    if time_speed_label:
        time_speed_label.text = "Speed: %.1fx" % schedule_manager.time_speed_multiplier
        
    if pause_button:
        pause_button.text = "Pause" if not schedule_manager.paused else "Resume"
    
    # Update NPC status
    if selected_npc and is_instance_valid(selected_npc):
        var status = "NPC: " + selected_npc.npc_name + "\n"
        status += "State: " + str(selected_npc.current_state) + "\n"
        status += "Room: " + selected_npc.assigned_room + "\n"
        status += "Movement: Waypoint-based\n"
        status += "Use Schedule: " + ("✓" if selected_npc.use_schedule else "✗") + "\n"
        status += "Is Moving: " + str(selected_npc.is_moving) + "\n"
        
        # Show waypoint path info
        if selected_npc.waypoint_path.size() > 0:
            status += "Waypoint Path: " + str(selected_npc.waypoint_path_index + 1) + "/" + str(selected_npc.waypoint_path.size())
        
        if npc_status_label:
            npc_status_label.text = status

func _on_time_changed(hour: int, minute: int):
    _update_ui()

func _on_time_period_changed(period: ScheduleManager.TimePeriod):
    _update_ui()

func _on_time_speed_changed(value: float):
    if schedule_manager:
        schedule_manager.time_speed_multiplier = value
        _update_ui()

func _on_pause_pressed():
    if schedule_manager:
        schedule_manager.paused = not schedule_manager.paused
        _update_ui()

func _on_time_period_button_pressed(period: int):
    if schedule_manager:
        schedule_manager.force_time_period(period)

func _on_force_move_pressed():
    # print("Debug: Force move button pressed")
    
    if not selected_npc:
        # print("Debug: No NPC selected")
        return
    
    if not schedule_manager:
        # print("Debug: No schedule manager found")
        return
        
    var room_index = room_option_button.selected
    # print("Debug: Selected room index: ", room_index)
    
    if room_index < 0:
        # print("Debug: No room selected in dropdown")
        return
    
    var waypoint_name = schedule_manager.get_room_waypoint_name(room_index)
    # print("Debug: Waypoint name from schedule manager: ", waypoint_name)
    
    if waypoint_name.is_empty():
        # print("Debug: Empty waypoint name returned")
        return
    
    # Use the waypoint name with _Center suffix for room centers
    var room_center_waypoint = waypoint_name.replace("_Waypoint", "_Center")
    
    # print("Debug: Force moving ", selected_npc.npc_name, " to ", schedule_manager.get_room_name(room_index), " (", room_center_waypoint, ")")
    # print("  Current NPC state: ", selected_npc.current_state)
    # print("  Is moving: ", selected_npc.is_moving)
    
    # Temporarily disable schedule to allow manual override
    var original_use_schedule = selected_npc.use_schedule
    selected_npc.use_schedule = false
    
    # Clear any current state that might interfere
    if selected_npc.current_state != selected_npc.MovementState.PATROL:
        selected_npc.set_state(selected_npc.MovementState.PATROL)
    
    # Stop any current movement first
    selected_npc.is_moving = false
    selected_npc.waypoint_path.clear()
    selected_npc.waypoint_path_index = 0
    
    # Force immediate movement using navigation
    if selected_npc.navigate_to_room(room_center_waypoint):
        # print("Debug: Navigation started successfully")
        selected_npc.assigned_room = schedule_manager.get_room_name(room_index)
        
        # Don't re-enable schedule for force move - let user control it
        # print("Debug: Force move initiated, schedule disabled for manual control")
    else:
        # print("Debug: Navigation failed - check if waypoint exists: ", room_center_waypoint)
        # Restore schedule state if navigation failed
        selected_npc.use_schedule = original_use_schedule

func _on_npc_selected(index: int):
    if index >= 0 and index < available_npcs.size():
        selected_npc = available_npcs[index]
        # print("Debug: Selected NPC: ", selected_npc.npc_name)
        
        # Update schedule toggle button text
        var schedule_button = get_node_or_null("ScrollContainer/VBoxContainer/ScheduleToggleButton")
        if not schedule_button:
            schedule_button = get_node_or_null("VBoxContainer/ScheduleToggleButton")
        if schedule_button:
            schedule_button.text = "Schedule: " + ("ON" if selected_npc.use_schedule else "OFF")
        
        # Update UI
        _update_ui()

func _on_schedule_toggle_pressed():
    if not selected_npc:
        # print("Debug: No NPC selected")
        return
    
    # Toggle schedule
    selected_npc.use_schedule = not selected_npc.use_schedule
    # print("Debug: Toggled ", selected_npc.npc_name, " schedule to: ", selected_npc.use_schedule)
    
    # Update button text
    var schedule_button = get_node_or_null("ScrollContainer/VBoxContainer/ScheduleToggleButton")
    if not schedule_button:
        schedule_button = get_node_or_null("VBoxContainer/ScheduleToggleButton")
    if schedule_button:
        schedule_button.text = "Schedule: " + ("ON" if selected_npc.use_schedule else "OFF")
    
    # If enabled, trigger initial schedule check
    if selected_npc.use_schedule:
        selected_npc._initial_schedule_check()

func _on_waypoint_viz_toggled(button_pressed: bool):
    debug_markers_visible = button_pressed
    
    # Toggle debug markers in waypoint network manager
    if waypoint_network_manager:
        var scene_root = get_tree().current_scene
        
        # Find all debug markers (they have labels)
        for child in scene_root.get_children():
            if child is MeshInstance3D and child.has_node("Label3D"):
                child.visible = debug_markers_visible
    
    # Toggle waypoint path visualization for all NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if npc is NPCBase:
            # Update the flag on each NPC
            npc.show_waypoint_path = debug_markers_visible
            
            # Show/hide current path visualization
            if debug_markers_visible and npc.is_moving:
                npc._visualize_waypoint_path()
            else:
                npc._clear_path_visualization()
    
    # print("Waypoint visualization: ", "ON" if debug_markers_visible else "OFF")

func _fix_positioning():
    """Force proper positioning of all UI elements"""
    # Ensure the main control is properly positioned
    position = Vector2(50, 20)
    size = Vector2(450, 600)
    
    # Fix VBox positioning
    var vbox = get_node_or_null("ScrollContainer/VBoxContainer")
    if not vbox:
        vbox = get_node_or_null("VBoxContainer")
    
    if vbox:
        # Force VBox to stay within bounds
        if vbox.global_position.x < 50:
            vbox.position.x = 0  # Reset local position
            
        # Ensure all children are properly sized
        for child in vbox.get_children():
            if child is Control:
                child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                if child is Button or child is OptionButton:
                    child.custom_minimum_size.x = 100

# func _on_movement_toggle_pressed():
#     if not selected_npc:
#         return
#     
#     # Toggle between NavMesh and Direct/Waypoint movement
#     selected_npc.use_navmesh = not selected_npc.use_navmesh
#     print("Toggled movement system to: ", "NavMesh" if selected_npc.use_navmesh else "Direct/Waypoint")

func _on_activate_saboteur_pressed():
    var phase_manager = get_tree().get_first_node_in_group("phase_manager")
    if phase_manager and phase_manager.has_method("activate_saboteur_manually"):
        phase_manager.activate_saboteur_manually()
        _update_saboteur_status()

func _on_deactivate_saboteur_pressed():
    var phase_manager = get_tree().get_first_node_in_group("phase_manager")
    if phase_manager and phase_manager.has_method("deactivate_saboteur_manually"):
        phase_manager.deactivate_saboteur_manually()
        _update_saboteur_status()

func _update_saboteur_status():
    var status_label = get_node_or_null("ScrollContainer/VBoxContainer/SaboteurStatusLabel")
    if not status_label:
        status_label = get_node_or_null("VBoxContainer/SaboteurStatusLabel")
    
    if not status_label:
        return
    
    var phase_manager = get_tree().get_first_node_in_group("phase_manager")
    if not phase_manager:
        status_label.text = "Saboteur: No Phase Manager"
        return
    
    var saboteur = phase_manager.get_current_saboteur()
    if saboteur:
        var saboteur_ai = saboteur.get_node_or_null("SaboteurPatrolAI")
        var is_active = saboteur_ai != null and saboteur_ai.is_active
        status_label.text = "Saboteur: " + saboteur.npc_name + " (" + ("Active" if is_active else "Inactive") + ")"
    else:
        status_label.text = "Saboteur: Not Selected"

func _on_awareness_toggled(button_pressed: bool):
    _update_saboteur_visualization()

func _on_vision_toggled(button_pressed: bool):
    _update_saboteur_visualization()

func _on_sound_toggled(button_pressed: bool):
    _update_saboteur_visualization()

func _on_state_toggled(button_pressed: bool):
    _update_saboteur_visualization()

func _on_path_toggled(button_pressed: bool):
    _update_saboteur_visualization()

func _update_saboteur_visualization():
    """Update saboteur debug visualization based on checkbox states"""
    var phase_manager = get_tree().get_first_node_in_group("phase_manager")
    if not phase_manager:
        return
    
    var saboteur = phase_manager.get_current_saboteur()
    if not saboteur:
        return
    
    var saboteur_ai = saboteur.get_node_or_null("SaboteurPatrolAI")
    if not saboteur_ai:
        return
    
    # Get checkbox states
    var awareness_cb = get_node_or_null("ScrollContainer/VBoxContainer/AwarenessCheckbox")
    if not awareness_cb:
        awareness_cb = get_node_or_null("VBoxContainer/AwarenessCheckbox")
    
    var vision_cb = get_node_or_null("ScrollContainer/VBoxContainer/VisionCheckbox")
    if not vision_cb:
        vision_cb = get_node_or_null("VBoxContainer/VisionCheckbox")
        
    var sound_cb = get_node_or_null("ScrollContainer/VBoxContainer/SoundCheckbox")
    if not sound_cb:
        sound_cb = get_node_or_null("VBoxContainer/SoundCheckbox")
        
    var state_cb = get_node_or_null("ScrollContainer/VBoxContainer/StateCheckbox")
    if not state_cb:
        state_cb = get_node_or_null("VBoxContainer/StateCheckbox")
        
    var path_cb = get_node_or_null("ScrollContainer/VBoxContainer/PathCheckbox")
    if not path_cb:
        path_cb = get_node_or_null("VBoxContainer/PathCheckbox")
    
    # Update visualization
    if saboteur_ai.has_method("set_debug_visualization"):
        saboteur_ai.set_debug_visualization(
            awareness_cb.button_pressed if awareness_cb else false,
            vision_cb.button_pressed if vision_cb else false,
            state_cb.button_pressed if state_cb else false,
            path_cb.button_pressed if path_cb else false,
            sound_cb.button_pressed if sound_cb else false
        )
