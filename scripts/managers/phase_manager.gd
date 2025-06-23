extends Node
class_name PhaseManager

# Game phases for survival horror progression
enum Phase {
    ARRIVAL,              # Initial investigation, safe environment
    ESCALATING_TENSION,   # First signs of danger, system malfunctions
    ACTIVE_THREAT,        # Saboteur actively hunting, major failures
    CRITICAL_DISCOVERY,   # Uncovering the truth, extreme danger
    DESPERATE_ESCAPE      # Station failing, must escape
}

@export var current_phase: Phase = Phase.ARRIVAL
@export var phase_durations: Dictionary = {
    Phase.ARRIVAL: 300.0,           # 5 minutes
    Phase.ESCALATING_TENSION: 420.0, # 7 minutes
    Phase.ACTIVE_THREAT: 600.0,      # 10 minutes
    Phase.CRITICAL_DISCOVERY: 480.0,  # 8 minutes
    Phase.DESPERATE_ESCAPE: 300.0     # 5 minutes (time limit)
}

# Phase progression triggers
@export var evidence_per_phase: Dictionary = {
    Phase.ARRIVAL: 3,
    Phase.ESCALATING_TENSION: 6,
    Phase.ACTIVE_THREAT: 9,
    Phase.CRITICAL_DISCOVERY: 12,
    Phase.DESPERATE_ESCAPE: 15
}

var phase_timer: float = 0.0
var evidence_collected: int = 0
var phase_locked: bool = false  # Prevents automatic progression
var escape_timer: float = 0.0
var escape_time_limit: float = 300.0  # 5 minutes to escape

# Saboteur selection
var selected_saboteur: NPCBase = null
var saboteur_candidates: Array[NPCBase] = []

# Environmental threat levels per phase
var threat_levels: Dictionary = {
    Phase.ARRIVAL: {
        "power_failure_chance": 0.0,
        "door_malfunction_chance": 0.0,
        "oxygen_leak_chance": 0.0,
        "saboteur_active": false,
        "npc_paranoia_level": 0.0
    },
    Phase.ESCALATING_TENSION: {
        "power_failure_chance": 0.1,
        "door_malfunction_chance": 0.05,
        "oxygen_leak_chance": 0.0,
        "saboteur_active": false,
        "npc_paranoia_level": 0.2
    },
    Phase.ACTIVE_THREAT: {
        "power_failure_chance": 0.3,
        "door_malfunction_chance": 0.15,
        "oxygen_leak_chance": 0.1,
        "saboteur_active": true,
        "npc_paranoia_level": 0.5
    },
    Phase.CRITICAL_DISCOVERY: {
        "power_failure_chance": 0.5,
        "door_malfunction_chance": 0.25,
        "oxygen_leak_chance": 0.2,
        "saboteur_active": true,
        "npc_paranoia_level": 0.8
    },
    Phase.DESPERATE_ESCAPE: {
        "power_failure_chance": 0.7,
        "door_malfunction_chance": 0.4,
        "oxygen_leak_chance": 0.4,
        "saboteur_active": true,
        "npc_paranoia_level": 1.0
    }
}

signal phase_changed(new_phase: Phase, old_phase: Phase)
signal escape_timer_updated(time_remaining: float)
signal critical_event_triggered(event_type: String)
signal environmental_threat(threat_type: String, location: Vector3)

func _ready():
    add_to_group("phase_manager")
    set_process(true)
    
    # Connect to evidence manager
    var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    if evidence_manager:
        evidence_manager.evidence_collected.connect(_on_evidence_collected)
    
    # Find all potential saboteur candidates
    _find_saboteur_candidates()
    
    print("PhaseManager: Initialized - Starting phase: ", Phase.keys()[current_phase])
    _apply_phase_settings()

func _process(delta):
    # Update phase timer
    phase_timer += delta
    
    # Check for automatic phase progression (time-based)
    if not phase_locked and phase_timer >= phase_durations.get(current_phase, 300.0):
        _try_advance_phase()
    
    # Update escape timer if in escape phase
    if current_phase == Phase.DESPERATE_ESCAPE:
        escape_timer += delta
        var time_remaining = escape_time_limit - escape_timer
        escape_timer_updated.emit(time_remaining)
        
        if time_remaining <= 0:
            _trigger_station_destruction()
    
    # Random environmental events based on phase
    _check_environmental_threats(delta)

func _try_advance_phase():
    if current_phase < Phase.DESPERATE_ESCAPE:
        advance_to_next_phase()

func advance_to_next_phase():
    var old_phase = current_phase
    current_phase = Phase.values()[current_phase + 1]
    phase_timer = 0.0
    
    print("PhaseManager: Advancing from ", Phase.keys()[old_phase], " to ", Phase.keys()[current_phase])
    
    _apply_phase_settings()
    phase_changed.emit(current_phase, old_phase)
    
    # Special handling for escape phase
    if current_phase == Phase.DESPERATE_ESCAPE:
        _start_escape_sequence()

