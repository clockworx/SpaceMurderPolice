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
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0
@export var wander_radius: float = 5.0
@export var room_wander_radius: float = 2.5  # Smaller wander radius when in a room
@export var assigned_room: String = ""  # Room assignment for NPC
@export var can_leave_room: bool = false  # Whether NPC can wander to other rooms

@export_group("Schedule")
@export var use_schedule: bool = false
@export var schedule: Array[Dictionary] = []  # Time-based schedule
@export var patrol_route: Array[Dictionary] = []  # Patrol route for security

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
var navigation_system: ImprovedNPCNavigation
var room_bounds: Dictionary = {}  # Store room boundaries
var room_navigation: RoomNavigationSystem
var waypoint_navigation: WaypointNavigationSystem
var current_activity: String = ""
var activity_timer: float = 0.0
var min_activity_time: float = 8.0
var max_activity_time: float = 20.0
var last_activity_change: float = 0.0
var separation_radius: float = 2.0  # Minimum distance between NPCs
var avoidance_force: float = 1.5  # How strongly NPCs push away from each other

# Advanced navigation components
var navigation_agent: NavigationAgent3D
var advanced_nav_manager: AdvancedNavigationManager
var is_navigating: bool = false
var nav_update_timer: float = 0.0
var nav_update_interval: float = 0.1  # Update path every 0.1 seconds

# Schedule system
var current_schedule_index: int = 0
var schedule_timer: float = 0.0
var is_following_schedule: bool = false
var schedule_transition_in_progress: bool = false
var game_time_hours: float = 8.0  # Start at 8 AM

# Patrol system
var current_patrol_index: int = 0
var patrol_timer: float = 0.0
var is_patrolling: bool = false

