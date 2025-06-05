extends Node
class_name DayNightManager

enum TimeOfDay {
    DAY,
    NIGHT
}

@export var evidence_threshold: int = 6  # Evidence pieces before night
@export var transition_duration: float = 3.0  # Time to transition between day/night

# Store state in a static variable to persist across scene changes
static var _persistent_time_state: TimeOfDay = TimeOfDay.DAY
static var _persistent_evidence_count: int = 0

var current_time: TimeOfDay = TimeOfDay.DAY
var evidence_collected: int = 0
var is_transitioning: bool = false

# Lighting references
var main_lights: Array[Light3D] = []
var emergency_lights: Array[Light3D] = []
var emergency_light_tweens: Array[Tween] = []
var environment: Environment

# Original light values for restoration
var original_light_values: Dictionary = {}

signal day_started()
signal night_started()
signal transition_started(to_night: bool)
signal transition_completed(to_night: bool)

func _ready():
    add_to_group("day_night_manager")
    
    # Restore persistent state
    current_time = _persistent_time_state
    evidence_collected = _persistent_evidence_count
    
    print("Day/Night Manager: Initialized, current state = ", TimeOfDay.keys()[current_time], " mode, evidence = ", evidence_collected)
    
    # Connect to evidence manager
    var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    if evidence_manager:
        evidence_manager.evidence_collected.connect(_on_evidence_collected)
    
    # Wait for scene to be ready
    await get_tree().process_frame
    
    # Find all lights in the scene
    _find_lights()
    
    # Find environment
    var world_env = get_tree().get_first_node_in_group("world_environment")
    if not world_env:
        world_env = get_node_or_null("/root/" + get_tree().current_scene.name + "/WorldEnvironment")
    if world_env and world_env is WorldEnvironment:
        environment = world_env.environment
    
    # If we're in night mode, apply night settings immediately
    if current_time == TimeOfDay.NIGHT:
        print("Day/Night Manager: Restoring night mode settings")
        await get_tree().process_frame
        _apply_night_settings_instant()

func _find_lights():
    # Find all lights in the RoomLights node
    var room_lights = get_node_or_null("/root/" + get_tree().current_scene.name + "/RoomLights")
    if room_lights:
        for child in room_lights.get_children():
            if child is Light3D:
                main_lights.append(child)
                # Store original values
                original_light_values[child] = {
                    "energy": child.light_energy,
                    "color": child.light_color
                }
    
    # Find the main directional light
    var main_light = get_node_or_null("/root/" + get_tree().current_scene.name + "/Lighting/MainLight")
    if main_light and main_light is DirectionalLight3D:
        main_lights.append(main_light)
        original_light_values[main_light] = {
            "energy": main_light.light_energy,
            "color": main_light.light_color
        }
    
    print("Day/Night Manager: Found ", main_lights.size(), " lights")

func _on_evidence_collected(_evidence_data):
    if current_time == TimeOfDay.DAY:
        evidence_collected += 1
        _persistent_evidence_count = evidence_collected  # Update persistent state
        print("Day/Night Manager: Evidence collected (", evidence_collected, "/", evidence_threshold, ")")
        
        if evidence_collected >= evidence_threshold and not is_transitioning:
            trigger_night_cycle()

func trigger_night_cycle():
    print("Day/Night Manager: trigger_night_cycle called, current_time=", TimeOfDay.keys()[current_time], ", is_transitioning=", is_transitioning)
    
    if is_transitioning:
        print("Day/Night Manager: Already transitioning, ignoring trigger")
        return
    
    if current_time == TimeOfDay.NIGHT:
        print("Day/Night Manager: Already in night mode")
        # Force Riley activation anyway for testing
        _activate_riley_night_mode()
        # Also check Riley's current state
        var riley = get_tree().get_first_node_in_group("riley_patrol")
        if riley:
            var state_text = "unknown"
            if "current_state" in riley:
                # Get state name from the enum
                match riley.current_state:
                    0: state_text = "PATROLLING"
                    1: state_text = "WAITING"
                    2: state_text = "INVESTIGATING"
                    3: state_text = "CHASING"
                    4: state_text = "SEARCHING"
                    _: state_text = str(riley.current_state)
            print("Day/Night Manager: Riley patrol AI found, state=", state_text)
        return
    
    print("Day/Night Manager: Triggering night cycle!")
    is_transitioning = true
    transition_started.emit(true)
    
    # Show warning to player
    _show_night_warning()
    
    # Wait a bit for warning
    await get_tree().create_timer(2.0).timeout
    
    # Transition to night
    _transition_to_night()

func _activate_riley_night_mode():
    print("Day/Night Manager: Activating Riley's night mode directly")
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("Day/Night Manager: Found ", npcs.size(), " NPCs in group")
    
    var found_riley = false
    for npc in npcs:
        print("Day/Night Manager: Checking NPC: ", npc.name, ", npc_name=", npc.get("npc_name") if "npc_name" in npc else "no npc_name")
        if "npc_name" in npc and npc.npc_name == "Riley Kim":
            found_riley = true
            if npc.has_method("on_night_cycle_started"):
                print("Day/Night Manager: Found Riley, activating patrol mode")
                npc.on_night_cycle_started()
                # Also check if Riley has patrol AI child
                var patrol_ai = npc.get_node_or_null("RileyPatrolAI")
                if patrol_ai:
                    var state_text = "unknown"
                    if "current_state" in patrol_ai:
                        match patrol_ai.current_state:
                            0: state_text = "PATROLLING"
                            1: state_text = "WAITING"
                            2: state_text = "INVESTIGATING"
                            3: state_text = "CHASING"
                            4: state_text = "SEARCHING"
                            _: state_text = str(patrol_ai.current_state)
                    print("Day/Night Manager: Riley has patrol AI, current state=", state_text)
                else:
                    print("Day/Night Manager: WARNING - Riley missing RileyPatrolAI child node!")
            else:
                print("Day/Night Manager: WARNING - Riley missing on_night_cycle_started method!")
            break
    
    if not found_riley:
        print("Day/Night Manager: ERROR - Riley Kim not found in NPCs group!")

