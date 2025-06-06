extends Node
class_name SabotageSystemManager

enum SabotageEvent {
    POWER_OUTAGE,
    SECURITY_MALFUNCTION,
    LIFE_SUPPORT_ISSUES,
    COMMUNICATION_BLACKOUT
}

enum SystemStatus {
    NORMAL,
    DAMAGED,
    REPAIRING,
    OFFLINE
}

@export var progress_thresholds: Dictionary = {
    SabotageEvent.POWER_OUTAGE: 25,
    SabotageEvent.SECURITY_MALFUNCTION: 50,
    SabotageEvent.LIFE_SUPPORT_ISSUES: 75,
    SabotageEvent.COMMUNICATION_BLACKOUT: 90
}

@export var transition_duration: float = 2.0

var investigation_progress: float = 0.0
var total_evidence: int = 0
var collected_evidence: int = 0
var triggered_events: Array[SabotageEvent] = []
var system_status: Dictionary = {}
var affected_rooms: Dictionary = {}
var is_transitioning: bool = false

# Lighting references
var room_lights: Dictionary = {}  # Room name -> Array[Light3D]
var emergency_lights: Array[Light3D] = []
var emergency_light_tweens: Array[Tween] = []
var disabled_terminals: Array[Node] = []
var environment: Environment

# Original values for restoration
var original_light_values: Dictionary = {}
var original_env_values: Dictionary = {}

signal sabotage_triggered(event: SabotageEvent)
signal sabotage_resolved(event: SabotageEvent)
signal system_status_changed(system: String, status: SystemStatus)
signal progress_updated(progress: float)
signal repair_needed(event: SabotageEvent, location: String)
signal sabotage_started(location: String, position: Vector3)
signal sabotage_ended()

func _ready():
    add_to_group("sabotage_manager")
    
    # Initialize system status
    system_status["power"] = SystemStatus.NORMAL
    system_status["security"] = SystemStatus.NORMAL
    system_status["life_support"] = SystemStatus.NORMAL
    system_status["communication"] = SystemStatus.NORMAL
    
    # Define affected rooms for each sabotage type
    affected_rooms[SabotageEvent.POWER_OUTAGE] = ["Laboratory 3", "Engineering", "Crew Quarters"]
    affected_rooms[SabotageEvent.SECURITY_MALFUNCTION] = ["Security Office", "All Doors"]
    affected_rooms[SabotageEvent.LIFE_SUPPORT_ISSUES] = ["Medical Bay", "All Areas"]
    affected_rooms[SabotageEvent.COMMUNICATION_BLACKOUT] = ["All Terminals", "Ship Connection"]
    
    # Connect to evidence manager
    var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    if evidence_manager:
        evidence_manager.evidence_collected.connect(_on_evidence_collected)
        # Connect to evidence spawned signal to get accurate count
        if evidence_manager.has_signal("evidence_spawned"):
            evidence_manager.connect("evidence_spawned", _on_total_evidence_updated)
        
        # Try to get total evidence count
        if evidence_manager.has_method("get_total_evidence_count"):
            total_evidence = evidence_manager.get_total_evidence_count()
            if total_evidence == 0:
                # If no evidence counted yet, wait and try again
                await get_tree().create_timer(1.0).timeout
                total_evidence = evidence_manager.get_total_evidence_count()
        
        if total_evidence == 0:
            total_evidence = 20  # Default estimate
            print("Sabotage System: Using default evidence count of ", total_evidence)
        else:
            print("Sabotage System: Total evidence count is ", total_evidence)
    
    # Wait for scene to be ready
    await get_tree().process_frame
    
    # Find environment and lights
    _initialize_environment()
    _map_room_lights()
    
    print("Sabotage System Manager: Initialized with ", total_evidence, " total evidence items")

func _initialize_environment():
    var world_env = get_tree().get_first_node_in_group("world_environment")
    if not world_env:
        world_env = get_node_or_null("/root/" + get_tree().current_scene.name + "/WorldEnvironment")
    
    if world_env and world_env is WorldEnvironment:
        environment = world_env.environment
        # Store original environment values
        original_env_values = {
            "ambient_energy": environment.ambient_light_energy,
            "ambient_color": environment.ambient_light_color
        }

