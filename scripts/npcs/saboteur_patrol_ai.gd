extends Node
class_name SaboteurPatrolAI

@export var patrol_speed: float = 4.0
@export var chase_speed: float = 6.0
@export var detection_range: float = 15.0
@export var vision_angle: float = 60.0  # Degrees
@export var hearing_range: float = 10.0
@export var patrol_wait_time: float = 3.0

@export_group("Debug Visualization")
@export var show_awareness_sphere: bool = false
@export var show_vision_cone: bool = false
@export var show_state_indicators: bool = false
@export var show_patrol_path: bool = false
@export var show_sound_detection: bool = false

# Room definitions with door positions
var rooms = {
    "lab3": {"inside": Vector3(-7, 1.0, 10), "door": Vector3(-3, 1.0, 10), "hallway": Vector3(0, 1.0, 10)},
    "medical": {"inside": Vector3(7, 1.0, 5), "door": Vector3(3, 1.0, 5), "hallway": Vector3(0, 1.0, 5)},
    "security": {"inside": Vector3(-7, 1.0, -5), "door": Vector3(-3, 1.0, -5), "hallway": Vector3(0, 1.0, -5)},
    "engineering": {"inside": Vector3(7, 1.0, -10), "door": Vector3(3, 1.0, -10), "hallway": Vector3(0, 1.0, -10)},
    "quarters": {"inside": Vector3(-7, 1.0, -15), "door": Vector3(-3, 1.0, -15), "hallway": Vector3(0, 1.0, -15)},
    "cafeteria": {"inside": Vector3(7, 1.0, -20), "door": Vector3(3, 1.0, -20), "hallway": Vector3(0, 1.0, -20)}
}

# Simplified patrol route - just room names
var patrol_route = [
    "start",
    "lab3",
    "medical", 
    "security",
    "engineering",
    "quarters",
    "cafeteria",
    "end"
]

var current_route_index: int = 0
var current_room_phase: String = "hallway"  # "hallway", "door", "inside", "exiting"

var target_position: Vector3
var npc_base: NPCBase
var navigation_agent: NavigationAgent3D
var player: Node3D
var is_chasing: bool = false
var is_investigating: bool = false
var investigation_target: Vector3
var wait_timer: float = 0.0
var last_known_player_pos: Vector3
var state_light: OmniLight3D
var state_label: Label3D
var awareness_sphere: MeshInstance3D
var vision_cone_mesh: MeshInstance3D
var sound_detection_sphere: MeshInstance3D
var patrol_path_line: MeshInstance3D

# States
enum State {
    PATROLLING,
    WAITING,
    INVESTIGATING,
    CHASING,
    SEARCHING,
    SABOTAGE  # Special state for sabotage operations
}

var current_state: State = State.PATROLLING
var is_active: bool = true  # Whether the AI is currently active
var sabotage_target: Vector3  # Target position for sabotage
var sabotage_complete: bool = false  # Whether sabotage task is done
var caught_player: bool = false  # To prevent spam messages

signal player_spotted(player_position: Vector3)
signal player_lost()
signal state_changed(new_state: State)

func _ready():
    # Debug: Starting initialization
    #print("SaboteurPatrolAI: Starting initialization")
    npc_base = get_parent()
    if not npc_base:
        push_error("SaboteurPatrolAI must be child of NPCBase")
        return
    
    # Debug: Found parent NPC
    #print("SaboteurPatrolAI: Found parent NPC: ", npc_base.npc_name)
    
    # Add to riley patrol group
    add_to_group("riley_patrol")
    
    # Wait for navigation to be ready
    await get_tree().physics_frame
    
    # Find player
    player = get_tree().get_first_node_in_group("player")
    if player:
        # Debug: Found player
        #print("SaboteurPatrolAI: Found player")
        pass
    else:
        push_warning("SaboteurPatrolAI: Player not found!")
    
    # Don't create visualizations in _ready since they start disabled
    # They will be created when activated or when debug settings change
    
    # Start patrolling
    # Debug: Starting patrol route
    #print("SaboteurPatrolAI: Starting patrol route")
    current_route_index = 0
    current_room_phase = "hallway"
    _update_patrol_target()
    
    # Override parent's movement - make sure parent stops processing
    if npc_base.has_method("set_physics_process"):
        npc_base.set_physics_process(false)
    
    # Start with physics processing disabled until night cycle
    set_physics_process(false)
    is_active = false
    
    # Debug: Initialization complete
    #print("SaboteurPatrolAI: Initialization complete, current state: ", State.keys()[current_state])

