extends Node
class_name RileyPatrolAI

@export var patrol_speed: float = 4.0
@export var chase_speed: float = 6.0
@export var detection_range: float = 15.0
@export var vision_angle: float = 60.0  # Degrees
@export var hearing_range: float = 10.0
@export var patrol_wait_time: float = 3.0

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

# States
enum State {
    PATROLLING,
    WAITING,
    INVESTIGATING,
    CHASING,
    SEARCHING
}

var current_state: State = State.PATROLLING

signal player_spotted(player_position: Vector3)
signal player_lost()
signal state_changed(new_state: State)

func _ready():
    print("RileyPatrolAI: Starting initialization")
    npc_base = get_parent()
    if not npc_base:
        push_error("RileyPatrolAI must be child of NPCBase")
        return
    
    print("RileyPatrolAI: Found parent NPC: ", npc_base.npc_name)
    
    # Add to riley patrol group
    add_to_group("riley_patrol")
    
    # Create navigation agent
    navigation_agent = NavigationAgent3D.new()
    npc_base.add_child(navigation_agent)
    navigation_agent.path_desired_distance = 0.5
    navigation_agent.target_desired_distance = 1.0
    
    # Wait for navigation to be ready
    await get_tree().physics_frame
    
    # Find player
    player = get_tree().get_first_node_in_group("player")
    if player:
        print("RileyPatrolAI: Found player")
    else:
        push_warning("RileyPatrolAI: Player not found!")
    
    # Create state indicators
    _create_state_indicators()
    
    # Start patrolling
    print("RileyPatrolAI: Starting patrol route")
    current_route_index = 0
    current_room_phase = "hallway"
    _update_patrol_target()
    
    # Override parent's movement
    if npc_base.has_method("_physics_process"):
        npc_base.set_physics_process(false)
    
    print("RileyPatrolAI: Initialization complete, current state: ", State.keys()[current_state])

func _physics_process(delta):
    if not npc_base:
        print("RileyPatrolAI: ERROR - npc_base is null!")
        return
    
    if not navigation_agent:
        print("RileyPatrolAI: WARNING - navigation_agent is null, using direct movement")
    
    # Update state indicators position
    if state_light:
        state_light.global_position = npc_base.global_position + Vector3.UP * 2.5
    if state_label:
        state_label.global_position = npc_base.global_position + Vector3.UP * 3.0
    
    # Check for player detection
    if player:
        _check_player_detection()
        
        # Extra check for very close range (touching)
        var touch_distance = npc_base.global_position.distance_to(player.global_position)
        if touch_distance < 1.2 and current_state != State.CHASING:
            print("RileyPatrolAI: Player touched Riley! Immediate detection!")
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

func _handle_patrolling(_delta):
    # Get current target based on route
    _update_patrol_target()
    
    var distance = npc_base.global_position.distance_to(target_position)
    
    if distance < 1.0:
        # Reached current target, advance to next phase
        _advance_patrol_phase()
        return
    
    # Always check for doors when moving
    _check_for_doors()
    
    # Move towards target
    var direction = (target_position - npc_base.global_position).normalized()
    direction.y = 0
    
    # Simple movement - stay in hallways unless entering a room
    npc_base.velocity = direction * patrol_speed
    npc_base.move_and_slide()
    
    # Rotate to face movement direction
    if direction.length() > 0.1:
        var look_pos = npc_base.global_position + direction
        look_pos.y = npc_base.global_position.y
        npc_base.look_at(look_pos, Vector3.UP)

func _handle_waiting(delta):
    wait_timer += delta
    if wait_timer >= patrol_wait_time:
        wait_timer = 0.0
        _set_next_patrol_target()
        _change_state(State.PATROLLING)

func _handle_investigating(delta):
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
    
    if distance < 1.5:
        # Caught the player!
        _on_player_caught()
        return
    
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
                var direction = (nearest_door - npc_base.global_position).normalized()
                direction.y = 0
                npc_base.velocity = direction * chase_speed
                npc_base.move_and_slide()
                if direction.length() > 0.1:
                    var look_pos = npc_base.global_position + direction
                    look_pos.y = npc_base.global_position.y
                    npc_base.look_at(look_pos, Vector3.UP)
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
            print("Riley: They got away... for now.")
            _change_state(State.PATROLLING)
            _set_next_patrol_target()
    else:
        # Move to last known position
        var direction = (last_known_player_pos - npc_base.global_position).normalized()
        direction.y = 0
        
        npc_base.velocity = direction * patrol_speed
        npc_base.move_and_slide()

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
            print("RileyPatrolAI: Detection check - Distance: ", distance, ", Angle: ", angle, ", Visibility: ", visibility_multiplier, ", Chance: ", detection_chance)
        
        # Immediate detection if very close or not hidden
        if distance < 2.0:
            if current_state != State.CHASING:
                print("RileyPatrolAI: Player spotted! (very close - ", distance, " units)")
                _on_player_spotted()
        elif visibility_multiplier >= 0.95 and distance < 5.0:
            if current_state != State.CHASING:
                print("RileyPatrolAI: Player spotted! (fully visible at ", distance, " units)")
                _on_player_spotted()
        elif detection_chance > 0.5 and randf() < 0.3:  # 30% chance when detection is high
            if current_state != State.CHASING:
                print("RileyPatrolAI: Player spotted! (detection chance: ", detection_chance, ")")
                _on_player_spotted()

func _on_player_spotted():
    print("Riley: Target acquired! Stop right there!")
    _change_state(State.CHASING)
    player_spotted.emit(player.global_position)
    
    # Alert dialogue
    if npc_base.has_method("speak"):
        npc_base.speak("You can't escape! I know what you're up to!")

func _on_player_caught():
    print("Riley: Got you!")
    # Trigger game over or consequence
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager and game_manager.has_method("on_player_caught"):
        game_manager.on_player_caught()

func _change_state(new_state: State):
    current_state = new_state
    state_changed.emit(new_state)
    
    # Debug print
    print("RileyPatrolAI: State changed to ", State.keys()[new_state])
    
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
    print("RileyPatrolAI: Moving to next location: ", patrol_route[current_route_index])
    
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
            print("RileyPatrolAI: Approaching door of ", current_location)
        "door":
            # Check if door is open before entering
            if _is_door_open_ahead():
                current_room_phase = "inside"
                print("RileyPatrolAI: Entering ", current_location)
            else:
                print("RileyPatrolAI: Door closed, waiting...")
                _change_state(State.WAITING)
        "inside":
            current_room_phase = "exiting"
            print("RileyPatrolAI: Checking ", current_location, ", now exiting")
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
    print("RileyPatrolAI: Investigating position ", pos)

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
    var distance = npc_base.global_position.distance_to(position)
    if distance <= hearing_range and current_state != State.CHASING:
        print("Riley: What was that noise?")
        investigate_position(position)

func _is_inside_room() -> bool:
    # Check if Riley is inside any room (x < -3 or x > 3)
    var x_pos = abs(npc_base.global_position.x)
    return x_pos > 3.0

func _is_in_hallway() -> bool:
    # Check if Riley is in the main hallway (x between -2 and 2)
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
                print("RileyPatrolAI: Opening door")
                result.collider.interact()