func _map_room_lights():
    # Map lights to their respective rooms
    var room_lights_node = get_node_or_null("/root/" + get_tree().current_scene.name + "/RoomLights")
    if not room_lights_node:
        return
    
    # Initialize room arrays
    room_lights["Laboratory 3"] = []
    room_lights["Engineering"] = []
    room_lights["Crew Quarters"] = []
    room_lights["Security Office"] = []
    room_lights["Medical Bay"] = []
    room_lights["Cafeteria"] = []
    
    # Map lights based on their names or positions
    for child in room_lights_node.get_children():
        if child is Light3D:
            # Store original values
            original_light_values[child] = {
                "energy": child.light_energy,
                "color": child.light_color
            }
            
            # Map to rooms based on position or name
            var room_name = _get_room_from_light(child)
            if room_name != "" and room_lights.has(room_name):
                room_lights[room_name].append(child)
    
    print("Sabotage System: Mapped lights to ", room_lights.size(), " rooms")

func _get_room_from_light(light: Light3D) -> String:
    # Map lights to rooms based on position or naming convention
    var light_name = light.name.to_lower()
    var pos = light.global_position
    
    # Check by name first
    if "lab" in light_name or "laboratory" in light_name:
        return "Laboratory 3"
    elif "engineering" in light_name:
        return "Engineering"
    elif "crew" in light_name or "quarters" in light_name:
        return "Crew Quarters"
    elif "security" in light_name:
        return "Security Office"
    elif "medical" in light_name or "med" in light_name:
        return "Medical Bay"
    elif "cafeteria" in light_name:
        return "Cafeteria"
    
    # Fallback to position-based mapping
    # You'll need to adjust these based on your actual room positions
    if pos.x < -10 and pos.z < 0:
        return "Security Office"
    elif pos.x > 10 and pos.z < -5:
        return "Laboratory 3"
    elif pos.z > 20:
        return "Engineering"
    
    return ""

func _on_evidence_collected(_evidence_data):
    collected_evidence += 1
    _update_progress()

func _on_total_evidence_updated(count: int):
    total_evidence = count
    print("Sabotage System: Updated total evidence count to ", total_evidence)
    _update_progress()

func _update_progress():
    if total_evidence == 0:
        print("Sabotage System: Cannot update progress - total evidence is 0")
        return
    
    var old_progress = investigation_progress
    investigation_progress = (float(collected_evidence) / float(total_evidence)) * 100.0
    
    progress_updated.emit(investigation_progress)
    
    print("Sabotage System: Investigation progress: ", investigation_progress, "% (", collected_evidence, "/", total_evidence, " evidence)")
    
    # Check for sabotage triggers
    _check_sabotage_triggers(old_progress, investigation_progress)

func _check_sabotage_triggers(old_progress: float, new_progress: float):
    # Don't trigger new events if a system is currently damaged
    if _has_active_sabotage():
        return
    
    # Check each threshold
    for event in progress_thresholds:
        var threshold = progress_thresholds[event]
        
        # Check if we crossed this threshold
        if old_progress < threshold and new_progress >= threshold:
            if not event in triggered_events:
                _trigger_sabotage(event)

func _trigger_sabotage(event: SabotageEvent):
    if is_transitioning:
        return
    
    # Check if already triggered
    if event in triggered_events:
        print("Sabotage System: Event already triggered: ", SabotageEvent.keys()[event])
        return
    
    triggered_events.append(event)
    is_transitioning = true
    
    print("Sabotage System: Triggering ", SabotageEvent.keys()[event], " at ", investigation_progress, "% progress")
    
    # Get location for this sabotage
    var repair_location = _get_repair_location(event)
    var repair_position = _get_repair_position(event)
    
    # Emit sabotage started signal for Riley to respond
    print("SabotageManager: Emitting sabotage_started signal - Location: ", repair_location, ", Position: ", repair_position)
    sabotage_started.emit(repair_location, repair_position)
    
    # Execute sabotage immediately when warning appears
    match event:
        SabotageEvent.POWER_OUTAGE:
            # Show warning and execute power outage simultaneously
            _show_sabotage_warning(event)
            await _execute_power_outage()
        SabotageEvent.SECURITY_MALFUNCTION:
            _show_sabotage_warning(event)
            await _execute_security_malfunction()
        SabotageEvent.LIFE_SUPPORT_ISSUES:
            _show_sabotage_warning(event)
            await _execute_life_support_issues()
        SabotageEvent.COMMUNICATION_BLACKOUT:
            _show_sabotage_warning(event)
            await _execute_communication_blackout()
    
    is_transitioning = false
    sabotage_triggered.emit(event)
    
    # Notify where repair is needed
    repair_needed.emit(event, repair_location)