func _physics_process(delta):
    if not is_active:
        return
        
    if not npc_base:
        # print("SaboteurPatrolAI: ERROR - npc_base is null!")
        return
    
    # Update state indicators position
    if state_light:
        state_light.global_position = npc_base.global_position + Vector3.UP * 2.5
    if state_label:
        state_label.global_position = npc_base.global_position + Vector3.UP * 3.0
    
    # Update awareness visualization
    _update_awareness_visualization()
    
    # Check for player detection
    if player:
        _check_player_detection()
        
        # Extra check for very close range (touching)
        var touch_distance = npc_base.global_position.distance_to(player.global_position)
        if touch_distance < 1.2 and current_state != State.CHASING:
            # print("SaboteurPatrolAI: Player touched Saboteur! Immediate detection!")
            _on_player_spotted()
    
    # Handle current state
    match current_state:
        State.PATROLLING:
            _handle_patrolling(delta)
        State.WAITING:
            _handle_waiting(delta)
        State.INVESTIGATING:
            _handle_investigating(delta)
        State.CHASING:
            _handle_chasing(delta)
        State.SEARCHING:
            _handle_searching(delta)
        State.SABOTAGE:
            _handle_sabotage(delta)

func _handle_patrolling(_delta):
    # Get current target based on route
    _update_patrol_target()
    
    var distance = npc_base.global_position.distance_to(target_position)
    
    if distance < 1.0:
        # Reached current target, advance to next phase
        _advance_patrol_phase()
        return
    
    # Check for obstacles and walls
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 0.9
    var direction = (target_position - npc_base.global_position).normalized()
    direction.y = 0
    
    # Cast ray to check for obstacles
    var to = from + direction * 2.0
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [npc_base]
    query.collision_mask = 1  # Environment layer
    
    var result = space_state.intersect_ray(query)
    if result:
        # Wall detected, try alternate path
        var left_dir = direction.rotated(Vector3.UP, PI/3)
        var right_dir = direction.rotated(Vector3.UP, -PI/3)
        
        # Test left
        query.to = from + left_dir * 2.0
        var left_result = space_state.intersect_ray(query)
        
        # Test right
        query.to = from + right_dir * 2.0
        var right_result = space_state.intersect_ray(query)
        
        if not left_result:
            direction = left_dir
        elif not right_result:
            direction = right_dir
        else:
            # Both blocked, back up
            direction = -direction
    
    # Always check for doors when moving
    _check_for_doors()
    
    # Apply movement with delta for smooth motion
    npc_base.velocity = direction * patrol_speed
    npc_base.move_and_slide()
    
    # Rotate to face movement direction
    if npc_base.velocity.length() > 0.1:
        var look_pos = npc_base.global_position + npc_base.velocity.normalized()
        look_pos.y = npc_base.global_position.y
        npc_base.look_at(look_pos, Vector3.UP)
        npc_base.rotation.x = 0
        npc_base.rotation.z = 0

func _handle_waiting(delta):
    wait_timer += delta
    if wait_timer >= patrol_wait_time:
        wait_timer = 0.0
        _set_next_patrol_target()
        _change_state(State.PATROLLING)

