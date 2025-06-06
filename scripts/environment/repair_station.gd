extends StaticBody3D
class_name RepairStation

enum RepairType {
    POWER_GRID,
    SECURITY_SYSTEM,
    LIFE_SUPPORT,
    COMMUNICATIONS
}

@export var repair_type: RepairType = RepairType.POWER_GRID
@export var station_name: String = "Repair Station"
@export var is_damaged: bool = false

var repair_ui_scenes: Dictionary = {
    RepairType.POWER_GRID: "res://scenes/ui/power_grid_repair_ui.tscn",
    RepairType.SECURITY_SYSTEM: "",  # TODO: Create security repair UI
    RepairType.LIFE_SUPPORT: "",      # TODO: Create life support repair UI
    RepairType.COMMUNICATIONS: ""     # TODO: Create communications repair UI
}

signal repair_completed(repair_type: RepairType)
signal repair_started(repair_type: RepairType)

func _ready():
    add_to_group("interactable")
    add_to_group("repair_station")
    collision_layer = 2
    
    # Connect to sabotage manager
    await get_tree().process_frame
    var sabotage_manager = get_tree().get_first_node_in_group("sabotage_manager")
    if sabotage_manager:
        sabotage_manager.sabotage_triggered.connect(_on_sabotage_triggered)
        sabotage_manager.sabotage_resolved.connect(_on_sabotage_resolved)
        print("Repair Station connected to sabotage manager")
        
        # Check if power is already damaged
        if sabotage_manager.is_system_damaged("power"):
            print("Power already damaged, activating repair station")
            is_damaged = true
            _update_visual_state(true)
    else:
        print("Repair Station WARNING: No sabotage manager found!")
    
    # DEBUG: Allow manual activation with T key
    set_process_input(true)

func get_interaction_prompt() -> String:
    if not is_damaged:
        return ""
    
    match repair_type:
        RepairType.POWER_GRID:
            return "Press [E] to repair Power Grid"
        RepairType.SECURITY_SYSTEM:
            return "Press [E] to repair Security System"
        RepairType.LIFE_SUPPORT:
            return "Press [E] to repair Life Support"
        RepairType.COMMUNICATIONS:
            return "Press [E] to repair Communications"
    
    return "Press [E] to repair " + station_name

func interact(_player = null):
    print("Repair station interact called, damaged: ", is_damaged)
    if not is_damaged:
        print("System is functioning normally")
        return
    
    # Check if we have a repair UI for this type
    var ui_path = repair_ui_scenes.get(repair_type, "")
    print("Looking for repair UI at: ", ui_path)
    if ui_path == "" or not ResourceLoader.exists(ui_path):
        print("Repair interface not found at path: ", ui_path)
        print("Completing repair instantly...")
        # For now, just complete the repair instantly
        _complete_repair()
        return
    
    # Show repair UI
    repair_started.emit(repair_type)
    print("Loading repair UI scene...")
    
    var repair_ui_scene = load(ui_path)
    if repair_ui_scene:
        print("Repair UI scene loaded successfully")
        var repair_ui = repair_ui_scene.instantiate()
        var ui_layer = get_node_or_null("/root/" + get_tree().current_scene.name + "/Player/UILayer")
        print("UI Layer found: ", ui_layer != null)
        if ui_layer:
            ui_layer.add_child(repair_ui)
            print("Repair UI added to scene")
            
            # Connect signals
            if repair_ui.has_signal("repair_completed"):
                repair_ui.repair_completed.connect(_on_repair_ui_completed)
            if repair_ui.has_signal("repair_cancelled"):
                repair_ui.repair_cancelled.connect(_on_repair_ui_cancelled)
            
            # Pause player input is handled by UIManager now
            # No need to manually disable player input

func _on_repair_ui_completed():
    _complete_repair()
    # UIManager handles re-enabling player input

func _on_repair_ui_cancelled():
    print("Repair cancelled")
    # UIManager handles re-enabling player input