func _show_sabotage_warning(event: SabotageEvent):
    var warning_text = ""
    var warning_color = Color(1, 0.8, 0)
    
    match event:
        SabotageEvent.POWER_OUTAGE:
            warning_text = "POWER GRID FAILURE DETECTED\nEmergency lighting activated\nSeveral areas affected"
            warning_color = Color(1, 1, 0)
        SabotageEvent.SECURITY_MALFUNCTION:
            warning_text = "SECURITY SYSTEM MALFUNCTION\nDoor locks compromised\nAccess restrictions lifted"
            warning_color = Color(1, 0.5, 0)
        SabotageEvent.LIFE_SUPPORT_ISSUES:
            warning_text = "LIFE SUPPORT CRITICAL\nOxygen levels dropping\nImmediate repair required"
            warning_color = Color(1, 0, 0)
        SabotageEvent.COMMUNICATION_BLACKOUT:
            warning_text = "COMMUNICATION SYSTEMS OFFLINE\nTerminal access restricted\nExternal contact lost"
            warning_color = Color(0.8, 0, 1)
    
    # Create warning UI
    var warning = Label.new()
    warning.text = warning_text
    warning.add_theme_font_size_override("font_size", 32)
    warning.add_theme_color_override("font_color", warning_color)
    warning.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
    warning.add_theme_constant_override("shadow_offset_x", 2)
    warning.add_theme_constant_override("shadow_offset_y", 2)
    warning.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    
    # Add to UI
    var ui_layer = get_node_or_null("/root/" + get_tree().current_scene.name + "/Player/UILayer")
    if ui_layer:
        ui_layer.add_child(warning)
        
        # Fade in and out
        var tween = create_tween()
        warning.modulate.a = 0
        tween.tween_property(warning, "modulate:a", 1.0, 0.5)
        tween.tween_interval(4.0)  # Show warning for 4 seconds
        tween.tween_property(warning, "modulate:a", 0.0, 1.0)
        tween.tween_callback(warning.queue_free)

func _execute_power_outage():
    # Update system status FIRST
    system_status["power"] = SystemStatus.DAMAGED
    print("Sabotage System: Setting power status to DAMAGED")
    
    # Emit status change IMMEDIATELY
    system_status_changed.emit("power", SystemStatus.DAMAGED)
    
    # Small delay to ensure signal is processed
    await get_tree().process_frame
    
    # Disable doors and terminals IMMEDIATELY
    print("Sabotage System: Disabling doors and terminals NOW")
    _disable_all_doors()
    _disable_all_terminals()
    
    var affected = affected_rooms[SabotageEvent.POWER_OUTAGE]
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Dim lights in affected rooms
    for room_name in affected:
        if room_lights.has(room_name):
            for light in room_lights[room_name]:
                if is_instance_valid(light):
                    tween.tween_property(light, "light_energy", 0.1, transition_duration)
                    tween.tween_property(light, "light_color", Color(0.3, 0.2, 0.2), transition_duration)
    
    # Dim overall environment
    if environment:
        tween.tween_property(environment, "ambient_light_energy", 0.3, transition_duration)
        tween.tween_property(environment, "ambient_light_color", Color(0.4, 0.3, 0.3), transition_duration)
    
    # Create emergency lighting
    await tween.finished
    _create_emergency_lights(affected)
    
    print("Sabotage System: Power outage executed in rooms: ", affected)

func _create_emergency_lights(rooms_to_affect: Array):
    # Add emergency lights only in affected areas
    for room_name in rooms_to_affect:
        var light_pos = _get_room_center(room_name)
        if light_pos != Vector3.ZERO:
            var emergency_light = OmniLight3D.new()
            emergency_light.position = light_pos + Vector3(0, 3, 0)
            emergency_light.light_color = Color(1, 0, 0)
            emergency_light.light_energy = 0
            emergency_light.omni_range = 10
            
            var lights_parent = get_node_or_null("/root/" + get_tree().current_scene.name + "/RoomLights")
            if lights_parent:
                lights_parent.add_child(emergency_light)
                emergency_lights.append(emergency_light)
                
                # Create pulsing effect
                _pulse_emergency_light(emergency_light)

func _pulse_emergency_light(light: OmniLight3D):
    if not is_instance_valid(light):
        return
    
    var tween = create_tween()
    tween.set_loops()
    
    emergency_light_tweens.append(tween)
    light.tree_exited.connect(tween.kill)
    
    tween.tween_property(light, "light_energy", 1.5, 1.0)
    tween.tween_property(light, "light_energy", 0.5, 1.0)