func _handle_investigating(delta):
    # Use parent's navigation system if available
    var nav_system = npc_base.get_node_or_null("NavigationSystem")
    if nav_system:
        # First, check if we're inside a room and need to exit
        if _is_inside_room() and not _is_in_hallway():
            # Find nearest door and exit first
            var nearest_door = _find_nearest_room_exit()
            if nearest_door != Vector3.ZERO:
                var exit_distance = npc_base.global_position.distance_to(nearest_door)
                if exit_distance > 1.0:
                    # Navigate to door first
                    if not nav_system.is_navigating:
                        nav_system.navigate_to(nearest_door)
                    nav_system.open_nearby_doors()
                    npc_base.velocity = nav_system.get_next_velocity(npc_base.velocity, patrol_speed)
                    if npc_base.velocity.length() > 0.1:
                        var look_pos = npc_base.global_position + npc_base.velocity.normalized()
                        look_pos.y = npc_base.global_position.y
                        npc_base.look_at(look_pos, Vector3.UP)
                    return
        
        # Navigate to investigation target
        if not nav_system.is_navigating:
            nav_system.navigate_to(investigation_target)
        
        nav_system.open_nearby_doors()
        npc_base.velocity = nav_system.get_next_velocity(npc_base.velocity, patrol_speed)
        
        if nav_system.get_distance_to_target() < 1.0:
            nav_system.stop_navigation()
            # Reached investigation point, look around
            npc_base.rotate_y(delta * 2.0)  # Spin to look around
            wait_timer += delta
            if wait_timer >= patrol_wait_time:
                wait_timer = 0.0
                _change_state(State.PATROLLING)
                _set_next_patrol_target()
    else:
        # Fallback to original logic
        # First, check if we're inside a room and need to exit
        if _is_inside_room() and not _is_in_hallway():
            # Find nearest door and exit first
            var nearest_door = _find_nearest_room_exit()
            if nearest_door != Vector3.ZERO:
                var exit_distance = npc_base.global_position.distance_to(nearest_door)
                if exit_distance > 1.0:
                    # Move to door first
                    _check_for_doors()
                    var direction = (nearest_door - npc_base.global_position).normalized()
                    direction.y = 0
                    npc_base.velocity = direction * patrol_speed
                    npc_base.move_and_slide()
                    if direction.length() > 0.1:
                        var look_pos = npc_base.global_position + direction
                        look_pos.y = npc_base.global_position.y
                        npc_base.look_at(look_pos, Vector3.UP)
                    return
        
        # Now handle normal investigation
        var distance = npc_base.global_position.distance_to(investigation_target)
        
        if distance < 1.0:
            # Reached investigation point, look around
            npc_base.rotate_y(delta * 2.0)  # Spin to look around
            wait_timer += delta
            if wait_timer >= patrol_wait_time:
                wait_timer = 0.0
                _change_state(State.PATROLLING)
                _set_next_patrol_target()
        else:
            # Check for doors
            _check_for_doors()
            
            # Move to investigation point
            var direction = (investigation_target - npc_base.global_position).normalized()
            direction.y = 0
            
            npc_base.velocity = direction * patrol_speed
            npc_base.move_and_slide()
            
            if direction.length() > 0.1:
                var look_pos = npc_base.global_position + direction
                look_pos.y = npc_base.global_position.y
                npc_base.look_at(look_pos, Vector3.UP)

func _handle_chasing(_delta):
    if not player:
        _change_state(State.SEARCHING)
        return
    
    var distance = npc_base.global_position.distance_to(player.global_position)
    
    if distance < 1.5 and not caught_player:
        # Caught the player!
        caught_player = true
        _on_player_caught()
        return
    
    # Use parent's navigation system if available
    var nav_system = npc_base.get_node_or_null("NavigationSystem")
    if nav_system:
        # If we're in a room and player is in hallway (or vice versa), go through door
        var riley_in_room = _is_inside_room()
        var player_x = abs(player.global_position.x)
        var player_in_room = player_x > 3.0
        
        if riley_in_room != player_in_room:
            # Need to go through a door
            var nearest_door = _find_nearest_room_exit()
            if nearest_door != Vector3.ZERO:
                var door_distance = npc_base.global_position.distance_to(nearest_door)
                if door_distance > 1.0:
                    # Navigate to door first
                    if not nav_system.is_navigating:
                        nav_system.navigate_to(nearest_door)
                    nav_system.open_nearby_doors()
                    npc_base.velocity = nav_system.get_next_velocity(npc_base.velocity, chase_speed)
                    if npc_base.velocity.length() > 0.1:
                        var door_look_pos = npc_base.global_position + npc_base.velocity.normalized()
                        door_look_pos.y = npc_base.global_position.y
                        npc_base.look_at(door_look_pos, Vector3.UP)
                    return
        
        # Navigate directly to player
        if not nav_system.is_navigating or player.global_position.distance_to(last_known_player_pos) > 2.0:
            nav_system.navigate_to(player.global_position)
            last_known_player_pos = player.global_position
        
        nav_system.open_nearby_doors()
        npc_base.velocity = nav_system.get_next_velocity(npc_base.velocity, chase_speed)
        
        # Look at player
        var look_pos = player.global_position
        look_pos.y = npc_base.global_position.y
        npc_base.look_at(look_pos, Vector3.UP)
    else:
        # Fallback to original logic
        # If we're in a room and player is in hallway (or vice versa), go through door
        var riley_in_room = _is_inside_room()
        var player_x = abs(player.global_position.x)
        var player_in_room = player_x > 3.0
        
        if riley_in_room != player_in_room:
            # Need to go through a door
            var nearest_door = _find_nearest_room_exit()
            if nearest_door != Vector3.ZERO:
                var door_distance = npc_base.global_position.distance_to(nearest_door)
                if door_distance > 1.0:
                    # Move to door first
                    _check_for_doors()
                    var door_direction = (nearest_door - npc_base.global_position).normalized()
                    door_direction.y = 0
                    npc_base.velocity = door_direction * chase_speed
                    npc_base.move_and_slide()
                    if door_direction.length() > 0.1:
                        var fallback_look_pos = npc_base.global_position + door_direction
                        fallback_look_pos.y = npc_base.global_position.y
                        npc_base.look_at(fallback_look_pos, Vector3.UP)
                    return
        
        # Check for doors when chasing
        _check_for_doors()
        
        # Direct chase
        var direction = (player.global_position - npc_base.global_position).normalized()
        direction.y = 0
        
        npc_base.velocity = direction * chase_speed
        npc_base.move_and_slide()
        
        # Look at player
        var look_pos = player.global_position
        look_pos.y = npc_base.global_position.y
        npc_base.look_at(look_pos, Vector3.UP)

