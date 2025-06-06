extends CharacterBody3D
class_name NPCBase

@export_group("NPC Properties")
@export var npc_name: String = "Unknown"
@export var role: String = "Crew Member"
@export var initial_dialogue_id: String = "greeting"
@export var is_suspicious: bool = false
@export var has_alibi: bool = true
@export var can_be_saboteur: bool = false  # For NPCs that can switch modes

@export_group("Movement")
@export var walk_speed: float = 2.0
@export var idle_time_min: float = 3.0
@export var idle_time_max: float = 8.0
@export var wander_radius: float = 5.0

@export_group("Interaction")
@export var interaction_distance: float = 3.0
@export var face_player_when_talking: bool = true

var dialogue_state: Dictionary = {}
var has_been_interviewed: bool = false
var current_dialogue: String = ""
var is_talking: bool = false
var player_nearby: bool = false

var initial_position: Vector3
var current_target: Vector3
var idle_timer: float = 0.0
var is_idle: bool = true
var is_night_cycle: bool = false
var night_behavior_active: bool = false

signal dialogue_started(npc)
signal dialogue_ended(npc)
signal suspicion_changed(npc, is_suspicious)

var relationship_manager: RelationshipManager
var relationship_indicator: Label3D

func _ready():
    collision_layer = 2  # Interactable layer
    collision_mask = 1   # Collide with environment
    
    initial_position = global_position
    current_target = global_position
    
    # Start with idle
    _start_idle()
    
    # Add to NPC group
    add_to_group("npcs")
    
    # Update name and role labels to match exported properties
    var name_label = get_node_or_null("Head/NameLabel")
    if name_label:
        name_label.text = npc_name
    
    var role_label = get_node_or_null("Head/RoleLabel")
    if role_label:
        role_label.text = role
    
    # Get relationship manager
    relationship_manager = get_tree().get_first_node_in_group("relationship_manager")
    if not relationship_manager:
        relationship_manager = RelationshipManager.new()
        get_tree().root.add_child(relationship_manager)
    
    # Create relationship indicator
    _create_relationship_indicator()
    
    # Connect to relationship changes
    relationship_manager.relationship_changed.connect(_on_relationship_changed)

func _physics_process(delta):
    if is_talking:
        # Face the player while talking
        if face_player_when_talking:
            var player = get_tree().get_first_node_in_group("player")
            if player:
                var look_position = player.global_position
                look_position.y = global_position.y  # Keep same height to avoid tilting
                look_at(look_position, Vector3.UP)
                rotation.x = 0
                rotation.z = 0
        return
    
    # Simple AI behavior
    if is_idle:
        idle_timer -= delta
        if idle_timer <= 0:
            _choose_new_target()
    else:
        _move_to_target(delta)

func _start_idle():
    is_idle = true
    idle_timer = randf_range(idle_time_min, idle_time_max)
    velocity = Vector3.ZERO

func _choose_new_target():
    # Pick a random point within wander radius
    var angle = randf() * TAU
    var distance = randf() * wander_radius
    var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
    current_target = initial_position + offset
    is_idle = false

func _move_to_target(_delta):
    var direction = (current_target - global_position).normalized()
    direction.y = 0
    
    if global_position.distance_to(current_target) > 0.5:
        velocity = direction * walk_speed
        
        # Rotate to face movement direction
        if velocity.length() > 0.1:
            var look_target = global_position + velocity
            look_target.y = global_position.y
            look_at(look_target, Vector3.UP)
            rotation.x = 0
            rotation.z = 0
    else:
        _start_idle()
    
    move_and_slide()

func interact():
    if is_talking:
        return
    
    # Don't allow interviews during night cycle
    if is_night_cycle:
        if npc_name == "Riley Kim":
            # Riley doesn't talk during patrol, just ignore
            return
        else:
            # Show a quick message that they can't talk
            print(npc_name + ": I need to get to my quarters. We can talk in the morning.")
            return
    
    is_talking = true
    dialogue_started.emit(self)
    
    # Stop moving
    velocity = Vector3.ZERO
    is_idle = true
    
    print(npc_name + ": Starting dialogue")
    
    # Find dialogue UI and start dialogue
    var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
    if dialogue_ui:
        dialogue_ui.start_dialogue(self)
    
    has_been_interviewed = true

func end_dialogue():
    is_talking = false
    dialogue_ended.emit(self)
    _start_idle()

func get_interaction_prompt() -> String:
    # Don't show interaction prompt during night cycle
    if is_night_cycle:
        return ""
    
    if has_been_interviewed:
        return "Press [E] to talk to " + npc_name + " again"
    else:
        return "Press [E] to interview " + npc_name

func get_dialogue_data() -> Dictionary:
    return {
        "npc_name": npc_name,
        "role": role,
        "current_dialogue": current_dialogue,
        "has_been_interviewed": has_been_interviewed,
        "is_suspicious": is_suspicious,
        "has_alibi": has_alibi
    }

func set_suspicious(suspicious: bool):
    if is_suspicious != suspicious:
        is_suspicious = suspicious
        suspicion_changed.emit(self, is_suspicious)

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_nearby = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_nearby = false
        if is_talking:
            end_dialogue()

func _create_relationship_indicator():
    relationship_indicator = Label3D.new()
    relationship_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    relationship_indicator.position.y = 0.8  # Higher above head
    relationship_indicator.font_size = 20  # Larger text
    relationship_indicator.outline_size = 10  # Thicker outline
    $Head.add_child(relationship_indicator)
    _update_relationship_indicator()