func _get_room_center(room_name: String) -> Vector3:
    # Return approximate room centers
    # Adjust these based on your actual room positions
    match room_name:
        "Laboratory 3":
            return Vector3(15, 0, -10)
        "Engineering":
            return Vector3(0, 0, 30)
        "Crew Quarters":
            return Vector3(-15, 0, 10)
        "Security Office":
            return Vector3(-10, 0, -5)
        "Medical Bay":
            return Vector3(10, 0, 5)
        "Cafeteria":
            return Vector3(0, 0, 0)
    return Vector3.ZERO

func _disable_terminals_in_rooms(room_names: Array):
    # Find and disable computer terminals in specific rooms
    var terminals = get_tree().get_nodes_in_group("computer_terminal")
    
    for terminal in terminals:
        # Check if terminal is in affected room
        if terminal.has_method("get_room_name") and terminal.has_method("disable"):
            var terminal_room = terminal.get_room_name()
            if terminal_room in room_names:
                terminal.disable()
                disabled_terminals.append(terminal)
                print("Sabotage System: Disabled terminal in ", terminal_room, ": ", terminal.name)

func _disable_all_terminals():
    # Disable ALL terminals during power outage
    var terminals = get_tree().get_nodes_in_group("computer_terminal")
    print("Sabotage System: Disabling all ", terminals.size(), " terminals due to station-wide power outage")
    
    for terminal in terminals:
        if terminal.has_method("disable"):
            terminal.disable()
            disabled_terminals.append(terminal)
            print("Sabotage System: Disabled terminal: ", terminal.name)

func _disable_doors_in_rooms(room_names: Array):
    # Find and disable automatic doors in specific rooms
    var doors = get_tree().get_nodes_in_group("powered_doors")
    print("Sabotage System: Found ", doors.size(), " powered doors")
    
    for door in doors:
        # Check if door is in affected room
        if door.has_method("get_room_name") and door.has_method("set_powered"):
            var door_room = door.get_room_name()
            print("Sabotage System: Door ", door.name, " is in room: ", door_room)
            if door_room in room_names:
                door.set_powered(false)
                print("Sabotage System: Disabled automatic door in ", door_room, ": ", door.name)
            else:
                print("Sabotage System: Door ", door.name, " not in affected rooms")
        else:
            print("Sabotage System: Door ", door.name, " missing required methods")

func _disable_all_doors():
    # Disable ALL automatic doors during power outage
    var doors = get_tree().get_nodes_in_group("powered_doors")
    print("Sabotage System: Found ", doors.size(), " doors in powered_doors group")
    
    # Also try to find all SlidingDoor nodes in case they're not in the group
    var all_nodes = get_tree().get_nodes_in_group("interactable")
    for node in all_nodes:
        if node.has_method("set_powered") and node.get_script() and node.get_script().resource_path.contains("sliding_door"):
            if not node in doors:
                doors.append(node)
                print("Sabotage System: Found additional door not in group: ", node.name)
    
    print("Sabotage System: Disabling all ", doors.size(), " doors due to station-wide power outage")
    
    for door in doors:
        if door.has_method("set_powered"):
            door.set_powered(false)
            print("Sabotage System: Disabled door: ", door.name)

func _get_repair_location(event: SabotageEvent) -> String:
    match event:
        SabotageEvent.POWER_OUTAGE:
            return "Engineering - Power Grid Control Panel"
        SabotageEvent.SECURITY_MALFUNCTION:
            return "Security Office - Main Security Console"
        SabotageEvent.LIFE_SUPPORT_ISSUES:
            return "Medical Bay - Life Support Controls"
        SabotageEvent.COMMUNICATION_BLACKOUT:
            return "Engineering - Communication Array"
    return ""

func _get_repair_position(event: SabotageEvent) -> Vector3:
    # Return approximate positions for each repair location
    match event:
        SabotageEvent.POWER_OUTAGE:
            return Vector3(7, 1.0, -10)  # Engineering room
        SabotageEvent.SECURITY_MALFUNCTION:
            return Vector3(-7, 1.0, -5)  # Security office
        SabotageEvent.LIFE_SUPPORT_ISSUES:
            return Vector3(7, 1.0, 5)    # Medical bay
        SabotageEvent.COMMUNICATION_BLACKOUT:
            return Vector3(7, 1.0, -10)  # Engineering room
    return Vector3.ZERO

func repair_system(event: SabotageEvent):
    match event:
        SabotageEvent.POWER_OUTAGE:
            _repair_power_outage()
        SabotageEvent.SECURITY_MALFUNCTION:
            _repair_security_malfunction()
        SabotageEvent.LIFE_SUPPORT_ISSUES:
            _repair_life_support()
        SabotageEvent.COMMUNICATION_BLACKOUT:
            _repair_communications()
    
    sabotage_resolved.emit(event)
    sabotage_ended.emit()