func _show_night_warning():
    # Create warning UI
    var warning = Label.new()
    warning.text = "STATION ENTERING NIGHT CYCLE\nEmergency lighting activated\nBe careful..."
    warning.add_theme_font_size_override("font_size", 32)
    warning.add_theme_color_override("font_color", Color(1, 0.8, 0))
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
        tween.tween_interval(3.0)
        tween.tween_property(warning, "modulate:a", 0.0, 1.0)
        tween.tween_callback(warning.queue_free)

func _transition_to_night():
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Dim main lights
    for light in main_lights:
        if light is OmniLight3D:
            # Room lights become very dim
            tween.tween_property(light, "light_energy", 0.3, transition_duration)
            tween.tween_property(light, "light_color", Color(0.5, 0.3, 0.3), transition_duration)
        elif light is DirectionalLight3D:
            # Main light becomes very dim
            tween.tween_property(light, "light_energy", 0.2, transition_duration)
            tween.tween_property(light, "light_color", Color(0.3, 0.3, 0.5), transition_duration)
    
    # Adjust environment
    if environment:
        tween.tween_property(environment, "ambient_light_energy", 0.5, transition_duration)
        tween.tween_property(environment, "ambient_light_color", Color(0.3, 0.3, 0.4), transition_duration)
    
    # Add red emergency light effect
    _create_emergency_lights()
    
    tween.set_parallel(false)
    tween.tween_callback(_on_night_transition_complete)

func _create_emergency_lights():
    # Add pulsing red emergency lights in key locations
    var emergency_positions = [
        Vector3(0, 3, 0),      # Main hallway
        Vector3(-7, 3, -5),    # Security office
        Vector3(7, 3, -10),    # Research lab
        Vector3(0, 3, 30)      # Docking bay
    ]
    
    for pos in emergency_positions:
        var emergency_light = OmniLight3D.new()
        emergency_light.position = pos
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
    
    # Store tween reference for cleanup
    emergency_light_tweens.append(tween)
    
    # Stop the tween if the light is freed
    light.tree_exited.connect(tween.kill)
    
    tween.tween_property(light, "light_energy", 1.5, 1.0)
    tween.tween_property(light, "light_energy", 0.5, 1.0)

func _on_night_transition_complete():
    current_time = TimeOfDay.NIGHT
    _persistent_time_state = TimeOfDay.NIGHT  # Update persistent state
    is_transitioning = false
    transition_completed.emit(true)
    night_started.emit()
    
    # Notify NPCs to change behavior
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if npc.has_method("on_night_cycle_started"):
            npc.on_night_cycle_started()
    
    print("Day/Night Manager: Night cycle active!")

func force_day_cycle():
    print("Day/Night Manager: force_day_cycle called, current_time=", TimeOfDay.keys()[current_time])
    print("Stack trace: ", get_stack())
    
    if is_transitioning or current_time == TimeOfDay.DAY:
        return
    
    is_transitioning = true
    transition_started.emit(false)
    
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Restore original lighting
    for light in main_lights:
        if original_light_values.has(light):
            var original = original_light_values[light]
            tween.tween_property(light, "light_energy", original.energy, transition_duration)
            tween.tween_property(light, "light_color", original.color, transition_duration)
    
    # Restore environment
    if environment:
        tween.tween_property(environment, "ambient_light_energy", 2.5, transition_duration)
        tween.tween_property(environment, "ambient_light_color", Color(1, 1, 1), transition_duration)
    
    # Fade out emergency lights
    for light in emergency_lights:
        if is_instance_valid(light):
            tween.tween_property(light, "light_energy", 0, transition_duration * 0.5)
    
    tween.set_parallel(false)
    tween.tween_callback(_on_day_transition_complete)

func _on_day_transition_complete():
    # Kill all emergency light tweens first
    for tween in emergency_light_tweens:
        if is_instance_valid(tween):
            tween.kill()
    emergency_light_tweens.clear()
    
    # Clean up emergency lights
    for light in emergency_lights:
        if is_instance_valid(light):
            light.queue_free()
    emergency_lights.clear()
    
    current_time = TimeOfDay.DAY
    _persistent_time_state = TimeOfDay.DAY  # Update persistent state
    is_transitioning = false
    transition_completed.emit(false)
    day_started.emit()
    
    # Notify NPCs to restore normal behavior
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if npc.has_method("on_day_cycle_started"):
            npc.on_day_cycle_started()
    
    print("Day/Night Manager: Day cycle restored")

func is_night_time() -> bool:
    return current_time == TimeOfDay.NIGHT

func is_day_time() -> bool:
    return current_time == TimeOfDay.DAY

func get_evidence_progress() -> float:
    return float(evidence_collected) / float(evidence_threshold)

func _apply_night_settings_instant():
    # Apply night lighting instantly (for scene reloads)
    for light in main_lights:
        if light is OmniLight3D:
            light.light_energy = 0.3
            light.light_color = Color(0.5, 0.3, 0.3)
        elif light is DirectionalLight3D:
            light.light_energy = 0.2
            light.light_color = Color(0.3, 0.3, 0.5)
    
    if environment:
        environment.ambient_light_energy = 0.5
        environment.ambient_light_color = Color(0.3, 0.3, 0.4)
    
    # Create emergency lights
    _create_emergency_lights()
    
    # Notify NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if npc.has_method("on_night_cycle_started"):
            npc.on_night_cycle_started()