func _handle_searching(delta):
    # Search last known position
    var distance = npc_base.global_position.distance_to(last_known_player_pos)
    
    if distance < 1.0:
        # Spin around looking for player
        npc_base.rotate_y(delta * 3.0)
        wait_timer += delta
        if wait_timer >= patrol_wait_time * 2:
            wait_timer = 0.0
            # print("Saboteur: They got away... for now.")
            _change_state(State.PATROLLING)
            _set_next_patrol_target()
    else:
        # Move to last known position
        var direction = (last_known_player_pos - npc_base.global_position).normalized()
        direction.y = 0
        
        npc_base.velocity = direction * patrol_speed
        npc_base.move_and_slide()

func _handle_sabotage(delta):
    # During sabotage, Saboteur moves to target while still detecting player
    if not sabotage_complete:
        var distance = npc_base.global_position.distance_to(sabotage_target)
        
        if distance < 1.5:
            # Reached sabotage location, perform sabotage
            sabotage_complete = true
            wait_timer = 0.0
            # print("SaboteurPatrolAI: Reached sabotage location, performing sabotage...")
            return
        
        # Move toward sabotage target (slower, more stealthy)
        var direction = (sabotage_target - npc_base.global_position).normalized()
        direction.y = 0
        
        # Use stealth speed if player nearby
        var move_speed = patrol_speed * 0.7  # Slower movement during sabotage
        if player:
            var player_distance = npc_base.global_position.distance_to(player.global_position)
            if player_distance < 8.0:
                move_speed *= 0.5  # Very slow when player is nearby
        
        npc_base.velocity = direction * move_speed
        npc_base.move_and_slide()
        
        # Face movement direction
        if direction.length() > 0.1:
            var look_pos = npc_base.global_position + direction
            look_pos.y = npc_base.global_position.y
            npc_base.look_at(look_pos, Vector3.UP)
    else:
        # Sabotage complete, wait briefly then return to normal patrol
        wait_timer += delta
        if wait_timer >= 3.0:  # Wait 3 seconds after completing sabotage
            # print("SaboteurPatrolAI: Sabotage complete, returning to patrol")
            sabotage_complete = false
            _change_state(State.PATROLLING)
            _set_next_patrol_target()

func _check_player_detection():
    var distance = npc_base.global_position.distance_to(player.global_position)
    
    # Check if in range
    if distance > detection_range:
        if current_state == State.CHASING:
            _change_state(State.SEARCHING)
            player_lost.emit()
        return
    
    # Check line of sight
    var space_state = npc_base.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        npc_base.global_position + Vector3.UP * 1.5,
        player.global_position + Vector3.UP * 1.0
    )
    query.exclude = [npc_base]
    query.collision_mask = 1  # Environment layer
    
    var result = space_state.intersect_ray(query)
    if result:
        # Something blocking view
        if current_state == State.CHASING:
            last_known_player_pos = player.global_position
            _change_state(State.SEARCHING)
            player_lost.emit()
        return
    
    # Check vision angle
    var to_player = (player.global_position - npc_base.global_position).normalized()
    var forward = -npc_base.global_transform.basis.z
    var angle = rad_to_deg(forward.angle_to(to_player))
    
    if angle <= vision_angle / 2.0:
        # Check player visibility (affected by hiding)
        var visibility_multiplier = 1.0
        if player.has_method("get_visibility_multiplier"):
            visibility_multiplier = player.get_visibility_multiplier()
        
        # Apply distance-based detection with visibility
        var detection_chance = (1.0 - (distance / detection_range)) * visibility_multiplier
        
        # Debug logging
        if current_state != State.CHASING and distance < 5.0:
            # Debug: Detection check
            pass #print("SaboteurPatrolAI: Detection check - Distance: ", distance, ", Angle: ", angle, ", Visibility: ", visibility_multiplier, ", Chance: ", detection_chance)")
        
        # Immediate detection if very close or not hidden
        if distance < 2.0:
            if current_state != State.CHASING:
                print("SaboteurPatrolAI: Player spotted! (very close - ", distance, " units)")
                _on_player_spotted()
        elif visibility_multiplier >= 0.95 and distance < 5.0:
            if current_state != State.CHASING:
                print("SaboteurPatrolAI: Player spotted! (fully visible at ", distance, " units)")
                _on_player_spotted()
        elif detection_chance > 0.5 and randf() < 0.3:  # 30% chance when detection is high
            if current_state != State.CHASING:
                print("SaboteurPatrolAI: Player spotted! (detection chance: ", detection_chance, ")")
                _on_player_spotted()