func _repair_power_outage():
    system_status["power"] = SystemStatus.REPAIRING
    system_status_changed.emit("power", SystemStatus.REPAIRING)
    
    var affected = affected_rooms[SabotageEvent.POWER_OUTAGE]
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Restore lights in affected rooms
    for room_name in affected:
        if room_lights.has(room_name):
            for light in room_lights[room_name]:
                if is_instance_valid(light) and original_light_values.has(light):
                    var original = original_light_values[light]
                    tween.tween_property(light, "light_energy", original.energy, transition_duration)
                    tween.tween_property(light, "light_color", original.color, transition_duration)
    
    # Restore environment
    if environment and original_env_values.size() > 0:
        tween.tween_property(environment, "ambient_light_energy", original_env_values.ambient_energy, transition_duration)
        tween.tween_property(environment, "ambient_light_color", original_env_values.ambient_color, transition_duration)
    
    # Remove emergency lights
    for light in emergency_lights:
        if is_instance_valid(light):
            tween.tween_property(light, "light_energy", 0, transition_duration * 0.5)
    
    tween.set_parallel(false)
    tween.tween_callback(_on_power_repair_complete)

func _on_power_repair_complete():
    # Clean up emergency lights
    for tween in emergency_light_tweens:
        if is_instance_valid(tween):
            tween.kill()
    emergency_light_tweens.clear()
    
    for light in emergency_lights:
        if is_instance_valid(light):
            light.queue_free()
    emergency_lights.clear()
    
    # Re-enable terminals
    for terminal in disabled_terminals:
        if is_instance_valid(terminal) and terminal.has_method("enable"):
            terminal.enable()
    disabled_terminals.clear()
    
    # Re-enable ALL doors after power restoration
    var doors = get_tree().get_nodes_in_group("powered_doors")
    print("Sabotage System: Re-enabling all ", doors.size(), " doors after power restoration")
    for door in doors:
        if door.has_method("set_powered"):
            door.set_powered(true)
    
    system_status["power"] = SystemStatus.NORMAL
    system_status_changed.emit("power", SystemStatus.NORMAL)
    
    print("Sabotage System: Power restored")

func _execute_security_malfunction():
    # To be implemented
    system_status["security"] = SystemStatus.DAMAGED
    system_status_changed.emit("security", SystemStatus.DAMAGED)

func _execute_life_support_issues():
    # To be implemented
    system_status["life_support"] = SystemStatus.DAMAGED
    system_status_changed.emit("life_support", SystemStatus.DAMAGED)

func _execute_communication_blackout():
    # To be implemented
    system_status["communication"] = SystemStatus.DAMAGED
    system_status_changed.emit("communication", SystemStatus.DAMAGED)

func _repair_security_malfunction():
    system_status["security"] = SystemStatus.NORMAL
    system_status_changed.emit("security", SystemStatus.NORMAL)

func _repair_life_support():
    system_status["life_support"] = SystemStatus.NORMAL
    system_status_changed.emit("life_support", SystemStatus.NORMAL)

func _repair_communications():
    system_status["communication"] = SystemStatus.NORMAL
    system_status_changed.emit("communication", SystemStatus.NORMAL)

func get_investigation_progress() -> float:
    return investigation_progress

func get_system_status(system: String) -> SystemStatus:
    return system_status.get(system, SystemStatus.NORMAL)

func is_system_damaged(system: String) -> bool:
    return get_system_status(system) == SystemStatus.DAMAGED

func get_active_sabotages() -> Array[SabotageEvent]:
    var active = []
    for event in triggered_events:
        var system_key = _get_system_key_for_event(event)
        if is_system_damaged(system_key):
            active.append(event)
    return active

func _has_active_sabotage() -> bool:
    # Check if any system is currently damaged
    for system in system_status:
        if system_status[system] == SystemStatus.DAMAGED or system_status[system] == SystemStatus.REPAIRING:
            return true
    return false

func _get_system_key_for_event(event: SabotageEvent) -> String:
    match event:
        SabotageEvent.POWER_OUTAGE:
            return "power"
        SabotageEvent.SECURITY_MALFUNCTION:
            return "security"
        SabotageEvent.LIFE_SUPPORT_ISSUES:
            return "life_support"
        SabotageEvent.COMMUNICATION_BLACKOUT:
            return "communication"
    return ""