func force_phase(new_phase: Phase):
    var old_phase = current_phase
    current_phase = new_phase
    phase_timer = 0.0
    
    print("PhaseManager: Forcing phase change to ", Phase.keys()[new_phase])
    
    _apply_phase_settings()
    phase_changed.emit(current_phase, old_phase)

func _apply_phase_settings():
    var settings = threat_levels.get(current_phase, {})
    
    # Update lighting
    _update_station_lighting()
    
    # Update saboteur AI
    if settings.get("saboteur_active", false):
        _activate_saboteur()
    else:
        _deactivate_saboteur()
    
    # Update NPC behavior
    _update_npc_paranoia(settings.get("npc_paranoia_level", 0.0))
    
    # Trigger phase-specific events
    match current_phase:
        Phase.ARRIVAL:
            critical_event_triggered.emit("investigation_started")
        Phase.ESCALATING_TENSION:
            critical_event_triggered.emit("systems_unstable")
        Phase.ACTIVE_THREAT:
            critical_event_triggered.emit("saboteur_hunting")
        Phase.CRITICAL_DISCOVERY:
            critical_event_triggered.emit("truth_revealed")
        Phase.DESPERATE_ESCAPE:
            critical_event_triggered.emit("station_critical")

func _update_station_lighting():
    var room_lights = get_tree().get_nodes_in_group("room_lights")
    
    match current_phase:
        Phase.ARRIVAL:
            # Normal lighting
            for light in room_lights:
                light.light_energy = 2.0
                light.light_color = Color.WHITE
        
        Phase.ESCALATING_TENSION:
            # Slightly dimmer, occasional flicker
            for light in room_lights:
                light.light_energy = 1.5
                light.light_color = Color(0.9, 0.9, 1.0)
        
        Phase.ACTIVE_THREAT:
            # Emergency lighting
            for light in room_lights:
                light.light_energy = 1.0
                light.light_color = Color(1.0, 0.8, 0.8)
        
        Phase.CRITICAL_DISCOVERY:
            # Failing systems, red alerts
            for light in room_lights:
                light.light_energy = 0.8
                light.light_color = Color(1.0, 0.5, 0.5)
        
        Phase.DESPERATE_ESCAPE:
            # Critical failure lighting
            for light in room_lights:
                light.light_energy = 0.5
                light.light_color = Color(1.0, 0.2, 0.2)

func _activate_saboteur():
    # First select a saboteur if not already selected
    if selected_saboteur == null:
        _select_random_saboteur()
    
    if selected_saboteur == null:
        push_warning("PhaseManager: Cannot activate - no saboteur available")
        return
    
    var saboteur_ai = selected_saboteur.get_node_or_null("SaboteurPatrolAI")
    if saboteur_ai and saboteur_ai.has_method("set_active"):
        saboteur_ai.set_active(true)
        print("PhaseManager: Saboteur AI activated for ", selected_saboteur.npc_name)

func _deactivate_saboteur():
    if selected_saboteur == null:
        return
        
    var saboteur_ai = selected_saboteur.get_node_or_null("SaboteurPatrolAI")
    if saboteur_ai and saboteur_ai.has_method("set_active"):
        saboteur_ai.set_active(false)
        print("PhaseManager: Saboteur AI deactivated")

func _update_npc_paranoia(level: float):
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if npc.has_method("set_paranoia_level"):
            npc.set_paranoia_level(level)

func _check_environmental_threats(delta):
    var settings = threat_levels.get(current_phase, {})
    
    # Random chance for various threats (checked every 5 seconds)
    if int(phase_timer) % 5 == 0 and randf() < delta:
        # Power failures
        if randf() < settings.get("power_failure_chance", 0.0):
            _trigger_power_failure()
        
        # Door malfunctions
        if randf() < settings.get("door_malfunction_chance", 0.0):
            _trigger_door_malfunction()
        
        # Oxygen leaks
        if randf() < settings.get("oxygen_leak_chance", 0.0):
            _trigger_oxygen_leak()

func _trigger_power_failure():
    var rooms = ["lab3", "medical", "security", "engineering", "quarters", "cafeteria"]
    var affected_room = rooms[randi() % rooms.size()]
    
    environmental_threat.emit("power_failure", Vector3.ZERO)
    print("PhaseManager: Power failure in ", affected_room)
    
    # TODO: Implement actual power failure mechanics

func _trigger_door_malfunction():
    environmental_threat.emit("door_malfunction", Vector3.ZERO)
    print("PhaseManager: Door malfunction triggered")
    
    # TODO: Lock random doors

func _trigger_oxygen_leak():
    environmental_threat.emit("oxygen_leak", Vector3.ZERO)
    print("PhaseManager: Oxygen leak detected")
    
    # TODO: Create oxygen hazard zone

func _start_escape_sequence():
    escape_timer = 0.0
    critical_event_triggered.emit("escape_sequence_started")
    
    # Open escape routes
    var escape_routes = get_tree().get_nodes_in_group("escape_routes")
    for route in escape_routes:
        if route.has_method("activate"):
            route.activate()
    
    print("PhaseManager: ESCAPE SEQUENCE INITIATED - ", escape_time_limit, " seconds to escape!")