func _on_player_spotted():
    print("Saboteur: Target acquired! Stop right there!")
    _change_state(State.CHASING)
    player_spotted.emit(player.global_position)
    
    # Alert dialogue
    if npc_base.has_method("speak"):
        npc_base.speak("You can't escape! I know what you're up to!")

func _on_player_caught():
    print("Saboteur: Got you!")
    # Trigger game over or consequence
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager and game_manager.has_method("on_player_caught"):
        game_manager.on_player_caught()

func _change_state(new_state: State):
    current_state = new_state
    state_changed.emit(new_state)
    
    # Debug print
    print("SaboteurPatrolAI: State changed to ", State.keys()[new_state])
    
    # Reset caught flag when not chasing
    if new_state != State.CHASING:
        caught_player = false
    
    # Update state indicators
    match new_state:
        State.CHASING:
            if state_light:
                state_light.light_color = Color.RED
                state_light.light_energy = 3.0
            if state_label:
                state_label.text = "CHASING"
                state_label.modulate = Color.RED
        State.INVESTIGATING:
            if state_light:
                state_light.light_color = Color.YELLOW
                state_light.light_energy = 2.5
            if state_label:
                state_label.text = "INVESTIGATING"
                state_label.modulate = Color.YELLOW
        State.SEARCHING:
            if state_light:
                state_light.light_color = Color.ORANGE
                state_light.light_energy = 2.5
            if state_label:
                state_label.text = "SEARCHING"
                state_label.modulate = Color.ORANGE
        State.WAITING:
            if state_light:
                state_light.light_color = Color.CYAN
                state_light.light_energy = 1.5
            if state_label:
                state_label.text = "WAITING"
                state_label.modulate = Color.CYAN
        State.SABOTAGE:
            if state_light:
                state_light.light_color = Color.MAGENTA
                state_light.light_energy = 1.0
            if state_label:
                state_label.text = "SABOTAGE"
                state_label.modulate = Color.MAGENTA
        _:  # PATROLLING
            if state_light:
                state_light.light_color = Color.GREEN
                state_light.light_energy = 2.0
            if state_label:
                state_label.text = "PATROLLING"
                state_label.modulate = Color.GREEN

func _set_next_patrol_target():
    # Move to next room in route
    current_route_index = (current_route_index + 1) % patrol_route.size()
    current_room_phase = "hallway"
    # Debug: Moving to next location
    # print("SaboteurPatrolAI: Moving to next location: ", patrol_route[current_route_index])
    
func _update_patrol_target():
    var current_location = patrol_route[current_route_index]
    
    if current_location == "start":
        target_position = Vector3(0, 1.0, 15)
    elif current_location == "end":
        target_position = Vector3(0, 1.0, -25)
    elif rooms.has(current_location):
        var room = rooms[current_location]
        match current_room_phase:
            "hallway":
                target_position = room["hallway"]
            "door":
                target_position = room["door"]
            "inside":
                target_position = room["inside"]
            "exiting":
                target_position = room["door"]
    else:
        target_position = Vector3(0, 1.0, 0)  # Default to center
        
func _advance_patrol_phase():
    var current_location = patrol_route[current_route_index]
    
    # Special handling for start/end points
    if current_location == "start" or current_location == "end":
        _change_state(State.WAITING)
        return
        
    # Room phase progression
    match current_room_phase:
        "hallway":
            current_room_phase = "door"
            # Debug: Approaching door
            # print("SaboteurPatrolAI: Approaching door of ", current_location)
        "door":
            # Check if door is open before entering
            if _is_door_open_ahead():
                current_room_phase = "inside"
                # Debug: Entering location
                # print("SaboteurPatrolAI: Entering ", current_location)
            else:
                # print("SaboteurPatrolAI: Door closed, waiting...")
                _change_state(State.WAITING)
        "inside":
            current_room_phase = "exiting"
            # print("SaboteurPatrolAI: Checking ", current_location, ", now exiting")
            _change_state(State.WAITING)  # Brief pause to "investigate"
        "exiting":
            # Done with this room, move to next
            _set_next_patrol_target()
            
func _is_door_open_ahead() -> bool:
    # Check if there's an open door in front
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 1.0
    var to = from + (target_position - npc_base.global_position).normalized() * 2.0
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Interactable layer (doors)
    query.exclude = [npc_base]
    
    var result = space_state.intersect_ray(query)
    if result and result.collider.has_method("is_open"):
        return result.collider.is_open
    
    # No door found or can't check, assume path is clear
    return true