func _ready():
    collision_layer = 2  # Interactable layer
    collision_mask = 1   # Collide with environment
    
    # Ensure physics processing is enabled
    set_physics_process(true)
    
    # Define room boundaries
    _setup_room_bounds()
    
    # Setup advanced navigation first
    advanced_nav_manager = get_tree().get_first_node_in_group("advanced_navigation_manager")
    if not advanced_nav_manager:
        # Create advanced navigation manager if it doesn't exist
        var adv_nav_script = load("res://scripts/managers/advanced_navigation_manager.gd")
        if adv_nav_script:
            advanced_nav_manager = adv_nav_script.new()
            advanced_nav_manager.name = "AdvancedNavigationManager"
            get_tree().root.add_child.call_deferred(advanced_nav_manager)
            await advanced_nav_manager.navigation_ready
    
    # Create NavigationAgent3D for this NPC
    if advanced_nav_manager and advanced_nav_manager.has_method("create_npc_navigator"):
        navigation_agent = advanced_nav_manager.create_npc_navigator(self)
        navigation_agent.velocity_computed.connect(_on_navigation_velocity_computed)
        navigation_agent.navigation_finished.connect(_on_navigation_finished)
        navigation_agent.target_reached.connect(_on_navigation_target_reached)
        print(npc_name + ": NavigationAgent3D configured")
        
        # Wait for navigation to be ready
        await get_tree().physics_frame
        await get_tree().physics_frame
    
    # DISABLED: Don't use waypoint navigation - user has placed NPCs manually
    # waypoint_navigation = get_tree().get_first_node_in_group("waypoint_navigation")
    # if not waypoint_navigation:
    #     # Create waypoint navigation system
    #     var waypoint_nav_script = load("res://scripts/npcs/waypoint_navigation_system.gd")
    #     if waypoint_nav_script:
    #         waypoint_navigation = waypoint_nav_script.new()
    #         waypoint_navigation.name = "WaypointNavigation"
    #         waypoint_navigation.add_to_group("waypoint_navigation")
    #         get_tree().root.add_child.call_deferred(waypoint_navigation)
    
    # DISABLED: Don't use room navigation either - user has placed NPCs manually
    # if not waypoint_navigation:
    #     var room_nav_script = load("res://scripts/npcs/room_navigation_system.gd")
    #     if room_nav_script:
    #         room_navigation = room_nav_script.new()
    #         room_navigation.name = "RoomNavigation"
    #         add_child(room_navigation)
    
    # DISABLED: Let user's scene placement determine room assignment
    # Don't override with code-based assignment
    print(npc_name + " starting in scene-defined position")
    
    initial_position = global_position
    current_target = global_position
    
    # DISABLED: Trust user's manual placement
    # Don't modify initial positions
    
    # Start with a short idle, then pick first activity
    idle_timer = 0.5
    is_idle = true
    current_activity = ""  # Ensure activity is reset
    
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
        get_tree().root.add_child.call_deferred(relationship_manager)
    
    # Create relationship indicator
    _create_relationship_indicator()
    
    # Connect to relationship changes
    relationship_manager.relationship_changed.connect(_on_relationship_changed)
    
    # DISABLED: User has manually positioned NPCs correctly
    # Trust the scene file positions instead of auto-repositioning
    print(npc_name + " starting at position: " + str(global_position))
    
    # Just set the initial position for reference
    initial_position = global_position
    current_target = global_position
    
    # Don't start first activity immediately - let idle timer handle it
    
    # Initialize schedule system
    _setup_default_schedules()
    if use_schedule and schedule.size() > 0:
        is_following_schedule = true
        _update_schedule_target()

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
    
    # Update activity timer
    if activity_timer > 0:
        activity_timer -= delta
        
    # Update patrol if using patrol system
    if is_patrolling:
        _update_patrol()
        
    # Force activity changes periodically to ensure NPCs move
    last_activity_change += delta
    if last_activity_change > 15.0:  # Check every 15 seconds
        if is_idle and idle_timer > 2.0:  # Only interrupt if been idle for a while
            idle_timer = 0.1  # Force new target selection soon
        last_activity_change = 0.0
    
    # Simple AI behavior
    if is_idle:
        idle_timer -= delta
        if idle_timer <= 0:
            _choose_new_target()
    else:
        # Navigation disabled due to errors - use simple movement
        _move_to_target(delta)
        
        # Check if stuck (but not too frequently)
        if velocity.length() < 0.1 and current_target.distance_to(global_position) > 2.0:
            # Increment a stuck counter instead of immediately choosing new target
            if not has_meta("stuck_timer"):
                set_meta("stuck_timer", 0.0)
            var stuck_timer = get_meta("stuck_timer") + delta
            set_meta("stuck_timer", stuck_timer)
            
            # Only consider stuck after 2 seconds of no movement
            if stuck_timer > 2.0:
                print(npc_name + " seems stuck after 2 seconds, choosing new target")
                _choose_new_target()
                set_meta("stuck_timer", 0.0)
        else:
            # Reset stuck timer if moving
            if has_meta("stuck_timer"):
                set_meta("stuck_timer", 0.0)

func _start_idle():
    is_idle = true
    idle_timer = randf_range(idle_time_min, idle_time_max)
    velocity = Vector3.ZERO

