extends CharacterBody3D

const WALK_SPEED = 3.5
const RUN_SPEED = 6.0
const CROUCH_SPEED = 1.5
const MOUSE_SENSITIVITY = 0.002
const GRAVITY = 9.8
const CROUCH_HEIGHT = 0.5  # How much to lower the camera when crouching

@onready var camera_holder = $CameraHolder
@onready var camera = $CameraHolder/Camera3D
@onready var interaction_ray = $CameraHolder/Camera3D/InteractionRay

var interaction_system: InteractionSystem

# State variables
var is_hidden: bool = false
var can_move: bool = true
var current_hiding_spot: HidingSpot = null
var is_crouching: bool = false
var default_camera_height: float = 0.0
var ui_is_active: bool = false

signal interactable_detected(interactable)
signal interactable_lost
signal hidden_state_changed(is_hidden: bool)

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    # Add to player group
    add_to_group("player")
    
    # Store default camera height
    if camera_holder:
        default_camera_height = camera_holder.position.y
    
    interaction_system = InteractionSystem.new()
    add_child(interaction_system)
    interaction_system.setup(interaction_ray)
    interaction_system.interactable_detected.connect(_on_interactable_detected)
    interaction_system.interactable_lost.connect(_on_interactable_lost)
    
    # Connect to UIManager for UI state changes (with delay to ensure it's ready)
    await get_tree().process_frame
    var ui_manager = UIManager.get_instance()
    if ui_manager:
        ui_manager.ui_state_changed.connect(_on_ui_state_changed)

func _input(event):
    if event is InputEventMouseMotion:
        var mouse_mode = Input.get_mouse_mode()
        if mouse_mode == Input.MOUSE_MODE_CAPTURED:
            if not is_hidden or (current_hiding_spot and current_hiding_spot.hiding_type == "vent"):
                # Limited look while in vents, no look in other hiding spots
                var sensitivity = MOUSE_SENSITIVITY
                if is_hidden:
                    sensitivity *= 0.3  # Reduced sensitivity in vents
                
                rotate_y(-event.relative.x * sensitivity)
                camera_holder.rotate_x(-event.relative.y * sensitivity)
                camera_holder.rotation.x = clamp(camera_holder.rotation.x, -1.5, 1.5)
    
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    if event.is_action_pressed("interact"):
        # If hidden, try to exit the hiding spot first
        if is_hidden and current_hiding_spot:
            current_hiding_spot.interact()
        else:
            interaction_system.interact()
    
    # Toggle crouch
    if event.is_action_pressed("crouch"):
        toggle_crouch()
    
    # DEBUG: Force night cycle with N key
    if event is InputEventKey and event.pressed and event.keycode == KEY_N:
        var day_night = get_tree().get_first_node_in_group("day_night_manager")
        if day_night and day_night.has_method("trigger_night_cycle"):
            print("DEBUG: Forcing night cycle")
            day_night.trigger_night_cycle()
        else:
            print("DEBUG: Day/Night manager not found!")
    
    # DEBUG: Reset to day with M key (for Morning)
    if event is InputEventKey and event.pressed and event.keycode == KEY_M:
        var day_night = get_tree().get_first_node_in_group("day_night_manager")
        if day_night and day_night.has_method("force_day_cycle"):
            print("DEBUG: Forcing day cycle")
            day_night.force_day_cycle()

func _physics_process(delta):
    if not can_move and not is_hidden:
        return
    
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    
    # Handle movement input
    if not is_hidden or (current_hiding_spot and current_hiding_spot.can_move_while_hidden):
        var input_dir = Vector3()
        if Input.is_action_pressed("move_forward"):
            input_dir.z -= 1
        if Input.is_action_pressed("move_backward"):
            input_dir.z += 1
        if Input.is_action_pressed("move_left"):
            input_dir.x -= 1
        if Input.is_action_pressed("move_right"):
            input_dir.x += 1
        
        input_dir = input_dir.normalized()
        
        var direction = (transform.basis * input_dir).normalized()
        
        # Determine speed based on movement state
        var speed = WALK_SPEED
        if is_crouching:
            speed = CROUCH_SPEED
        elif Input.is_action_pressed("run") and not is_hidden:
            speed = RUN_SPEED
        
        if direction:
            velocity.x = direction.x * speed
            velocity.z = direction.z * speed
            
            # Make noise when running
            if speed == RUN_SPEED:
                make_noise(10.0)
            # Crouching is completely silent
        else:
            velocity.x = move_toward(velocity.x, 0, speed * delta * 3)
            velocity.z = move_toward(velocity.z, 0, speed * delta * 3)
    else:
        # Stop movement when hidden (except in vents)
        velocity.x = 0
        velocity.z = 0
    
    move_and_slide()
    
    # Only check interactions when UI is not active
    if not ui_is_active:
        interaction_system.check_interaction()

func _on_interactable_detected(interactable):
    print("Player: Interactable detected - ", interactable.name if interactable else "null")
    interactable_detected.emit(interactable)

func _on_interactable_lost():
    print("Player: Interactable lost")
    interactable_lost.emit()

func _on_ui_state_changed(is_ui_active: bool):
    ui_is_active = is_ui_active
    
    # When UI becomes active, clear any current interactable
    if is_ui_active and interaction_system.current_interactable:
        interaction_system.current_interactable = null
        interactable_lost.emit()

func set_hidden_state(hidden: bool, hiding_spot: HidingSpot = null):
    is_hidden = hidden
    can_move = !hidden  # Disable movement while hidden (except in vents)
    
    # Store current hiding spot if entering
    if hidden and hiding_spot:
        current_hiding_spot = hiding_spot
        if hiding_spot.can_move_while_hidden:
            can_move = true  # Can move in vents
        # Force the interaction system to track this hiding spot
        if interaction_system:
            interaction_system.current_interactable = hiding_spot
    else:
        current_hiding_spot = null
    
    hidden_state_changed.emit(hidden)
    
    # Update UI
    var player_ui = get_node_or_null("UILayer/PlayerUI")
    if player_ui and player_ui.has_method("set_hidden_indicator"):
        player_ui.set_hidden_indicator(hidden)

func get_visibility_multiplier() -> float:
    var multiplier = 1.0
    
    if current_hiding_spot:
        multiplier = current_hiding_spot.get_visibility_multiplier()
    elif is_crouching:
        multiplier = 0.6  # 40% harder to detect when crouching
    
    return multiplier

func make_noise(radius: float):
    # Alert nearby NPCs
    var riley = get_tree().get_first_node_in_group("riley_patrol")
    if riley:
        # Riley patrol AI is a child of the NPC, get the parent's position
        var riley_npc = riley.get_parent() if riley.get_parent() else null
        if riley_npc and riley_npc is Node3D:
            var distance = global_position.distance_to(riley_npc.global_position)
            if distance <= radius and riley.has_method("on_sound_heard"):
                riley.on_sound_heard(global_position)

func toggle_crouch():
    if is_hidden:
        return  # Can't crouch while hidden
    
    is_crouching = !is_crouching
    
    # Animate camera height change
    var target_height = default_camera_height
    if is_crouching:
        target_height = default_camera_height - CROUCH_HEIGHT
    
    # Smooth transition
    var tween = create_tween()
    tween.tween_property(camera_holder, "position:y", target_height, 0.2)
    
    # Update collision shape if needed (future enhancement)
    # For now, just the visual change
    
    # Update UI indicator
    var player_ui = get_node_or_null("UILayer/PlayerUI")
    if player_ui and player_ui.has_method("set_crouch_indicator"):
        player_ui.set_crouch_indicator(is_crouching)
