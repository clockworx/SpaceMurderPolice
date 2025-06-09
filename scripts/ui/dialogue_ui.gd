extends Control
class_name DialogueUI

@onready var dialogue_panel = $DialoguePanel
@onready var speaker_label = $DialoguePanel/VBoxContainer/SpeakerLabel
@onready var dialogue_text = $DialoguePanel/VBoxContainer/DialogueText
@onready var options_container = $DialoguePanel/VBoxContainer/OptionsContainer

var dialogue_system: DialogueSystem
var current_options: Array = []

signal option_selected(index: int)

func _ready():
    visible = false
    dialogue_panel.modulate.a = 0.0
    
    # Add to dialogue UI group
    add_to_group("dialogue_ui")
    
    # Get dialogue system reference
    dialogue_system = DialogueSystem.new()
    add_child.call_deferred(dialogue_system)
    
    # Connect dialogue system signals after it's added
    call_deferred("_connect_dialogue_signals")
    
func _connect_dialogue_signals():
    if dialogue_system:
        dialogue_system.dialogue_started.connect(_on_dialogue_started)
        dialogue_system.dialogue_ended.connect(_on_dialogue_ended)
        dialogue_system.dialogue_line_changed.connect(_on_dialogue_line_changed)
        dialogue_system.evidence_revealed.connect(_on_evidence_revealed)
        
        # Get relationship manager and connect to changes
        var rel_manager = dialogue_system.relationship_manager
        if rel_manager:
            rel_manager.relationship_changed.connect(_on_relationship_changed)

func _on_dialogue_started(_npc_name: String):
    visible = true
    
    # Pause player movement
    get_tree().paused = true
    
    # Fade in dialogue panel
    var tween = create_tween()
    tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.3)
    
    # Show mouse cursor
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_dialogue_ended():
    # Fade out dialogue panel
    var tween = create_tween()
    tween.tween_property(dialogue_panel, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func(): visible = false)
    
    # Resume player movement
    get_tree().paused = false
    
    # Hide mouse cursor
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_dialogue_line_changed(speaker: String, text: String, options: Array):
    speaker_label.text = speaker
    dialogue_text.text = text
    
    # Clear previous options
    for child in options_container.get_children():
        child.queue_free()
    
    current_options = options
    
    # Create option buttons
    for i in range(options.size()):
        var button = Button.new()
        button.text = str(i + 1) + ". " + options[i]
        button.add_theme_font_size_override("font_size", 16)
        button.pressed.connect(_on_option_button_pressed.bind(i))
        options_container.add_child(button)
        
        # Focus first button
        if i == 0:
            button.grab_focus()

func _on_option_button_pressed(index: int):
    option_selected.emit(index)
    dialogue_system.select_option(index)

func _on_evidence_revealed(evidence_id: String):
    # Show notification that evidence was revealed
    var evidence_notification = Label.new()
    evidence_notification.text = "New evidence revealed: " + evidence_id
    evidence_notification.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
    evidence_notification.add_theme_font_size_override("font_size", 20)
    evidence_notification.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    evidence_notification.position.y = 100
    add_child(evidence_notification)
    
    # Fade out notification
    var tween = create_tween()
    tween.tween_interval(2.0)
    tween.tween_property(evidence_notification, "modulate:a", 0.0, 1.0)
    tween.tween_callback(evidence_notification.queue_free)

func _input(event):
    if not visible:
        return
    
    # Keyboard shortcuts for options
    if event is InputEventKey and event.pressed:
        var key_num = 0
        if event.keycode >= KEY_1 and event.keycode <= KEY_9:
            key_num = event.keycode - KEY_1
        
        if key_num < current_options.size():
            dialogue_system.select_option(key_num)

func start_dialogue(npc: NPCBase):
    if dialogue_system:
        dialogue_system.start_dialogue(npc)

func _on_relationship_changed(npc_name: String, old_level: int, new_level: int):
    # Show relationship change notification
    var change_text = ""
    var color = Color.WHITE
    
    if new_level > old_level:
        change_text = "Relationship with " + npc_name + " improved!"
        color = Color(0.4, 0.8, 0.4)  # Green
    else:
        change_text = "Relationship with " + npc_name + " worsened!"
        color = Color(0.8, 0.4, 0.4)  # Red
    
    # Add relationship level name
    var level_names = ["Hostile", "Unfriendly", "Neutral", "Friendly", "Trusted"]
    var level_index = new_level + 2  # Convert from -2 to 2 range to 0 to 4
    if level_index >= 0 and level_index < level_names.size():
        change_text += "\n[" + level_names[level_index] + "]"
    
    # Create notification
    var relationship_notification = Label.new()
    relationship_notification.text = change_text
    relationship_notification.add_theme_color_override("font_color", color)
    relationship_notification.add_theme_font_size_override("font_size", 24)
    relationship_notification.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    relationship_notification.position.y = -150
    add_child(relationship_notification)
    
    # Animate notification
    var tween = create_tween()
    tween.tween_property(relationship_notification, "position:y", -200, 0.5)
    tween.parallel().tween_property(relationship_notification, "modulate:a", 0.0, 1.5)
    tween.tween_callback(relationship_notification.queue_free)