func _choose_new_target():
    # First choose activity if needed
    if activity_timer <= 0:
        _choose_new_activity()
        activity_timer = randf_range(min_activity_time, max_activity_time)
    
    # Use NavigationAgent3D if available
    if navigation_agent and navigation_agent is NavigationAgent3D:
        var target_pos = Vector3.ZERO
        
        # Get target based on current activity
        if current_activity != "wander" and assigned_room != "hallway":
            target_pos = advanced_nav_manager.get_room_waypoint(assigned_room, current_activity)
        else:
            # Get random patrol point
            target_pos = advanced_nav_manager.get_random_patrol_point(assigned_room)
        
        if target_pos != Vector3.ZERO:
            current_target = target_pos
            # Set navigation target
            navigation_agent.target_position = current_target
            is_navigating = true
            
            # Register our target position to prevent bunching
            if advanced_nav_manager.has_method("register_npc_position"):
                advanced_nav_manager.register_npc_position(self, current_target)
        else:
            # Fallback to simple navigation
            _choose_target_fallback()
    else:
        # Use simple navigation
        _choose_target_fallback()
    
    # If we have a NavigationAgent3D, set the target
    if navigation_agent and navigation_agent is NavigationAgent3D and current_target != Vector3.ZERO:
        navigation_agent.target_position = current_target
        is_navigating = true
    
    is_idle = false
    # Check if we're actually going somewhere new
    var distance_to_new_target = current_target.distance_to(global_position)
    if distance_to_new_target > 1.5:
        print(npc_name + " moving to " + str(current_target) + " for activity: " + current_activity + " (distance: " + str(distance_to_new_target) + ")")
    else:
        # Too close to current position, try to find a farther target
        print(npc_name + " target too close (", distance_to_new_target, "m), current pos: ", global_position, ", target: ", current_target)
        
        # Force a random walk if stuck - but stay within room bounds
        var random_offset = Vector3(
            randf_range(-3.0, 3.0),
            0,
            randf_range(-3.0, 3.0)
        )
        var potential_target = global_position + random_offset
        
        # Ensure target is within room bounds
        if not assigned_room.is_empty() and room_bounds.has(assigned_room):
            var bounds = room_bounds[assigned_room]
            potential_target.x = clamp(potential_target.x, bounds.min_x + 1.0, bounds.max_x - 1.0)
            potential_target.z = clamp(potential_target.z, bounds.min_z + 1.0, bounds.max_z - 1.0)
        else:
            # Clamp to station bounds if no room assigned
            potential_target.x = clamp(potential_target.x, -15.0, 15.0)
            potential_target.z = clamp(potential_target.z, -25.0, 20.0)
        
        current_target = potential_target
        print(npc_name + " forcing random walk to: ", current_target)
        return

func _choose_target_fallback():
    # Simple movement within current area
    if false and waypoint_navigation and not assigned_room.is_empty():
        # Get target based on current activity
        if current_activity != "wander" and assigned_room != "hallway":
            var activity_pos = waypoint_navigation.get_activity_position(assigned_room, current_activity)
            if activity_pos != Vector3.ZERO:
                current_target = activity_pos
            else:
                current_target = waypoint_navigation.get_next_waypoint(assigned_room, global_position)
        else:
            current_target = waypoint_navigation.get_next_waypoint(assigned_room, global_position)
    elif room_navigation and not assigned_room.is_empty():
        # Fallback to room navigation
        if current_activity != "wander" and assigned_room != "hallway":
            var activity_pos = room_navigation.get_activity_position(assigned_room, current_activity)
            if activity_pos != Vector3.ZERO:
                current_target = activity_pos
            else:
                current_target = room_navigation.get_next_waypoint(assigned_room, global_position)
        else:
            current_target = room_navigation.get_next_waypoint(assigned_room, global_position)
    else:
        # Fallback to simple room-based movement
        if not assigned_room.is_empty() and room_bounds.has(assigned_room):
            var bounds = room_bounds[assigned_room]
            # Stay in back half of room, away from doors
            var x = 0.0
            var z = randf_range(bounds.min_z + 1.0, bounds.max_z - 1.0)
            
            if bounds.min_x < 0:  # Left side room
                x = randf_range(bounds.min_x + 1.0, bounds.min_x + 2.5)
            else:  # Right side room
                x = randf_range(bounds.max_x - 2.5, bounds.max_x - 1.0)
            
            current_target = Vector3(x, 0.1, z)
        else:
            # Default wander for hallway NPCs
            var angle = randf() * TAU
            var distance = randf() * wander_radius * 0.5  # Smaller wander radius
            var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
            current_target = initial_position + offset

