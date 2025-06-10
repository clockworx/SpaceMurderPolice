extends Control

# UI overlay to display NPC states
# Add this as a Control node to the scene to see NPC states

var label: RichTextLabel
var npcs: Array = []

func _ready():
    # Create UI
    set_anchors_preset(Control.PRESET_TOP_LEFT)
    position = Vector2(10, 10)
    
    label = RichTextLabel.new()
    label.custom_minimum_size = Vector2(300, 200)
    label.add_theme_color_override("default_color", Color.WHITE)
    label.add_theme_color_override("font_shadow_color", Color.BLACK)
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    add_child(label)
    
    # Add background
    var bg = ColorRect.new()
    bg.color = Color(0, 0, 0, 0.7)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.show_behind_parent = true
    add_child(bg)
    bg.move_to_front()
    label.move_to_front()
    
    # Find NPCs
    await get_tree().process_frame
    _find_npcs(get_tree().current_scene, npcs)
    
    print("State display monitoring ", npcs.size(), " NPCs")

func _find_npcs(node: Node, result: Array):
    if node.has_method("get_state_name"):
        result.append(node)
    
    for child in node.get_children():
        _find_npcs(child, result)

func _process(_delta):
    if npcs.is_empty():
        return
    
    var text = "[b]NPC States:[/b]\n\n"
    
    for npc in npcs:
        if not is_instance_valid(npc):
            continue
            
        var npc_name = npc.get("npc_name") if npc.get("npc_name") else npc.name
        var state = npc.get_state_name()
        var color = "white"
        
        match state:
            "PATROL":
                color = "green"
            "IDLE":
                color = "yellow"
            "TALK":
                color = "cyan"
        
        text += "[color=" + color + "]" + npc_name + ": " + state + "[/color]\n"
    
    text += "\n[color=gray]Press 1=PATROL, 2=IDLE, 3=TALK, 4=RESUME[/color]"
    
    label.bbcode_enabled = true
    label.text = text