func investigate_position(pos: Vector3):
    investigation_target = pos
    _change_state(State.INVESTIGATING)
    wait_timer = 0.0
    print("SaboteurPatrolAI: Investigating position ", pos)

func _create_state_indicators():
    # Create overhead light
    state_light = OmniLight3D.new()
    state_light.light_color = Color.GREEN
    state_light.light_energy = 2.0
    state_light.omni_range = 5.0
    get_tree().current_scene.add_child(state_light)
    
    # Create debug label
    state_label = Label3D.new()
    state_label.text = "PATROLLING"
    state_label.modulate = Color.GREEN
    state_label.font_size = 16  # Much smaller
    state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    state_label.no_depth_test = true
    state_label.fixed_size = true
    state_label.pixel_size = 0.005  # Smaller pixel size
    get_tree().current_scene.add_child(state_label)

func on_sound_heard(position: Vector3):
    # Only respond to sounds if active (during night cycle)
    if not is_active:
        return
        
    var distance = npc_base.global_position.distance_to(position)
    if distance <= hearing_range and current_state != State.CHASING:
        print("Saboteur: What was that noise?")
        investigate_position(position)

func _is_inside_room() -> bool:
    # Check if Saboteur is inside any room (x < -3 or x > 3)
    var x_pos = abs(npc_base.global_position.x)
    return x_pos > 3.0

func _is_in_hallway() -> bool:
    # Check if Saboteur is in the main hallway (x between -2 and 2)
    var x_pos = abs(npc_base.global_position.x)
    return x_pos <= 2.0

func _find_nearest_room_exit() -> Vector3:
    # Find the nearest door position based on current location
    var current_pos = npc_base.global_position
    var nearest_door = Vector3.ZERO
    var min_distance = 999999.0
    
    # Check all room doors
    for room_name in rooms:
        var room = rooms[room_name]
        var door_pos = room["door"]
        var distance = current_pos.distance_to(door_pos)
        
        # Only consider doors that are reasonably close (same room)
        if distance < 10.0 and distance < min_distance:
            min_distance = distance
            nearest_door = door_pos
    
    return nearest_door

func _check_for_doors():
    # Cast ray forward to check for doors
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 1.0
    var to = from - npc_base.global_transform.basis.z * 2.0  # 2 units forward
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Interactable layer
    query.exclude = [npc_base]
    
    var result = space_state.intersect_ray(query)
    if result and result.collider.has_method("interact"):
        # Check if it's a door
        if result.collider.has_method("get_interaction_prompt"):
            var prompt = result.collider.get_interaction_prompt()
            if "door" in prompt.to_lower():
                print("SaboteurPatrolAI: Opening door")
                result.collider.interact()

func set_active(active: bool):
    is_active = active
    set_physics_process(active)  # Enable/disable physics processing
    print("SaboteurPatrolAI: Set active to ", active)
    
    if not active:
        # Stop all movement
        if npc_base:
            npc_base.velocity = Vector3.ZERO
        # Hide all visualizations
        if state_light:
            state_light.visible = false
        if state_label:
            state_label.visible = false
        if awareness_sphere:
            awareness_sphere.visible = false
        if vision_cone_mesh:
            vision_cone_mesh.visible = false
        if sound_detection_sphere:
            sound_detection_sphere.visible = false
        if patrol_path_line:
            patrol_path_line.visible = false
    else:
        # Always create visualizations when activating (they will be shown/hidden based on settings)
        if not state_light:
            _create_state_indicators()
        if not awareness_sphere:
            _create_awareness_visualization()
        if not sound_detection_sphere:
            _create_sound_detection_visualization()
        if not patrol_path_line:
            _create_patrol_path_visualization()
            
        # Show visualizations based on current settings
        if state_light:
            state_light.visible = show_state_indicators
        if state_label:
            state_label.visible = show_state_indicators
        if awareness_sphere:
            awareness_sphere.visible = show_awareness_sphere
        if vision_cone_mesh:
            vision_cone_mesh.visible = show_vision_cone
        if sound_detection_sphere:
            sound_detection_sphere.visible = show_sound_detection
        if patrol_path_line:
            patrol_path_line.visible = show_patrol_path
            
        # Start patrolling when activated
        _change_state(State.PATROLLING)
        _set_next_patrol_target()

func start_sabotage_mission(sabotage_position: Vector3):
    print("SaboteurPatrolAI: Starting sabotage mission to ", sabotage_position)
    sabotage_target = sabotage_position
    sabotage_complete = false
    wait_timer = 0.0
    _change_state(State.SABOTAGE)

