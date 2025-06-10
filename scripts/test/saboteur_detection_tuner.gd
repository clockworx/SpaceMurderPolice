extends Node

# Saboteur Detection Tuner - Add this to your scene for runtime tuning
# Press number keys 1-5 to select different NPCs
# Use +/- to adjust values, Tab to cycle parameters

var selected_npc: UnifiedNPC
var selected_param: int = 0
var npcs: Array = []

var param_names = [
    "enable_saboteur_behavior",
    "detection_range", 
    "vision_angle",
    "investigation_duration",
    "return_to_patrol_speed"
]

func _ready():
    # Find all NPCs that can be saboteurs
    for npc in get_tree().get_nodes_in_group("npcs"):
        if npc.has_method("can_be_saboteur") and npc.can_be_saboteur:
            npcs.append(npc)
            print("Found saboteur NPC: ", npc.npc_name)
    
    if npcs.size() > 0:
        selected_npc = npcs[0]
        _show_current_values()
    
    print("\n=== Saboteur Detection Tuner ===")
    print("Controls:")
    print("- Number keys (1-5): Select NPC")
    print("- Tab: Cycle through parameters")
    print("- +/-: Adjust current parameter")
    print("- D: Toggle debug visuals")
    print("- R: Reset to defaults")

func _input(event):
    if not selected_npc:
        return
    
    # Select NPC with number keys
    for i in range(min(5, npcs.size())):
        if event.is_action_pressed("ui_text_submit") and Input.is_key_pressed(KEY_1 + i):
            selected_npc = npcs[i]
            print("\nSelected NPC: ", selected_npc.npc_name)
            _show_current_values()
    
    # Cycle parameters with Tab
    if event.is_action_pressed("ui_focus_next"):
        selected_param = (selected_param + 1) % param_names.size()
        print("\nSelected parameter: ", param_names[selected_param])
        _show_current_value()
    
    # Adjust values with +/-
    if event.is_action_pressed("ui_page_up"):  # + key
        _adjust_parameter(0.1)
    elif event.is_action_pressed("ui_page_down"):  # - key
        _adjust_parameter(-0.1)
    
    # Toggle debug with D
    if event.is_action_pressed("ui_text_submit") and Input.is_key_pressed(KEY_D):
        selected_npc.show_state_label = not selected_npc.show_state_label
        selected_npc.debug_state_changes = not selected_npc.debug_state_changes
        print("\nDebug mode: ", selected_npc.show_state_label)
    
    # Reset with R
    if event.is_action_pressed("ui_text_submit") and Input.is_key_pressed(KEY_R):
        _reset_to_defaults()

func _adjust_parameter(delta: float):
    var param = param_names[selected_param]
    
    match param:
        "enable_saboteur_behavior":
            selected_npc.enable_saboteur_behavior = not selected_npc.enable_saboteur_behavior
        "detection_range":
            selected_npc.detection_range = max(1.0, selected_npc.detection_range + delta * 10)
        "vision_angle":
            selected_npc.vision_angle = clamp(selected_npc.vision_angle + delta * 100, 10, 180)
        "investigation_duration":
            selected_npc.investigation_duration = max(0.5, selected_npc.investigation_duration + delta * 10)
        "return_to_patrol_speed":
            selected_npc.return_to_patrol_speed = max(0.5, selected_npc.return_to_patrol_speed + delta * 10)
    
    _show_current_value()

func _show_current_value():
    var param = param_names[selected_param]
    var value = selected_npc.get(param)
    print(param, " = ", value)

func _show_current_values():
    print("\nCurrent values for ", selected_npc.npc_name, ":")
    for param in param_names:
        print("  ", param, " = ", selected_npc.get(param))

func _reset_to_defaults():
    selected_npc.enable_saboteur_behavior = false
    selected_npc.detection_range = 10.0
    selected_npc.vision_angle = 60.0
    selected_npc.investigation_duration = 3.0
    selected_npc.return_to_patrol_speed = 3.0
    print("\nReset to defaults")
    _show_current_values()

# Visual debug overlay
func _draw():
    if not selected_npc or not selected_npc.enable_saboteur_behavior:
        return
    
    # This would need to be in a 2D overlay, just showing the concept
    # In practice, you'd create 3D debug meshes for visualization