func _trigger_station_destruction():
    critical_event_triggered.emit("station_destroyed")
    print("PhaseManager: STATION DESTROYED - Game Over")
    
    # TODO: Trigger game over screen

func _on_evidence_collected(evidence):
    evidence_collected += 1
    
    # Check if we should advance phase based on evidence
    var required_evidence = evidence_per_phase.get(current_phase, 999)
    if evidence_collected >= required_evidence and not phase_locked:
        print("PhaseManager: Evidence threshold reached (", evidence_collected, "/", required_evidence, ")")
        _try_advance_phase()

func get_current_threat_level() -> Dictionary:
    return threat_levels.get(current_phase, {})

func is_saboteur_active() -> bool:
    return threat_levels.get(current_phase, {}).get("saboteur_active", false)

func lock_phase(locked: bool):
    phase_locked = locked
    print("PhaseManager: Phase progression ", "locked" if locked else "unlocked")

func get_phase_name() -> String:
    return Phase.keys()[current_phase]

func get_time_in_phase() -> float:
    return phase_timer

func get_escape_time_remaining() -> float:
    if current_phase == Phase.DESPERATE_ESCAPE:
        return max(0.0, escape_time_limit - escape_timer)
    return -1.0

func _find_saboteur_candidates():
    """Find all NPCs that can potentially be the saboteur"""
    saboteur_candidates.clear()
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc is NPCBase and npc.can_be_saboteur:
            saboteur_candidates.append(npc)
            print("PhaseManager: Found saboteur candidate - ", npc.npc_name)
    
    print("PhaseManager: Total saboteur candidates: ", saboteur_candidates.size())

func _select_random_saboteur():
    """Randomly select one NPC to be the saboteur"""
    if saboteur_candidates.is_empty():
        push_warning("PhaseManager: No saboteur candidates available!")
        return
    
    # If saboteur already selected, don't reselect
    if selected_saboteur != null:
        return
    
    # Randomly pick one candidate
    var index = randi() % saboteur_candidates.size()
    selected_saboteur = saboteur_candidates[index]
    
    print("PhaseManager: Selected saboteur - ", selected_saboteur.npc_name)
    
    # Attach saboteur AI components to the selected NPC
    _attach_saboteur_components(selected_saboteur)

func _attach_saboteur_components(npc: NPCBase):
    """Attach saboteur AI and character mode components to the selected NPC"""
    # Check if components already exist
    if npc.has_node("SaboteurPatrolAI"):
        return
    
    # Create and attach SaboteurPatrolAI
    var patrol_ai = preload("res://scripts/npcs/saboteur_patrol_ai.gd").new()
    patrol_ai.name = "SaboteurPatrolAI"
    npc.add_child(patrol_ai)
    patrol_ai.add_to_group("saboteur_ai")
    
    # Create and attach SaboteurCharacterModes
    var char_modes = preload("res://scripts/npcs/saboteur_character_modes.gd").new()
    char_modes.name = "SaboteurCharacterModes"
    npc.add_child(char_modes)
    
    print("PhaseManager: Attached saboteur components to ", npc.npc_name)

func activate_saboteur_manually():
    """Manually activate the saboteur (for debug purposes)"""
    if selected_saboteur == null:
        _select_random_saboteur()
    
    if selected_saboteur == null:
        push_warning("PhaseManager: Cannot activate - no saboteur selected")
        return
    
    # Activate the saboteur AI
    var saboteur_ai = selected_saboteur.get_node_or_null("SaboteurPatrolAI")
    if saboteur_ai and saboteur_ai.has_method("set_active"):
        saboteur_ai.set_active(true)
        print("PhaseManager: Manually activated saboteur - ", selected_saboteur.npc_name)
        
        # Update debug visualizations based on current UI settings
        var debug_ui = get_tree().get_first_node_in_group("schedule_debug_ui")
        if debug_ui and debug_ui.has_method("_update_saboteur_visualization"):
            debug_ui._update_saboteur_visualization()
    
    # Transform to saboteur mode
    var char_modes = selected_saboteur.get_node_or_null("SaboteurCharacterModes")
    if char_modes and char_modes.has_method("switch_to_saboteur_mode"):
        char_modes.switch_to_saboteur_mode()

func deactivate_saboteur_manually():
    """Manually deactivate the saboteur (for debug purposes)"""
    if selected_saboteur == null:
        return
    
    # Deactivate the saboteur AI
    var saboteur_ai = selected_saboteur.get_node_or_null("SaboteurPatrolAI")
    if saboteur_ai and saboteur_ai.has_method("set_active"):
        saboteur_ai.set_active(false)
        print("PhaseManager: Manually deactivated saboteur")
    
    # Transform back to normal mode
    var char_modes = selected_saboteur.get_node_or_null("SaboteurCharacterModes")
    if char_modes and char_modes.has_method("switch_to_normal_mode"):
        char_modes.switch_to_normal_mode()

func get_current_saboteur() -> NPCBase:
    """Get the currently selected saboteur NPC"""
    return selected_saboteur