func end_sabotage_mission():
    print("SaboteurPatrolAI: Ending sabotage mission, returning to patrol")
    _change_state(State.PATROLLING)
    _set_next_patrol_target()
    sabotage_complete = false

func _create_awareness_visualization():
    # Create awareness sphere if enabled
    if show_awareness_sphere:
        awareness_sphere = MeshInstance3D.new()
        awareness_sphere.name = "AwarenessSphere"
        
        var sphere_mesh = SphereMesh.new()
        sphere_mesh.radial_segments = 16
        sphere_mesh.rings = 8
        sphere_mesh.radius = detection_range
        sphere_mesh.height = detection_range * 2
        awareness_sphere.mesh = sphere_mesh
        
        # Create wireframe material
        var sphere_material = StandardMaterial3D.new()
        sphere_material.albedo_color = Color(0, 1, 0, 0.2)
        sphere_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        sphere_material.vertex_color_use_as_albedo = true
        sphere_material.no_depth_test = true
        sphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        sphere_material.cull_mode = BaseMaterial3D.CULL_DISABLED
        
        awareness_sphere.material_override = sphere_material
        awareness_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        
        npc_base.add_child(awareness_sphere)
    
    # Create vision cone if enabled
    if show_vision_cone:
        vision_cone_mesh = MeshInstance3D.new()
        vision_cone_mesh.name = "VisionCone"
        
        # Create a simple pyramid mesh for vision cone
        var arrays = []
        arrays.resize(Mesh.ARRAY_MAX)
        
        var vertices = PackedVector3Array()
        
        # Vision cone vertices
        var cone_length = detection_range * 0.8
        var cone_width = tan(deg_to_rad(vision_angle / 2)) * cone_length
        
        vertices.push_back(Vector3.ZERO)  # Origin
        vertices.push_back(Vector3(-cone_width, 0, -cone_length))  # Left
        vertices.push_back(Vector3(cone_width, 0, -cone_length))   # Right
        vertices.push_back(Vector3(0, cone_width, -cone_length))    # Top
        vertices.push_back(Vector3(0, -cone_width, -cone_length))   # Bottom
        
        # Create triangles for the cone
        var indices = PackedInt32Array([
            0, 1, 2,  # Horizontal plane
            0, 3, 4,  # Vertical plane
            0, 1, 3,  # Left-top
            0, 3, 2,  # Right-top
            0, 2, 4,  # Right-bottom
            0, 4, 1   # Left-bottom
        ])
        
        arrays[Mesh.ARRAY_VERTEX] = vertices
        arrays[Mesh.ARRAY_INDEX] = indices
        
        var array_mesh = ArrayMesh.new()
        array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
        
        vision_cone_mesh.mesh = array_mesh
        
        # Create vision cone material
        var cone_material = StandardMaterial3D.new()
        cone_material.albedo_color = Color(1, 1, 0, 0.15)
        cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        cone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        cone_material.no_depth_test = true
        cone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
        
        vision_cone_mesh.material_override = cone_material
        vision_cone_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        vision_cone_mesh.position.y = 1.5  # Eye level
        
        npc_base.add_child(vision_cone_mesh)

func _update_awareness_visualization():
    if not awareness_sphere or not vision_cone_mesh:
        return
    
    # Update colors based on state
    var sphere_material = awareness_sphere.material_override as StandardMaterial3D
    var cone_material = vision_cone_mesh.material_override as StandardMaterial3D
    
    if not sphere_material or not cone_material:
        return
    
    match current_state:
        State.CHASING:
            sphere_material.albedo_color = Color(1, 0, 0, 0.3)
            cone_material.albedo_color = Color(1, 0, 0, 0.3)
        State.INVESTIGATING:
            sphere_material.albedo_color = Color(1, 1, 0, 0.25)
            cone_material.albedo_color = Color(1, 1, 0, 0.25)
        State.SEARCHING:
            sphere_material.albedo_color = Color(1, 0.5, 0, 0.25)
            cone_material.albedo_color = Color(1, 0.5, 0, 0.25)
        State.SABOTAGE:
            sphere_material.albedo_color = Color(1, 0, 1, 0.2)
            cone_material.albedo_color = Color(1, 0, 1, 0.2)
        _:  # PATROLLING or WAITING
            sphere_material.albedo_color = Color(0, 1, 0, 0.2)
            cone_material.albedo_color = Color(1, 1, 0, 0.15)
    
    # Show vision cone based on state and debug settings
    if show_vision_cone:
        vision_cone_mesh.visible = current_state != State.WAITING
    else:
        vision_cone_mesh.visible = false

func get_current_state_name() -> String:
    return State.keys()[current_state]