func _move_to_target(_delta):
    var to_target = current_target - global_position
    to_target.y = 0
    var distance = to_target.length()
    
    if distance > 1.0:  # Increased threshold to prevent stopping too early
        var direction = to_target.normalized()
        
        # Improved obstacle avoidance with multiple ray checks
        var space_state = get_world_3d().direct_space_state
        var check_height = 0.9
        var check_distance = 1.2
        var blocked = false
        
        # Check multiple heights for obstacles
        for height in [0.3, 0.9, 1.5]:
            var from = global_position + Vector3.UP * height
            var to = from + direction * check_distance
            
            var query = PhysicsRayQueryParameters3D.create(from, to)
            query.exclude = [self]
            query.collision_mask = 1  # Environment layer
            
            var result = space_state.intersect_ray(query)
            if result:
                blocked = true
                break
        
        # Also check ground ahead to avoid walking off edges
        var ground_from = global_position + direction * 0.5 + Vector3.UP * 0.5
        var ground_to = ground_from + Vector3.DOWN * 1.0
        var ground_query = PhysicsRayQueryParameters3D.create(ground_from, ground_to)
        ground_query.exclude = [self]
        ground_query.collision_mask = 1
        var ground_result = space_state.intersect_ray(ground_query)
        if not ground_result:
            blocked = true  # No ground ahead
        
        if blocked:
            # More sophisticated avoidance
            # Try multiple angles to find a clear path
            var clear_direction = Vector3.ZERO
            var angles = [PI/4, -PI/4, PI/2, -PI/2, 3*PI/4, -3*PI/4, PI]
            
            for angle in angles:
                var test_dir = direction.rotated(Vector3.UP, angle)
                var all_clear = true
                
                # Test this direction at multiple heights
                for height in [0.3, 0.9, 1.5]:
                    var from = global_position + Vector3.UP * height
                    var test_to = from + test_dir * check_distance
                    var test_query = PhysicsRayQueryParameters3D.create(from, test_to)
                    test_query.exclude = [self]
                    test_query.collision_mask = 1
                    
                    var test_result = space_state.intersect_ray(test_query)
                    if test_result:
                        all_clear = false
                        break
                
                if all_clear:
                    clear_direction = test_dir
                    break
            
            if clear_direction != Vector3.ZERO:
                direction = clear_direction
            else:
                # All directions blocked, stop and wait
                direction = Vector3.ZERO
                velocity = Vector3.ZERO
                # Force new target after a short wait
                if not has_meta("blocked_timer"):
                    set_meta("blocked_timer", 0.0)
                var blocked_timer = get_meta("blocked_timer") + _delta
                set_meta("blocked_timer", blocked_timer)
                if blocked_timer > 1.0:
                    print(npc_name + " is completely blocked, choosing new target")
                    _choose_new_target()
                    set_meta("blocked_timer", 0.0)
                return
        
        # Add gentle NPC avoidance
        var avoidance = _calculate_npc_avoidance()
        if avoidance.length() > 0.1:
            direction = (direction * 2.0 + avoidance).normalized()
        
        # Apply movement
        velocity = direction * walk_speed
        
        # Rotate to face movement direction
        if velocity.length() > 0.1:
            var look_target = global_position + velocity
            look_target.y = global_position.y
            look_at(look_target, Vector3.UP)
            rotation.x = 0
            rotation.z = 0
        
        # Check for doors
        _check_and_open_doors()
    else:
        # Reached target
        velocity = Vector3.ZERO
        _start_idle()
    
    # Always call move_and_slide to apply physics
    move_and_slide()
    
    # Safety check - ensure NPC stays within bounds
    var needs_reset = false
    
    # Check height bounds
    if global_position.y < -1.0 or global_position.y > 5.0:
        print("WARNING: " + npc_name + " fell out of bounds! Resetting Y position")
        global_position.y = 0.1
        velocity.y = 0
        needs_reset = true
    
    # DISABLED: Don't enforce room bounds - user has placed NPCs manually
    # Just log if they're in unexpected positions
    if not assigned_room.is_empty() and room_bounds.has(assigned_room):
        var bounds = room_bounds[assigned_room]
        
        if global_position.x < bounds.min_x - 2.0 or global_position.x > bounds.max_x + 2.0:
            pass  # Don't move them, just let them be where placed
        
        if global_position.z < bounds.min_z - 2.0 or global_position.z > bounds.max_z + 2.0:
            pass  # Don't move them, just let them be where placed
    else:
        # General station bounds check - but don't reset
        if global_position.x < -16.0 or global_position.x > 16.0 or global_position.z < -26.0 or global_position.z > 21.0:
            # Just log, don't move
            pass
    
    if needs_reset:
        velocity = Vector3.ZERO
        _choose_new_target()

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
    var _debug_text = ""  # Prefixed with underscore since not used
    
    # Always show relationship status for debugging
    match level:
        -2:
            level_name = "HOSTILE"
            _debug_text = "[-2]"
        -1:
            level_name = "UNFRIENDLY"
            _debug_text = "[-1]"
        0:
            level_name = "NEUTRAL"
            _debug_text = "[0]"
        1:
            level_name = "FRIENDLY"
            _debug_text = "[+1]"
        2:
            level_name = "TRUSTED"
            _debug_text = "[+2]"
    
    # Only show when player is nearby
    relationship_indicator.text = level_name
    relationship_indicator.modulate = color
    relationship_indicator.visible = player_nearby  # Only visible when player is close

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
    
    # Ensure we're not processing physics in base class
    set_physics_process(false)
    
    # Check if patrol AI already exists
    var patrol_ai = get_node_or_null("SaboteurPatrolAI")
    if patrol_ai:
        print("DEBUG: Riley patrol AI already exists, enabling it")
        # Enable the patrol AI's physics process
        patrol_ai.set_physics_process(true)
        patrol_ai.set_active(true)
        # Reset to patrolling state
        if patrol_ai.has_method("_change_state"):
            patrol_ai._change_state(patrol_ai.State.PATROLLING)
        if patrol_ai.has_method("_set_next_patrol_target"):
            patrol_ai._set_next_patrol_target()
        return
    
    # Add patrol AI component if it doesn't exist
    var saboteur_patrol_script = load("res://scripts/npcs/saboteur_patrol_ai.gd")
    if not saboteur_patrol_script:
        push_error("Failed to load saboteur_patrol_ai.gd!")
        return
        
    patrol_ai = saboteur_patrol_script.new()
    patrol_ai.name = "SaboteurPatrolAI"
    add_child(patrol_ai)
    print("DEBUG: Saboteur patrol AI added as child")
    
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
        var patrol_ai = get_node_or_null("SaboteurPatrolAI")
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

