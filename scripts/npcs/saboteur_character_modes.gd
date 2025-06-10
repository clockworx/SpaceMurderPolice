extends Node
class_name SaboteurCharacterModes

# Character mode states
enum Mode {
    NORMAL,      # Helpful maintenance tech
    SABOTEUR     # Mysterious masked figure
}

@export_group("Visual Settings")
@export var normal_uniform_color: Color = Color(0.8, 0.8, 0.8)  # Light gray uniform
@export var saboteur_suit_color: Color = Color(0.1, 0.1, 0.1)   # Dark suit
@export var normal_emissive_color: Color = Color(0.2, 0.8, 0.2)  # Green tech lights
@export var saboteur_emissive_color: Color = Color(0.8, 0.2, 0.2) # Red saboteur lights

@export_group("Movement Settings")
@export var saboteur_speed_multiplier: float = 1.5  # Faster when sabotaging
@export var saboteur_sneak_speed: float = 1.0       # Slow when sneaking

var current_mode: Mode = Mode.NORMAL
var npc_base: NPCBase
var patrol_ai: SaboteurPatrolAI
var mesh_instance: MeshInstance3D
var name_label: Label3D
var role_label: Label3D
var original_name: String = "Unknown"
var original_role: String = "Station Crew"
var sabotage_target: Vector3

# Materials for switching appearance
var normal_material: StandardMaterial3D
var saboteur_material: StandardMaterial3D
var helmet_mesh: MeshInstance3D

signal mode_changed(new_mode: Mode)
signal sabotage_movement_started(target_position: Vector3)
signal sabotage_movement_completed()

func _ready():
    # Debug: Initializing
    #print("SaboteurCharacterModes: Initializing...")
    npc_base = get_parent()
    if not npc_base:
        push_error("SaboteurCharacterModes must be child of NPCBase")
        return
    
    # Debug: Found parent NPC
    #print("SaboteurCharacterModes: Found parent NPC: ", npc_base.npc_name)
    
    # Find components
    patrol_ai = npc_base.get_node_or_null("SaboteurPatrolAI")
    mesh_instance = npc_base.get_node_or_null("MeshInstance3D")
    name_label = npc_base.get_node_or_null("Head/NameLabel")
    role_label = npc_base.get_node_or_null("Head/RoleLabel")
    
    # Debug: Components found
    #print("SaboteurCharacterModes: Components found - PatrolAI: ", patrol_ai != null, ", Mesh: ", mesh_instance != null, ", NameLabel: ", name_label != null)
    
    # Store original values
    if name_label:
        original_name = name_label.text
    if role_label:
        original_role = role_label.text
    
    # Debug: Original name and role
    #print("SaboteurCharacterModes: Original name: ", original_name, ", role: ", original_role)
    
    # Create materials
    _setup_materials()
    
    # Create helmet/mask for saboteur mode
    _create_helmet()
    
    # Connect to sabotage system
    var sabotage_manager = get_tree().get_first_node_in_group("sabotage_manager")
    if sabotage_manager:
        # Debug: Found sabotage manager
        #print("SaboteurCharacterModes: Found sabotage manager, connecting signals...")
        sabotage_manager.sabotage_started.connect(_on_sabotage_started)
        sabotage_manager.sabotage_ended.connect(_on_sabotage_ended)
        # Debug: Connected to signals
        #print("SaboteurCharacterModes: Connected to sabotage signals")
    else:
        print("SaboteurCharacterModes: WARNING - No sabotage manager found!")
    
    # Start in normal mode
    _apply_normal_mode()
    # Debug: Initialization complete
    #print("SaboteurCharacterModes: Initialization complete")

func _setup_materials():
    # Create normal material
    normal_material = StandardMaterial3D.new()
    normal_material.albedo_color = normal_uniform_color
    normal_material.emission_enabled = true
    normal_material.emission = normal_emissive_color
    normal_material.emission_energy = 0.5
    normal_material.metallic = 0.2
    normal_material.roughness = 0.8
    
    # Create saboteur material
    saboteur_material = StandardMaterial3D.new()
    saboteur_material.albedo_color = saboteur_suit_color
    saboteur_material.emission_enabled = true
    saboteur_material.emission = saboteur_emissive_color
    saboteur_material.emission_energy = 0.3
    saboteur_material.metallic = 0.6
    saboteur_material.roughness = 0.4

func _create_helmet():
    # Create a simple helmet/mask mesh
    helmet_mesh = MeshInstance3D.new()
    var helmet = SphereMesh.new()
    helmet.radial_segments = 16
    helmet.height = 0.4
    helmet.radius = 0.25
    helmet_mesh.mesh = helmet
    
    # Dark visor material
    var visor_material = StandardMaterial3D.new()
    visor_material.albedo_color = Color(0.05, 0.05, 0.05)
    visor_material.metallic = 0.9
    visor_material.roughness = 0.1
    visor_material.emission_enabled = true
    visor_material.emission = Color(0.5, 0, 0)
    visor_material.emission_energy = 0.2
    helmet_mesh.material_override = visor_material
    
    # Add to head but hide initially
    var head = npc_base.get_node_or_null("Head")
    if head:
        head.add_child(helmet_mesh)
        helmet_mesh.position = Vector3(0, 0.1, 0)
        helmet_mesh.visible = false