func _create_sound_detection_visualization():
    """Create a sphere to show sound detection radius"""
    sound_detection_sphere = MeshInstance3D.new()
    sound_detection_sphere.name = "SoundDetectionSphere"
    
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 16
    sphere_mesh.rings = 8
    sphere_mesh.radius = hearing_range
    sphere_mesh.height = hearing_range * 2
    sound_detection_sphere.mesh = sphere_mesh
    
    # Create material for sound detection
    var sound_material = StandardMaterial3D.new()
    sound_material.albedo_color = Color(0, 0.5, 1, 0.15)  # Blue for sound
    sound_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    sound_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    sound_material.no_depth_test = true
    sound_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    
    sound_detection_sphere.material_override = sound_material
    sound_detection_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    
    npc_base.add_child(sound_detection_sphere)

func _create_patrol_path_visualization():
    """Create lines showing the patrol path"""
    patrol_path_line = MeshInstance3D.new()
    patrol_path_line.name = "PatrolPathLine"
    
    # Update the patrol path when the route changes
    _update_patrol_path_visualization()
    
    get_tree().current_scene.add_child(patrol_path_line)

func _update_patrol_path_visualization():
    """Update the patrol path lines"""
    if not patrol_path_line or not show_patrol_path:
        return
    
    # Create line mesh for patrol route
    var vertices = PackedVector3Array()
    
    # Add all patrol points
    for location in patrol_route:
        var pos: Vector3
        if location == "start":
            pos = Vector3(0, 1.0, 15)
        elif location == "end":
            pos = Vector3(0, 1.0, -25)
        elif rooms.has(location):
            # Show path through room (hallway -> door -> inside -> door -> hallway)
            var room = rooms[location]
            vertices.append(room["hallway"])
            vertices.append(room["door"])
            vertices.append(room["inside"])
            vertices.append(room["door"])
            vertices.append(room["hallway"])
        else:
            pos = Vector3(0, 1.0, 0)
        
        if location == "start" or location == "end":
            vertices.append(pos)
    
    if vertices.size() < 2:
        return
    
    # Create line segments
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    
    var line_vertices = PackedVector3Array()
    for i in range(vertices.size() - 1):
        line_vertices.append(vertices[i])
        line_vertices.append(vertices[i + 1])
    
    arrays[Mesh.ARRAY_VERTEX] = line_vertices
    
    var array_mesh = ArrayMesh.new()
    array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
    
    patrol_path_line.mesh = array_mesh
    
    # Create material for the path
    var path_material = StandardMaterial3D.new()
    path_material.albedo_color = Color(1, 0, 1, 0.8)  # Magenta for path
    path_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    path_material.vertex_color_use_as_albedo = true
    
    patrol_path_line.material_override = path_material

func set_debug_visualization(awareness: bool, vision: bool, state: bool, path: bool, sound: bool):
    """Update debug visualization settings"""
    print("SaboteurPatrolAI: Setting debug visualization - awareness:", awareness, " vision:", vision, " state:", state, " path:", path, " sound:", sound)
    print("  Current is_active:", is_active)
    
    show_awareness_sphere = awareness
    show_vision_cone = vision
    show_state_indicators = state
    show_patrol_path = path
    show_sound_detection = sound
    
    # Create visualizations if they don't exist and AI is active
    if is_active:
        if not state_light and (state or not (awareness or vision or path or sound)):
            print("  Creating state indicators")
            _create_state_indicators()
        if not awareness_sphere and (awareness or vision):
            print("  Creating awareness visualization")
            _create_awareness_visualization()
        if not sound_detection_sphere and sound:
            print("  Creating sound detection visualization")
            _create_sound_detection_visualization()
        if not patrol_path_line and path:
            print("  Creating patrol path visualization")
            _create_patrol_path_visualization()
    
    # Update visibility of existing visualizations
    if awareness_sphere:
        awareness_sphere.visible = show_awareness_sphere and is_active
        print("  Awareness sphere visible:", awareness_sphere.visible)
    if vision_cone_mesh:
        vision_cone_mesh.visible = show_vision_cone and is_active
        print("  Vision cone visible:", vision_cone_mesh.visible)
    if state_light:
        state_light.visible = show_state_indicators and is_active
        print("  State light visible:", state_light.visible)
    if state_label:
        state_label.visible = show_state_indicators and is_active
        print("  State label visible:", state_label.visible)
    if patrol_path_line:
        patrol_path_line.visible = show_patrol_path and is_active
        print("  Patrol path visible:", patrol_path_line.visible)
    if sound_detection_sphere:
        sound_detection_sphere.visible = show_sound_detection and is_active
        print("  Sound detection visible:", sound_detection_sphere.visible)