func _on_navigation_stuck(stuck_position: Vector3):
    print(npc_name + " got stuck at ", stuck_position, ", choosing new target")
    # Move back a bit and choose new target
    global_position -= global_transform.basis.z * 0.5
    # Choose a new random target when stuck
    _choose_new_target()

func _check_and_open_doors():
    # Cast ray forward to check for doors
    var space_state = get_world_3d().direct_space_state
    var from = global_position + Vector3.UP * 1.0
    var forward = velocity.normalized() if velocity.length() > 0.1 else -global_transform.basis.z
    var to = from + forward * 2.5  # Check further ahead for doors
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 3  # Check both environment and interactable layers
    query.exclude = [self]
    
    var result = space_state.intersect_ray(query)
    if result and result.collider.has_method("open_door"):
        # It's a door - check if closed
        if not result.collider.is_open:
            print(npc_name + ": Approaching door")
            # Stop and wait for door to open
            var door_distance = global_position.distance_to(result.collider.global_position)
            if door_distance < 3.5:
                # Close enough - stop and wait
                velocity = Vector3.ZERO
                is_idle = true
                idle_timer = 0.5  # Wait briefly for door to open
                
                # Face the door
                var look_pos = result.collider.global_position
                look_pos.y = global_position.y
                look_at(look_pos, Vector3.UP)
                rotation.x = 0
                rotation.z = 0

func _on_navigation_finished():
    # Navigation completed, start idle
    _start_idle()

func get_current_state() -> String:
    # Used by navigation debug visualization
    if npc_name == "Riley Kim" and is_night_cycle:
        var patrol_ai = get_node_or_null("SaboteurPatrolAI")
        if patrol_ai and patrol_ai.has_method("get_current_state_name"):
            return patrol_ai.get_current_state_name()
    return "idle" if is_idle else "moving"

func _choose_new_activity():
    # Choose activity based on NPC role and room
    var old_activity = current_activity
    match assigned_room:
        "laboratory":
            var activities = ["workstation", "equipment", "research", "wander"]
            current_activity = activities[randi() % activities.size()]
        "medical":
            var activities = ["examination", "supplies", "desk", "wander"]
            current_activity = activities[randi() % activities.size()]
        "security":
            var activities = ["monitors", "weapons", "desk", "wander"]
            current_activity = activities[randi() % activities.size()]
        "engineering":
            var activities = ["console", "repairs", "storage", "wander"]
            current_activity = activities[randi() % activities.size()]
        "cafeteria":
            var activities = ["kitchen", "tables", "storage", "wander"]
            current_activity = activities[randi() % activities.size()]
        _:
            current_activity = "wander"
    
    if current_activity != old_activity:
        print(npc_name + " switching from " + old_activity + " to " + current_activity)