func switch_to_normal_mode():
    if current_mode == Mode.NORMAL:
        return
    
    print("Saboteur switching to NORMAL mode")
    current_mode = Mode.NORMAL
    _apply_normal_mode()
    mode_changed.emit(Mode.NORMAL)

func switch_to_saboteur_mode():
    if current_mode == Mode.SABOTEUR:
        return
    
    print("Saboteur switching to SABOTEUR mode")
    current_mode = Mode.SABOTEUR
    _apply_saboteur_mode()
    mode_changed.emit(Mode.SABOTEUR)

func _apply_normal_mode():
    # Visual changes
    if mesh_instance and normal_material:
        mesh_instance.material_override = normal_material
    
    # Show name and role
    if name_label:
        name_label.text = original_name
        name_label.visible = true
    if role_label:
        role_label.text = original_role
        role_label.visible = true
    
    # Hide helmet
    if helmet_mesh:
        helmet_mesh.visible = false
    
    # Reset movement speed
    if npc_base:
        npc_base.walk_speed = 2.0
    
    # Disable patrol behavior in normal mode (Saboteur is helpful, not patrolling)
    if patrol_ai:
        patrol_ai.set_physics_process(false)
        if patrol_ai.has_method("set_active"):
            patrol_ai.set_active(false)
    
    # Enable interaction
    if npc_base:
        npc_base.set_collision_layer_value(2, true)  # Re-enable interactable layer

func _apply_saboteur_mode():
    # Visual changes
    if mesh_instance and saboteur_material:
        mesh_instance.material_override = saboteur_material
    
    # Hide identity
    if name_label:
        name_label.text = "Unknown Figure"
        name_label.visible = true
    if role_label:
        role_label.visible = false  # Hide role completely
    
    # Show helmet
    if helmet_mesh:
        helmet_mesh.visible = true
    
    # Adjust movement speed
    if npc_base:
        npc_base.walk_speed = 3.0  # Faster movement
    
    # Activate patrol AI and switch to sabotage mode
    if patrol_ai:
        if patrol_ai.has_method("set_active"):
            patrol_ai.set_active(true)
        patrol_ai.set_physics_process(true)
        if patrol_ai.has_method("start_sabotage_mission"):
            patrol_ai.start_sabotage_mission(sabotage_target)
    
    # Disable interaction (can't talk to unknown figure)
    if npc_base:
        npc_base.set_collision_layer_value(2, false)  # Disable interactable layer

func move_to_sabotage_target(target_position: Vector3):
    sabotage_target = target_position
    sabotage_movement_started.emit(target_position)
    
    # Override physics process for custom movement
    set_physics_process(true)

func _physics_process(_delta):
    if current_mode != Mode.SABOTEUR:
        set_physics_process(false)
        return
    
    # Move toward sabotage target
    var distance = npc_base.global_position.distance_to(sabotage_target)
    
    if distance < 1.5:
        # Reached target
        sabotage_movement_completed.emit()
        set_physics_process(false)
        return
    
    # Calculate movement
    var direction = (sabotage_target - npc_base.global_position).normalized()
    direction.y = 0
    
    # Use stealth movement if player is nearby
    var player = get_tree().get_first_node_in_group("player")
    var speed = npc_base.walk_speed * saboteur_speed_multiplier
    
    if player:
        var player_distance = npc_base.global_position.distance_to(player.global_position)
        if player_distance < 10.0:
            speed = saboteur_sneak_speed  # Slow down near player
    
    # Move
    npc_base.velocity = direction * speed
    npc_base.move_and_slide()
    
    # Rotate to face movement direction
    if direction.length() > 0.1:
        var look_pos = npc_base.global_position + direction
        look_pos.y = npc_base.global_position.y
        npc_base.look_at(look_pos, Vector3.UP)

func _on_sabotage_started(location: String, position: Vector3):
    print("SaboteurCharacterModes: Sabotage started signal received - Location: ", location, ", Position: ", position)
    print("SaboteurCharacterModes: Current NPC name: ", npc_base.npc_name)
    
    # Only NPCs marked as saboteurs respond to sabotage events
    if not npc_base.can_be_saboteur:
        print("SaboteurCharacterModes: Not a saboteur NPC, ignoring sabotage signal")
        return
    
    print("SaboteurCharacterModes: This is a saboteur NPC! Switching to saboteur mode...")
    
    # Switch to saboteur mode
    switch_to_saboteur_mode()
    
    # Move to sabotage location
    move_to_sabotage_target(position)

func _on_sabotage_ended():
    # Wait a bit before switching back
    await get_tree().create_timer(5.0).timeout
    
    print("Saboteur: Sabotage complete. Returning to normal mode...")
    switch_to_normal_mode()

func is_in_saboteur_mode() -> bool:
    return current_mode == Mode.SABOTEUR

func get_current_identity() -> String:
    if current_mode == Mode.SABOTEUR:
        return "Unknown Figure"
    return original_name

# Debug function - call this to manually test mode switching
func debug_test_saboteur_mode():
    print("SaboteurCharacterModes: DEBUG - Manual mode switch test")
    if current_mode == Mode.NORMAL:
        switch_to_saboteur_mode()
    else:
        switch_to_normal_mode()

func _input(event):
    # Debug key for testing - press T to toggle modes
    if event.is_action_pressed("ui_select") and Input.is_action_pressed("ui_cancel"):
        debug_test_saboteur_mode()