func _update_relationship_indicator():
    if not relationship_manager or not relationship_indicator:
        return
    
    var level = relationship_manager.get_relationship(npc_name)
    var color = relationship_manager.get_relationship_color(npc_name)
    var level_name = ""
    var debug_text = ""
    
    # Always show relationship status for debugging
    match level:
        -2:
            level_name = "HOSTILE"
            debug_text = "[-2]"
        -1:
            level_name = "UNFRIENDLY"
            debug_text = "[-1]"
        0:
            level_name = "NEUTRAL"
            debug_text = "[0]"
        1:
            level_name = "FRIENDLY"
            debug_text = "[+1]"
        2:
            level_name = "TRUSTED"
            debug_text = "[+2]"
    
    # DEBUG: Always show status
    relationship_indicator.text = level_name + " " + debug_text
    relationship_indicator.modulate = color
    relationship_indicator.visible = true  # Always visible for debug

func _on_relationship_changed(changed_npc_name: String, _old_level: int, _new_level: int):
    if changed_npc_name == npc_name:
        _update_relationship_indicator()

func on_night_cycle_started():
    is_night_cycle = true
    
    # Different NPCs react differently to night
    match npc_name:
        "Riley Kim":
            # Riley becomes the hunter - activate patrol AI
            night_behavior_active = true
            print(npc_name + ": Beginning night patrol...")
            _activate_riley_patrol_mode()
        "Dr. Marcus Webb", "Commander Chen", "Dr. Okafor":
            # Most NPCs go to quarters
            night_behavior_active = true
            print(npc_name + ": Heading to quarters for the night.")
            _move_to_quarters()
        "Jake Torres":
            # Security stays on duty but changes position
            night_behavior_active = true
            print(npc_name + ": Maintaining security watch.")
            _move_to_security_post()

func _activate_riley_patrol_mode():
    print("DEBUG: Activating Riley patrol mode for ", npc_name)
    
    # Stop normal movement
    is_idle = true
    current_target = global_position
    velocity = Vector3.ZERO
    
    # Check if patrol AI already exists
    var patrol_ai = get_node_or_null("RileyPatrolAI")
    if patrol_ai:
        print("DEBUG: Riley patrol AI already exists, enabling it")
        # Disable parent's physics process to let patrol AI take over
        set_physics_process(false)
        # Enable the patrol AI's physics process
        patrol_ai.set_physics_process(true)
        # Reset to patrolling state
        if patrol_ai.has_method("_change_state"):
            patrol_ai._change_state(patrol_ai.State.PATROLLING)
        if patrol_ai.has_method("_set_next_patrol_target"):
            patrol_ai._set_next_patrol_target()
        return
    
    # Add patrol AI component if it doesn't exist
    var riley_patrol_script = load("res://scripts/npcs/riley_patrol_ai.gd")
    if not riley_patrol_script:
        push_error("Failed to load riley_patrol_ai.gd!")
        return
        
    patrol_ai = riley_patrol_script.new()
    patrol_ai.name = "RileyPatrolAI"
    add_child(patrol_ai)
    print("DEBUG: Riley patrol AI added as child")
    
    # Disable parent's physics process to let patrol AI take over
    set_physics_process(false)
    
    # Change appearance to be more menacing
    var mesh_instance = get_node_or_null("MeshInstance3D")
    if not mesh_instance:
        mesh_instance = find_child("*Mesh*", true, false) as MeshInstance3D
    
    if mesh_instance:
        print("DEBUG: Found mesh instance, changing appearance")
        var material = mesh_instance.get_surface_override_material(0)
        if not material:
            material = mesh_instance.mesh.surface_get_material(0) if mesh_instance.mesh else null
        
        if material and material is StandardMaterial3D:
            var new_material = material.duplicate()
            new_material.albedo_color = Color(0.8, 0.2, 0.2)  # Reddish tint
            new_material.emission_enabled = true
            new_material.emission = Color(0.5, 0, 0)
            new_material.emission_energy_multiplier = 0.5
            mesh_instance.set_surface_override_material(0, new_material)
    else:
        print("DEBUG: No mesh instance found")
    
    print("Riley: The station is mine now. No one escapes.")

func _move_to_quarters():
    # Move to a "quarters" position (simplified for now)
    is_idle = false
    velocity = Vector3.ZERO
    # In a full implementation, this would navigate to crew quarters

func _move_to_security_post():
    # Move to security monitoring position
    is_idle = false

func on_day_cycle_started():
    is_night_cycle = false
    night_behavior_active = false
    
    # Restore normal behavior
    if npc_name == "Riley Kim":
        # Disable patrol AI and restore normal movement
        var patrol_ai = get_node_or_null("RileyPatrolAI")
        if patrol_ai:
            patrol_ai.set_physics_process(false)
        set_physics_process(true)
        
        # Restore normal appearance
        var mesh_instance = get_node_or_null("MeshInstance3D")
        if not mesh_instance:
            mesh_instance = find_child("*Mesh*", true, false) as MeshInstance3D
        
        if mesh_instance and mesh_instance.get_surface_override_material(0):
            # Remove the override to restore original
            mesh_instance.set_surface_override_material(0, null)
        
        print(npc_name + ": Returning to normal duties.")
    
    # Resume normal idle behavior
    _start_idle()
    # In a full implementation, this would navigate to security office