func _setup_room_bounds():
    # Define boundaries for each room (updated for larger room sizes)
    room_bounds = {
        "laboratory": {"min_x": -15.0, "max_x": -1.0, "min_z": 3.0, "max_z": 17.0},
        "medical": {"min_x": 2.0, "max_x": 14.0, "min_z": -1.0, "max_z": 11.0},
        "security": {"min_x": -14.0, "max_x": -2.0, "min_z": -11.0, "max_z": 1.0},
        "engineering": {"min_x": 1.0, "max_x": 15.0, "min_z": -17.0, "max_z": -3.0},
        "quarters": {"min_x": -15.0, "max_x": -1.0, "min_z": -21.0, "max_z": -9.0},
        "cafeteria": {"min_x": 0.0, "max_x": 16.0, "min_z": -27.0, "max_z": -13.0},
        "hallway": {"min_x": -3.0, "max_x": 3.0, "min_z": -30.0, "max_z": 22.5}
    }

func _get_room_from_position(pos: Vector3) -> String:
    # Determine which room a position is in
    # Check rooms first before defaulting to hallway
    for room_name in room_bounds:
        if room_name == "hallway":
            continue  # Check hallway last
        var bounds = room_bounds[room_name]
        if pos.x >= bounds.min_x and pos.x <= bounds.max_x and \
           pos.z >= bounds.min_z and pos.z <= bounds.max_z:
            return room_name
    
    # Check if in hallway bounds
    if room_bounds.has("hallway"):
        var hallway_bounds = room_bounds["hallway"]
        if pos.x >= hallway_bounds.min_x and pos.x <= hallway_bounds.max_x and \
           pos.z >= hallway_bounds.min_z and pos.z <= hallway_bounds.max_z:
            return "hallway"
    
    return "hallway"  # Default to hallway if not in any room

func _assign_npc_to_room():
    # Updated with correct NPC names from the game
    match npc_name:
        "Dr. Sarah Chen":
            assigned_room = "medical"
            can_leave_room = true  # Medical officer might need to visit patients
        "Dr. Marcus Webb":
            assigned_room = "laboratory"
            can_leave_room = false  # Chief scientist stays in lab
        "Alex Chen":
            assigned_room = "engineering"
            can_leave_room = true  # Engineer needs to move around
        "Jake Torres":
            assigned_room = "security"
            can_leave_room = true  # Security chief patrols
        "Dr. Zara Okafor":
            assigned_room = "hallway"  # AI specialist can be anywhere
            can_leave_room = true
        _:
            # Default assignment based on position
            assigned_room = _get_room_from_position(global_position)
            can_leave_room = true

# Calculate avoidance force from other NPCs
func _calculate_npc_avoidance() -> Vector3:
    var avoidance = Vector3.ZERO
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc == self:
            continue
            
        var distance = global_position.distance_to(npc.global_position)
        if distance < separation_radius and distance > 0.01:
            # Calculate repulsion force
            var away_dir = (global_position - npc.global_position)
            away_dir.y = 0  # Keep on same level
            if away_dir.length() > 0:
                away_dir = away_dir.normalized()
                var force = 1.0 - (distance / separation_radius)
                avoidance += away_dir * force * avoidance_force
    
    # Limit avoidance force to prevent jittering
    if avoidance.length() > avoidance_force:
        avoidance = avoidance.normalized() * avoidance_force
    
    return avoidance

# Check if position would cause collision with furniture
func _is_position_blocked(pos: Vector3) -> bool:
    var space_state = get_world_3d().direct_space_state
    var from = pos + Vector3.UP * 0.5
    var to = pos + Vector3.DOWN * 0.1
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    query.collision_mask = 3  # Check both environment and interactables
    
    var result = space_state.intersect_ray(query)
    return result != null