func _complete_repair():
    is_damaged = false
    repair_completed.emit(repair_type)
    
    # Notify sabotage manager
    var sabotage_manager = get_tree().get_first_node_in_group("sabotage_manager")
    if sabotage_manager and sabotage_manager.has_method("repair_system"):
        var sabotage_event = _get_sabotage_event_for_repair_type()
        sabotage_manager.repair_system(sabotage_event)
    
    print(RepairType.keys()[repair_type], " system repaired!")
    
    # Update visual feedback
    _update_visual_state(false)

func _get_sabotage_event_for_repair_type() -> int:
    match repair_type:
        RepairType.POWER_GRID:
            return SabotageSystemManager.SabotageEvent.POWER_OUTAGE
        RepairType.SECURITY_SYSTEM:
            return SabotageSystemManager.SabotageEvent.SECURITY_MALFUNCTION
        RepairType.LIFE_SUPPORT:
            return SabotageSystemManager.SabotageEvent.LIFE_SUPPORT_ISSUES
        RepairType.COMMUNICATIONS:
            return SabotageSystemManager.SabotageEvent.COMMUNICATION_BLACKOUT
    return -1

func _on_sabotage_triggered(event: int):
    # Check if this repair station should be activated
    if _get_sabotage_event_for_repair_type() == event:
        is_damaged = true
        _update_visual_state(true)
        print(station_name, " repair needed due to sabotage")

func _on_sabotage_resolved(event: int):
    # Check if this repair station should be deactivated
    if _get_sabotage_event_for_repair_type() == event:
        is_damaged = false
        _update_visual_state(false)

func _update_visual_state(damaged: bool):
    # Update visual indicators (lights, particles, etc.)
    # Find any child lights
    for child in get_children():
        if child is Light3D:
            if damaged:
                child.light_color = Color(1, 0, 0)
                child.light_energy = 2.0
            else:
                child.light_color = Color(0, 1, 0)
                child.light_energy = 0.5
    
    # Update screen material
    var screen = get_node_or_null("Screen")
    if screen and screen is MeshInstance3D:
        var mat = screen.get_surface_override_material(0)
        if not mat and screen.mesh:
            mat = screen.mesh.surface_get_material(0)
        
        if mat and mat is StandardMaterial3D:
            if damaged:
                mat.emission = Color(1, 0, 0, 1)
                mat.emission_energy_multiplier = 0.5
            else:
                mat.emission = Color(0, 0.5, 0, 1)
                mat.emission_energy_multiplier = 0.3
    
    # Update emergency button
    var button = get_node_or_null("EmergencyButton")
    if button and button is MeshInstance3D:
        var mat = button.get_surface_override_material(0)
        if not mat and button.mesh:
            mat = button.mesh.surface_get_material(0)
        
        if mat and mat is StandardMaterial3D:
            if damaged:
                mat.emission_energy_multiplier = 1.0
            else:
                mat.emission_energy_multiplier = 0.2
    
    # Update indicator lights
    var control_panel = get_node_or_null("ControlPanel")
    if control_panel:
        for child in control_panel.get_children():
            if child is MeshInstance3D:
                var mat = StandardMaterial3D.new()
                if damaged:
                    mat.albedo_color = Color(1, 0, 0, 1)
                    mat.emission_enabled = true
                    mat.emission = Color(1, 0, 0, 1)
                    mat.emission_energy_multiplier = 0.5
                else:
                    mat.albedo_color = Color(0, 1, 0, 1)
                    mat.emission_enabled = true
                    mat.emission = Color(0, 1, 0, 1)
                    mat.emission_energy_multiplier = 0.3
                child.set_surface_override_material(0, mat)

func on_hover_start():
    pass

func on_hover_end():
    pass

func _input(event):
    # DEBUG: Press T to toggle repair station damage state
    if event.is_action_pressed("toggle_evidence"):  # T key
        is_damaged = !is_damaged
        _update_visual_state(is_damaged)
        print("DEBUG: Repair station damaged state: ", is_damaged)
