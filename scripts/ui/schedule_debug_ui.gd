extends Control

@export var toggle_key: String = "F1"  # Key to toggle debug UI

@onready var schedule_manager: ScheduleManager = get_tree().get_first_node_in_group("schedule_manager")
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var period_label: Label = $VBoxContainer/PeriodLabel
@onready var time_speed_slider: HSlider = $VBoxContainer/TimeSpeedContainer/TimeSpeedSlider
@onready var time_speed_label: Label = $VBoxContainer/TimeSpeedContainer/TimeSpeedLabel
@onready var pause_button: Button = $VBoxContainer/PauseButton
@onready var room_option_button: OptionButton = $VBoxContainer/RoomContainer/RoomOptionButton
@onready var force_move_button: Button = $VBoxContainer/RoomContainer/ForceMoveButton
@onready var npc_status_label: Label = $VBoxContainer/NPCStatusLabel
# @onready var movement_toggle_button: Button = $VBoxContainer/MovementToggleButton

var selected_npc: NPCBase

func _ready():
    if not schedule_manager:
        queue_free()
        return
    
    # Start hidden
    visible = false
    
    # Connect signals
    schedule_manager.time_changed.connect(_on_time_changed)
    schedule_manager.time_period_changed.connect(_on_time_period_changed)
    
    time_speed_slider.value_changed.connect(_on_time_speed_changed)
    pause_button.pressed.connect(_on_pause_pressed)
    force_move_button.pressed.connect(_on_force_move_pressed)
    
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
    
    # Setup time period buttons
    for i in range(ScheduleManager.TimePeriod.size()):
        var button = Button.new()
        button.text = schedule_manager.get_time_period_name(i)
        button.pressed.connect(_on_time_period_button_pressed.bind(i))
        $VBoxContainer/TimePeriodButtons.add_child(button)
    
    # Initial update
    _update_ui()
    
    # Find NPC
    var npcs = get_tree().get_nodes_in_group("npcs")
    if npcs.size() > 0:
        selected_npc = npcs[0]

func _setup_room_options():
    room_option_button.clear()
    for i in range(ScheduleManager.Room.size()):
        room_option_button.add_item(schedule_manager.get_room_name(i))

func _input(event):
    if event.is_action_pressed("toggle_schedule_debug"):
        visible = not visible
        if visible:
            # Release mouse when showing debug UI
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            # Capture mouse when hiding debug UI
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
    if visible and selected_npc:
        _update_ui()

func _update_ui():
    if not schedule_manager:
        return
        
    time_label.text = "Time: " + schedule_manager.get_formatted_time()
    period_label.text = "Period: " + schedule_manager.get_time_period_name(schedule_manager.get_current_time_period())
    time_speed_label.text = "Speed: %.1fx" % schedule_manager.time_speed_multiplier
    pause_button.text = "Pause" if not schedule_manager.paused else "Resume"
    
    # Update NPC status
    if selected_npc and is_instance_valid(selected_npc):
        var status = "NPC: " + selected_npc.npc_name + "\n"
        status += "State: " + str(selected_npc.current_state) + "\n"
        status += "Room: " + selected_npc.assigned_room + "\n"
        status += "Movement: " + ("NavMesh" if selected_npc.use_navmesh else "Direct/Waypoint") + "\n"
        status += "Using Waypoints: " + str(selected_npc.use_waypoints) + "\n"
        status += "Is Paused: " + str(selected_npc.is_paused) + "\n"
        
        # Show navigation path info
        if selected_npc.navigation_path.size() > 0:
            status += "Nav Path: " + str(selected_npc.navigation_path_index + 1) + "/" + str(selected_npc.navigation_path.size())
        
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
    if not selected_npc:
        return
        
    var room_index = room_option_button.selected
    var waypoint_name = schedule_manager.get_room_waypoint_name(room_index)
    
    # Find waypoint
    var waypoint = get_tree().get_first_node_in_group(waypoint_name)
    if waypoint and waypoint is Node3D:
        print("Debug: Force moving ", selected_npc.npc_name, " to ", schedule_manager.get_room_name(room_index))
        
        # Clear any current state that might interfere
        if selected_npc.current_state != selected_npc.MovementState.PATROL:
            selected_npc.set_state(selected_npc.MovementState.PATROL)
        
        # Force immediate movement using navigation
        selected_npc._navigate_to_room(waypoint_name)
        selected_npc.assigned_room = schedule_manager.get_room_name(room_index)

# func _on_movement_toggle_pressed():
#     if not selected_npc:
#         return
#     
#     # Toggle between NavMesh and Direct/Waypoint movement
#     selected_npc.use_navmesh = not selected_npc.use_navmesh
#     print("Toggled movement system to: ", "NavMesh" if selected_npc.use_navmesh else "Direct/Waypoint")