# Navigation using NavigationAgent3D for smooth movement
func _navigate_with_agent(delta):
    if not navigation_agent:
        # Fallback to old movement
        _move_to_target(delta)
        return
        
    # Always update the target position
    navigation_agent.target_position = current_target
    
    if navigation_agent.is_navigation_finished():
        # Reached target
        is_navigating = false
        _start_idle()
        
        # Unregister our position
        if advanced_nav_manager and advanced_nav_manager.has_method("unregister_npc_position"):
            advanced_nav_manager.unregister_npc_position(current_target)
    else:
        # Get next position on path
        var next_position = navigation_agent.get_next_path_position()
        var direction = global_position.direction_to(next_position)
        direction.y = 0  # Keep on same level
        
        # Apply movement
        velocity = direction * walk_speed
        
        # Rotate to face movement direction
        if velocity.length() > 0.1:
            var look_target = global_position + velocity
            look_target.y = global_position.y
            look_at(look_target, Vector3.UP)
            rotation.x = 0
            rotation.z = 0
        
        move_and_slide()
        
        # Check for doors along the path
        _check_and_open_doors()

# Called when NavigationAgent computes safe velocity
func _on_navigation_velocity_computed(safe_velocity: Vector3):
    if is_navigating:
        velocity = safe_velocity
        
        # Rotate to face movement direction
        if velocity.length() > 0.1:
            var look_target = global_position + velocity
            look_target.y = global_position.y
            look_at(look_target, Vector3.UP)
            rotation.x = 0
            rotation.z = 0
        
        move_and_slide()

# Called when navigation target is reached
func _on_navigation_target_reached():
    print(npc_name + " reached navigation target")
    is_navigating = false
    _start_idle()

# Apply velocity from advanced navigation system
func apply_velocity(new_velocity: Vector3):
    velocity = new_velocity
    
    # Rotate to face movement direction
    if velocity.length() > 0.1:
        var look_target = global_position + velocity
        look_target.y = global_position.y
        look_at(look_target, Vector3.UP)
        rotation.x = 0
        rotation.z = 0
    
    move_and_slide()

# Schedule System Functions
func _setup_default_schedules():
    # Set up default schedules based on NPC role
    if schedule.is_empty():
        match npc_name:
            "Dr. Sarah Chen":  # Medical Officer
                schedule = [
                    {"time": 8.0, "room": "cafeteria", "activity": "breakfast", "duration": 0.5},
                    {"time": 8.5, "room": "medical", "activity": "examination", "duration": 3.5},
                    {"time": 12.0, "room": "cafeteria", "activity": "lunch", "duration": 1.0},
                    {"time": 13.0, "room": "medical", "activity": "supplies", "duration": 4.0},
                    {"time": 17.0, "room": "medical", "activity": "desk", "duration": 1.0},
                    {"time": 18.0, "room": "cafeteria", "activity": "dinner", "duration": 1.0},
                    {"time": 19.0, "room": "quarters", "activity": "rest", "duration": 13.0}
                ]
            "Dr. Marcus Webb":  # Chief Scientist
                schedule = [
                    {"time": 7.0, "room": "laboratory", "activity": "research", "duration": 5.0},
                    {"time": 12.0, "room": "cafeteria", "activity": "lunch", "duration": 0.5},
                    {"time": 12.5, "room": "laboratory", "activity": "equipment", "duration": 6.5},
                    {"time": 19.0, "room": "laboratory", "activity": "workstation", "duration": 2.0},
                    {"time": 21.0, "room": "quarters", "activity": "rest", "duration": 10.0}
                ]
            "Jake Torres":  # Security Chief
                # Use patrol route instead of schedule
                use_schedule = false
                patrol_route = [
                    {"room": "security", "activity": "monitors", "duration": 120.0},
                    {"room": "hallway", "activity": "patrol", "duration": 60.0},
                    {"room": "laboratory", "activity": "check", "duration": 30.0},
                    {"room": "medical", "activity": "check", "duration": 30.0},
                    {"room": "engineering", "activity": "check", "duration": 30.0},
                    {"room": "cafeteria", "activity": "check", "duration": 30.0},
                    {"room": "quarters", "activity": "check", "duration": 30.0},
                    {"room": "security", "activity": "weapons", "duration": 60.0}
                ]
                is_patrolling = true
            "Alex Chen":  # Engineer
                schedule = [
                    {"time": 6.0, "room": "engineering", "activity": "console", "duration": 2.0},
                    {"time": 8.0, "room": "cafeteria", "activity": "breakfast", "duration": 0.5},
                    {"time": 8.5, "room": "engineering", "activity": "machinery", "duration": 3.5},
                    {"time": 12.0, "room": "cafeteria", "activity": "lunch", "duration": 1.0},
                    {"time": 13.0, "room": "engineering", "activity": "repairs", "duration": 5.0},
                    {"time": 18.0, "room": "cafeteria", "activity": "dinner", "duration": 1.0},
                    {"time": 19.0, "room": "engineering", "activity": "console", "duration": 2.0},
                    {"time": 21.0, "room": "quarters", "activity": "rest", "duration": 9.0}
                ]
            "Dr. Zara Okafor":  # AI Specialist
                schedule = [
                    {"time": 9.0, "room": "cafeteria", "activity": "breakfast", "duration": 0.5},
                    {"time": 9.5, "room": "laboratory", "activity": "workstation", "duration": 2.5},
                    {"time": 12.0, "room": "cafeteria", "activity": "lunch", "duration": 1.0},
                    {"time": 13.0, "room": "engineering", "activity": "console", "duration": 2.0},
                    {"time": 15.0, "room": "laboratory", "activity": "research", "duration": 3.0},
                    {"time": 18.0, "room": "cafeteria", "activity": "dinner", "duration": 1.5},
                    {"time": 19.5, "room": "quarters", "activity": "rest", "duration": 13.5}
                ]

