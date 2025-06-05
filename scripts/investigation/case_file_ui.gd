extends Control

@onready var interaction_prompt = $InteractionPrompt
@onready var interaction_label = $InteractionPrompt/Label
@onready var crosshair_dot = $Crosshair/CrosshairDot

# Outline colors
var default_crosshair_color = Color(1, 1, 1, 0.8)
var hover_outline_color = Color(1.0, 0.84, 0.0, 1.0)  # Gold

# Outline bracket elements
var outline_brackets: Array[ColorRect] = []

# Hidden indicator
var hidden_indicator: Label = null
# Crouch indicator
var crouch_indicator: Label = null

func _ready():
    # Store default crosshair settings
    if crosshair_dot:
        crosshair_dot.color = default_crosshair_color
    
    # Create outline brackets
    _create_outline_brackets()
    
    # Create hidden indicator
    _create_hidden_indicator()
    
    # Create crouch indicator
    _create_crouch_indicator()
    
    # Connect to player signals for interaction prompts
    await get_tree().process_frame
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.interactable_detected.connect(_on_interactable_detected)
        player.interactable_lost.connect(_on_interactable_lost)
        player.hidden_state_changed.connect(_on_hidden_state_changed)
        print("UI: Connected to player signals")
    else:
        print("UI: Could not find player to connect signals")

func show_interaction_prompt(prompt_text: String = "Press [E] to interact"):
    interaction_label.text = prompt_text
    interaction_prompt.visible = true
    
    # Change crosshair to gold outline
    if crosshair_dot:
        crosshair_dot.color = hover_outline_color
        crosshair_dot.custom_minimum_size = Vector2(8, 8)  # Make it bigger
    
    # Show outline brackets
    _show_outline_brackets()

func hide_interaction_prompt():
    interaction_prompt.visible = false
    
    # Reset crosshair to default
    if crosshair_dot:
        crosshair_dot.color = default_crosshair_color
        crosshair_dot.custom_minimum_size = Vector2(4, 4)  # Back to normal size
    
    # Hide outline brackets
    _hide_outline_brackets()

func _create_outline_brackets():
    if not $Crosshair:
        return
    
    var bracket_size = 20
    var bracket_thickness = 3
    var bracket_offset = 30
    
    # Create 4 corner brackets
    for i in 4:
        var h_rect = ColorRect.new()
        var v_rect = ColorRect.new()
        
        h_rect.color = hover_outline_color
        v_rect.color = hover_outline_color
        h_rect.visible = false
        v_rect.visible = false
        
        # Set sizes
        h_rect.custom_minimum_size = Vector2(bracket_size, bracket_thickness)
        v_rect.custom_minimum_size = Vector2(bracket_thickness, bracket_size)
        
        # Position based on corner
        match i:
            0:  # Top-left
                h_rect.position = Vector2(-bracket_offset, -bracket_offset)
                v_rect.position = Vector2(-bracket_offset, -bracket_offset)
            1:  # Top-right
                h_rect.position = Vector2(bracket_offset - bracket_size, -bracket_offset)
                v_rect.position = Vector2(bracket_offset - bracket_thickness, -bracket_offset)
            2:  # Bottom-left
                h_rect.position = Vector2(-bracket_offset, bracket_offset - bracket_thickness)
                v_rect.position = Vector2(-bracket_offset, bracket_offset - bracket_size)
            3:  # Bottom-right
                h_rect.position = Vector2(bracket_offset - bracket_size, bracket_offset - bracket_thickness)
                v_rect.position = Vector2(bracket_offset - bracket_thickness, bracket_offset - bracket_size)
        
        $Crosshair.add_child(h_rect)
        $Crosshair.add_child(v_rect)
        outline_brackets.append(h_rect)
        outline_brackets.append(v_rect)

func _show_outline_brackets():
    for bracket in outline_brackets:
        bracket.visible = true
        # Animate in
        var tween = create_tween()
        bracket.modulate.a = 0.0
        tween.tween_property(bracket, "modulate:a", 1.0, 0.1)

func _hide_outline_brackets():
    for bracket in outline_brackets:
        bracket.visible = false

func _create_hidden_indicator():
    # Create container for hidden indicator
    var container = PanelContainer.new()
    container.name = "HiddenIndicator"
    container.visible = false
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    # Position at top center - use CENTER_TOP preset and offset
    container.set_anchors_preset(Control.PRESET_CENTER_TOP)
    container.position = Vector2(-100, 50)  # Half width offset
    container.set_deferred("size", Vector2(200, 40))
    
    # Style the container
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0.7)
    style.set_corner_radius_all(5)
    container.add_theme_stylebox_override("panel", style)
    
    # Create label
    hidden_indicator = Label.new()
    hidden_indicator.text = "HIDDEN"
    hidden_indicator.add_theme_color_override("font_color", Color(0, 1, 0))
    hidden_indicator.add_theme_font_size_override("font_size", 24)
    hidden_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hidden_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    container.add_child(hidden_indicator)
    add_child(container)

func set_hidden_indicator(is_hidden: bool):
    if hidden_indicator and hidden_indicator.get_parent():
        hidden_indicator.get_parent().visible = is_hidden
        
        if is_hidden:
            # Pulse animation
            var tween = create_tween()
            tween.set_loops()
            tween.tween_property(hidden_indicator, "modulate:a", 0.5, 0.5)
            tween.tween_property(hidden_indicator, "modulate:a", 1.0, 0.5)

func _create_crouch_indicator():
    # Create container for crouch indicator
    var container = PanelContainer.new()
    container.name = "CrouchIndicator"
    container.visible = false
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    # Position at bottom left
    container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    container.position = Vector2(50, -100)
    container.set_deferred("size", Vector2(150, 30))
    
    # Style the container
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0.5)
    style.set_corner_radius_all(3)
    container.add_theme_stylebox_override("panel", style)
    
    # Create label
    crouch_indicator = Label.new()
    crouch_indicator.text = "CROUCHING"
    crouch_indicator.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
    crouch_indicator.add_theme_font_size_override("font_size", 18)
    crouch_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crouch_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    container.add_child(crouch_indicator)
    add_child(container)

func set_crouch_indicator(is_crouching: bool):
    if crouch_indicator and crouch_indicator.get_parent():
        crouch_indicator.get_parent().visible = is_crouching

func _on_interactable_detected(interactable):
    if interactable and interactable.has_method("get_interaction_prompt"):
        var prompt = interactable.get_interaction_prompt()
        show_interaction_prompt(prompt)
    else:
        show_interaction_prompt("Press [E] to interact")

func _on_interactable_lost():
    hide_interaction_prompt()

func _on_hidden_state_changed(is_hidden: bool):
    set_hidden_indicator(is_hidden)