func _update_schedule_target():
    if not use_schedule or schedule.is_empty():
        return
    
    # Find current schedule entry based on game time
    var current_entry = _get_current_schedule_entry()
    if not current_entry:
        return
    
    # Check if we need to transition to a new room
    if current_entry.room != assigned_room:
        print(npc_name + " transitioning from " + assigned_room + " to " + current_entry.room + " for " + current_entry.activity)
        assigned_room = current_entry.room
        current_activity = current_entry.activity
        schedule_transition_in_progress = true
        
        # Get the room center as initial target
        if room_bounds.has(assigned_room):
            var bounds = room_bounds[assigned_room]
            current_target = Vector3(
                (bounds.min_x + bounds.max_x) / 2.0,
                0.1,
                (bounds.min_z + bounds.max_z) / 2.0
            )
            is_idle = false
    else:
        # Already in the right room, update activity
        if current_activity != current_entry.activity:
            current_activity = current_entry.activity
            activity_timer = current_entry.duration * 60.0  # Convert minutes to seconds
            _choose_new_target()

func _get_current_schedule_entry() -> Dictionary:
    if schedule.is_empty():
        return {}
    
    # Find the schedule entry that matches current time
    var current_entry = {}
    var latest_time = 0.0
    
    for entry in schedule:
        if entry.time <= game_time_hours and entry.time > latest_time:
            current_entry = entry
            latest_time = entry.time
    
    # If no entry found (too early), use the last entry from previous day
    if current_entry.is_empty() and schedule.size() > 0:
        current_entry = schedule[-1]
    
    return current_entry

func _update_patrol():
    if not is_patrolling or patrol_route.is_empty():
        return
    
    patrol_timer -= get_physics_process_delta_time()
    
    if patrol_timer <= 0:
        # Move to next patrol point
        current_patrol_index = (current_patrol_index + 1) % patrol_route.size()
        var patrol_point = patrol_route[current_patrol_index]
        
        print(npc_name + " patrolling to " + patrol_point.room + " for " + patrol_point.activity)
        
        assigned_room = patrol_point.room
        current_activity = patrol_point.activity
        patrol_timer = patrol_point.duration
        
        # Force new target selection
        _choose_new_target()

func set_game_time(hours: float):
    game_time_hours = fmod(hours, 24.0)
    if use_schedule:
        _update_schedule_target()

func force_schedule_entry(index: int):
    if index >= 0 and index < schedule.size():
        current_schedule_index = index
        _update_schedule_target()
