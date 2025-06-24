extends Node
class_name SaboteurOverride

# This script uses the NPC's navigation but controls when to move

@export_group("Vision Settings")
@export var vision_distance: float = 15.0  # How far the saboteur can see
@export var vision_angle: float = 70.0  # FOV in degrees (human is ~70-90)
@export var vision_height: float = 1.6  # Eye height
@export var show_vision_cone: bool = true  # Debug visualization

@export_group("Sound Settings")
@export var hearing_range: float = 20.0  # How far sounds can be heard
@export var running_noise_multiplier: float = 1.5  # Running is louder
@export var walking_noise_base: float = 10.0  # Base walking detection range
@export var crouching_noise_multiplier: float = 0.3  # Crouching is quieter
@export var show_sound_detection: bool = false  # Debug visualization

var npc_base: NPCBase
var wait_time: float = 5.0
var wait_timer: float = 0.0
var is_waiting: bool = true  # Start waiting
var current_room: String = ""

# Room waypoint names that match the waypoint system
var room_waypoints = [
    "Laboratory_Center",
    "MedicalBay_Center",
    "Security_Center",
    "Engineering_Center",
    "CrewQuarters_Center",
    "Cafeteria_Center"
]

# Visual indicators
var state_label: Label3D
var vision_cone_container: Node3D  # Container for cone and line
var vision_cone_mesh: MeshInstance3D  # The actual cone mesh
var sound_sphere_mesh: MeshInstance3D  # Sound detection sphere
var walking_range_mesh: MeshInstance3D  # Walking detection range
var running_range_mesh: MeshInstance3D  # Running detection range
var sound_marker: MeshInstance3D  # Marker for sound location

# Detection
var player: Node3D = null
var player_detected: bool = false
var last_seen_position: Vector3 = Vector3.ZERO
var time_since_seen: float = 0.0

# Sound detection
var sound_detected: bool = false
var sound_position: Vector3 = Vector3.ZERO
var investigating_sound: bool = false
var sound_investigation_time: float = 0.0
var max_investigation_time: float = 5.0  # Time to investigate before giving up

func _ready():
    npc_base = get_parent() as NPCBase
    if not npc_base:
        push_error("SaboteurOverride must be child of NPCBase")
        queue_free()
        return
    
    # Disable schedules but keep NPC movement system
    if "use_schedule" in npc_base:
        npc_base.use_schedule = false
    
    # Disable all interaction behaviors
    if "react_to_player_proximity" in npc_base:
        npc_base.react_to_player_proximity = false
    
    # Disable dialogue
    npc_base.set_collision_layer_value(2, false)  # Remove from interactable layer
    
    # Disable any talk/idle behaviors
    if "idle_trigger_distance" in npc_base:
        npc_base.idle_trigger_distance = 0.0
    if "talk_trigger_distance" in npc_base:
        npc_base.talk_trigger_distance = 0.0
    
    # Enable path visualization
    if "show_waypoint_path" in npc_base:
        npc_base.show_waypoint_path = true
        print("SaboteurOverride: Enabled path visualization")
    
    # Update appearance
    var name_label = npc_base.get_node_or_null("Head/NameLabel")
    if name_label:
        name_label.text = "Unknown Figure"
    
    var role_label = npc_base.get_node_or_null("Head/RoleLabel")
    if role_label:
        role_label.visible = false
    
    # Dark appearance
    var mesh = npc_base.get_node_or_null("MeshInstance3D")
    if mesh:
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.1, 0.1, 0.1)
        material.emission_enabled = true
        material.emission = Color(0.8, 0.2, 0.2)
        material.emission_energy = 0.3
        mesh.material_override = material
    
    # Disable dialogue system if present
    var dialogue = npc_base.get_node_or_null("DialogueSystem")
    if dialogue:
        dialogue.set_process(false)
        dialogue.set_physics_process(false)
        if dialogue.has_method("set_enabled"):
            dialogue.set_enabled(false)
    
    # Create state label
    _create_state_label()
    
    # Create vision cone visualization
    _create_vision_cone()
    
    # Create sound detection visualization
    _create_sound_detection()
    
    # Find player
    player = get_tree().get_first_node_in_group("player")
    
    # Wait a moment before starting
    await get_tree().create_timer(1.0).timeout
    
    # Start patrolling
    _pick_new_target()
    
    print("SaboteurOverride: Taking control of ", npc_base.name)

func _process(delta):
    if not npc_base:
        return
    
    # Check for player detection
    _check_player_detection()
    
    # Check for sound detection
    _check_sound_detection()
    
    # Update detection timer
    if player_detected:
        time_since_seen = 0.0
    else:
        time_since_seen += delta
    
    # Handle sound investigation timer only when at location
    if investigating_sound and is_waiting:  # Only count investigation time when waiting at the location
        sound_investigation_time += delta
        if sound_investigation_time >= max_investigation_time:
            # Give up investigating
            investigating_sound = false
            sound_detected = false
            sound_investigation_time = 0.0
            if sound_marker and show_sound_detection:
                sound_marker.visible = false
            print("SaboteurOverride: No one found at sound location, resuming patrol")
    
    # Update investigation distance
    if investigating_sound and npc_base.is_moving and sound_position != Vector3.ZERO:
        var dist = npc_base.global_position.distance_to(sound_position)
        _update_state_label("INVESTIGATING SOUND [" + str(snappedf(dist, 0.1)) + "m]")
    
    # Check if NPC has finished moving
    if not npc_base.is_moving and not is_waiting:
        # Reached destination
        if investigating_sound:
            print("SaboteurOverride: Reached sound location, investigating...")
            is_waiting = true
            wait_timer = 0.0
            _update_state_label("SEARCHING AT SOUND")
        else:
            print("SaboteurOverride: Reached destination")
            is_waiting = true
            wait_timer = 0.0
            _update_state_label("WAITING at " + current_room.replace("_Center", ""))
    
    # Handle waiting
    if is_waiting:
        wait_timer += delta
        var wait_duration = 2.0 if investigating_sound else wait_time  # Shorter wait when investigating
        if wait_timer >= wait_duration:
            is_waiting = false
            wait_timer = 0.0
            if investigating_sound:
                # Done investigating, resume patrol
                investigating_sound = false
                sound_detected = false
                if sound_marker and show_sound_detection:
                    sound_marker.visible = false
            _pick_new_target()
    
    # Update label position
    if state_label:
        state_label.global_position = npc_base.global_position + Vector3.UP * 2.5
    
    # Update vision cone position and rotation
    if vision_cone_container:
        # Since it's now a child of NPC, use local position
        vision_cone_container.position = Vector3.UP * vision_height
        vision_cone_container.rotation = Vector3.ZERO  # Inherits NPC rotation
        
        # Update cone color based on detection
        if vision_cone_mesh and vision_cone_mesh.material_override:
            var mat = vision_cone_mesh.material_override as StandardMaterial3D
            if player_detected:
                mat.albedo_color = Color(1, 0.5, 0, 0.3)  # Orange when detected
            else:
                mat.albedo_color = Color(0, 1, 0, 0.3)  # Green when not detected
        
        # Update range line
        var line_mesh = vision_cone_container.get_meta("range_line", null) as MeshInstance3D
        if line_mesh and line_mesh.mesh is ImmediateMesh:
            var immediate = line_mesh.mesh as ImmediateMesh
            immediate.clear_surfaces()
            immediate.surface_begin(Mesh.PRIMITIVE_LINES)
            immediate.surface_set_color(Color(1, 0, 1, 1))  # Magenta
            # Draw multiple lines slightly offset to make it appear thicker
            for offset in [Vector3.ZERO, Vector3(0.05, 0, 0), Vector3(-0.05, 0, 0), Vector3(0, 0.05, 0)]:
                immediate.surface_add_vertex(Vector3(0, -vision_height, 0) + offset)  # At feet
                immediate.surface_add_vertex(Vector3(0, -vision_height, -vision_distance) + offset)  # End of range
            immediate.surface_end()
    
    # Check for doors while moving
    if npc_base.is_moving:
        _check_for_doors()

func _pick_new_target():
    # Get available rooms excluding current
    var available = []
    for room in room_waypoints:
        if room != current_room:
            available.append(room)
    
    if available.is_empty():
        available = room_waypoints.duplicate()
    
    # Pick random room
    current_room = available[randi() % available.size()]
    
    print("SaboteurOverride: Navigating to ", current_room)
    
    # Use the NPC's navigation system
    if npc_base.has_method("navigate_to_room"):
        if npc_base.navigate_to_room(current_room):
            is_waiting = false
            print("SaboteurOverride: Navigation started successfully")
            _update_state_label("PATROLLING to " + current_room.replace("_Center", ""))
        else:
            print("SaboteurOverride: Navigation failed, will retry")
            is_waiting = true
            wait_timer = wait_time - 1.0  # Retry soon

func _create_state_label():
    state_label = Label3D.new()
    state_label.text = "SABOTEUR - WAITING"
    state_label.modulate = Color.RED
    state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    state_label.no_depth_test = true
    state_label.font_size = 16
    state_label.outline_size = 4
    state_label.outline_modulate = Color.BLACK
    get_tree().current_scene.add_child(state_label)

func _update_state_label(text: String):
    if state_label:
        state_label.text = "SABOTEUR - " + text
        if player_detected:
            state_label.text += " [!PLAYER SPOTTED!]"
            state_label.modulate = Color(1, 0.2, 0.2)  # Bright red when player detected
        elif investigating_sound:
            state_label.modulate = Color.YELLOW  # Yellow when investigating sound
            if sound_position != Vector3.ZERO:
                state_label.text += "\n→ " + str(sound_position.round())
        elif is_waiting:
            state_label.modulate = Color.CYAN
        else:
            state_label.modulate = Color.RED

func _check_for_doors():
    # Check for doors in multiple directions
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 1.0
    
    # Check in movement direction and forward
    var directions = []
    
    # Add velocity direction if moving
    if npc_base.velocity.length() > 0.1:
        directions.append(npc_base.velocity.normalized())
    
    # Always check forward
    directions.append(-npc_base.global_transform.basis.z)
    
    # Also check to the sides
    directions.append(npc_base.global_transform.basis.x)
    directions.append(-npc_base.global_transform.basis.x)
    
    for direction in directions:
        for distance in [1.5, 2.5, 3.5]:
            var to = from + direction * distance
            
            var query = PhysicsRayQueryParameters3D.create(from, to)
            query.collision_mask = 3  # Check both environment (1) and interactable (2) layers
            query.exclude = [npc_base]
            
            var result = space_state.intersect_ray(query)
            if result:
                # Check if it's a door
                if result.collider is SlidingDoor:
                    var door = result.collider as SlidingDoor
                    if not door.is_open and not door.is_moving:
                        print("SaboteurOverride: Triggering door - ", door.door_name)
                        # For automatic doors, trigger the detection instead of interact
                        if door.is_powered:
                            # Add ourselves to the detection area manually
                            door._on_body_entered(npc_base)
                        else:
                            # Manual door, use interact
                            door.interact()
                        return

func _create_vision_cone():
    if not show_vision_cone:
        return
    
    vision_cone_mesh = MeshInstance3D.new()
    vision_cone_mesh.name = "VisionCone"
    
    # Use a simple CylinderMesh rotated to create a cone
    var cone = CylinderMesh.new()
    cone.height = vision_distance
    cone.top_radius = 0.1
    cone.bottom_radius = vision_distance * tan(deg_to_rad(vision_angle / 2.0))
    cone.radial_segments = 32
    cone.rings = 1
    vision_cone_mesh.mesh = cone
    
    # Position and rotate the cone
    vision_cone_mesh.rotation.x = PI/2  # Point forward (positive rotation)
    vision_cone_mesh.position.z = -vision_distance/2  # Center it
    
    # Create material for the cone
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0, 1, 0, 0.3)  # Start with green (no detection)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.no_depth_test = true
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    vision_cone_mesh.material_override = mat
    
    # Add to scene as a container
    vision_cone_container = Node3D.new()
    vision_cone_container.name = "VisionConeContainer"
    npc_base.add_child(vision_cone_container)  # Add to NPC, not scene
    vision_cone_container.add_child(vision_cone_mesh)
    
    # Keep the mesh reference as is
    
    # Create a separate line mesh for the range indicator
    var line_mesh = MeshInstance3D.new()
    line_mesh.name = "VisionRangeLine"
    
    # Create line using ImmediateMesh
    var immediate_mesh = ImmediateMesh.new()
    line_mesh.mesh = immediate_mesh
    
    # Create line material
    var line_mat = StandardMaterial3D.new()
    line_mat.albedo_color = Color(1, 0, 1, 1)  # Magenta
    line_mat.emission_enabled = true
    line_mat.emission = Color(1, 0, 1)
    line_mat.emission_energy = 2.0
    line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    line_mat.vertex_color_use_as_albedo = true
    line_mat.no_depth_test = true
    line_mesh.material_override = line_mat
    
    # Add as child of cone container so it moves together
    vision_cone_container.add_child(line_mesh)
    
    # Store reference for updating
    vision_cone_container.set_meta("range_line", line_mesh)

func _check_player_detection():
    if not player:
        player = get_tree().get_first_node_in_group("player")
        if not player:
            return
    
    # Get positions
    var eye_pos = npc_base.global_position + Vector3.UP * vision_height
    var player_pos = player.global_position + Vector3.UP * 0.9  # Player center of mass
    
    # Check distance
    var distance = eye_pos.distance_to(player_pos)
    if distance > vision_distance:
        player_detected = false
        return
    
    # Check angle
    var to_player = (player_pos - eye_pos).normalized()
    var forward = -npc_base.global_transform.basis.z
    var angle = rad_to_deg(forward.angle_to(to_player))
    
    if angle > vision_angle / 2.0:
        player_detected = false
        return
    
    # Check line of sight
    var space_state = npc_base.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(eye_pos, player_pos)
    query.collision_mask = 1  # Environment layer only
    query.exclude = [npc_base]
    
    var result = space_state.intersect_ray(query)
    if result:
        # Something blocking the view
        player_detected = false
        return
    
    # Player is detected!
    if not player_detected:
        print("SaboteurOverride: PLAYER DETECTED at distance ", distance, "m")
        last_seen_position = player_pos
    
    player_detected = true

func _create_sound_detection():
    # Always create the sphere, just hide it if not debugging
    
    # Create sound detection sphere
    sound_sphere_mesh = MeshInstance3D.new()
    sound_sphere_mesh.name = "SoundDetectionSphere"
    
    var sphere = SphereMesh.new()
    sphere.radius = hearing_range
    sphere.height = hearing_range * 2
    sphere.radial_segments = 32
    sphere.rings = 16
    sound_sphere_mesh.mesh = sphere
    
    # Create material
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0, 0.5, 1, 0.1)  # Light blue
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.no_depth_test = true
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    sound_sphere_mesh.material_override = mat
    
    npc_base.add_child(sound_sphere_mesh)
    sound_sphere_mesh.visible = show_sound_detection
    
    # Create sound marker
    sound_marker = MeshInstance3D.new()
    sound_marker.name = "SoundMarker"
    
    var marker_mesh = SphereMesh.new()
    marker_mesh.radius = 0.5
    marker_mesh.height = 1.0
    sound_marker.mesh = marker_mesh
    
    var marker_mat = StandardMaterial3D.new()
    marker_mat.albedo_color = Color(1, 1, 0, 0.8)  # Yellow
    marker_mat.emission_enabled = true
    marker_mat.emission = Color(1, 1, 0)
    marker_mat.emission_energy = 2.0
    marker_mat.no_depth_test = true
    sound_marker.material_override = marker_mat
    
    get_tree().current_scene.add_child(sound_marker)
    sound_marker.visible = false

func _check_sound_detection():
    if not player or player_detected:  # Don't check sound if already seeing player
        return
    
    var player_controller = player
    if not player_controller:
        return
    
    # Calculate distance
    var distance = npc_base.global_position.distance_to(player.global_position)
    
    # Determine player movement state and noise level
    var noise_range = 0.0
    var is_crouching = false
    var is_sprinting = false
    
    # Check player states (assuming player controller has these)
    if "is_crouching" in player_controller:
        is_crouching = player_controller.is_crouching
    if "is_sprinting" in player_controller:
        is_sprinting = player_controller.is_sprinting
    
    # Check if player is moving
    var player_velocity = Vector3.ZERO
    if player_controller.has_method("get_velocity"):
        player_velocity = player_controller.get_velocity()
    elif "velocity" in player_controller:
        player_velocity = player_controller.velocity
    
    var is_moving = player_velocity.length() > 0.1
    
    if not is_moving:
        return  # No sound if not moving
    
    # Calculate noise range based on movement type
    if is_crouching:
        noise_range = walking_noise_base * crouching_noise_multiplier
    elif is_sprinting:
        noise_range = walking_noise_base * running_noise_multiplier
    else:
        noise_range = walking_noise_base
    
    # Check if within hearing range
    if distance <= noise_range and distance <= hearing_range:
        # Sound detected!
        var new_sound_pos = player.global_position
        
        # Always update sound position if player moved
        if not sound_detected or new_sound_pos.distance_to(sound_position) > 1.0:
            # New sound or significant position change
            sound_detected = true
            sound_position = new_sound_pos
            
            print("SaboteurOverride: SOUND DETECTED at ", sound_position, " (", 
                  "crouching" if is_crouching else ("running" if is_sprinting else "walking"), 
                  ", range: ", noise_range, "m)")
            
            # Always navigate to new sound position
            _investigate_sound(sound_position)
            
            # Update marker
            if sound_marker:
                sound_marker.global_position = sound_position + Vector3.UP * 0.5
                sound_marker.visible = show_sound_detection  # Only show if debug is on

func _investigate_sound(position: Vector3):
    # Always update to the latest sound position
    
    # Interrupt current movement
    npc_base.stop_movement()
    is_waiting = false
    wait_timer = 0.0
    
    investigating_sound = true
    sound_investigation_time = 0.0
    
    # Try to navigate using waypoints first
    if _navigate_to_position_with_waypoints(position):
        var dist = npc_base.global_position.distance_to(position)
        _update_state_label("INVESTIGATING SOUND [" + str(snappedf(dist, 0.1)) + "m]")
        print("SaboteurOverride: Moving to investigate sound at ", position)
        print("  Current position: ", npc_base.global_position)
        print("  Distance to sound: ", dist)
        print("  Is moving: ", npc_base.is_moving)
        print("  Waypoint path size: ", npc_base.waypoint_path.size())
    else:
        # Fallback to direct movement if no waypoint path found
        print("SaboteurOverride: WARNING - No waypoint path to sound, using direct movement")
        npc_base.move_to_position(position)
        var dist = npc_base.global_position.distance_to(position)
        _update_state_label("INVESTIGATING SOUND [" + str(snappedf(dist, 0.1)) + "m]")

func _navigate_to_position_with_waypoints(target_pos: Vector3) -> bool:
    """Navigate to a position using the waypoint system to avoid walls"""
    
    # Get waypoint network manager
    var waypoint_manager = get_tree().get_first_node_in_group("waypoint_network_manager")
    if not waypoint_manager:
        print("SaboteurOverride: No waypoint manager found")
        return false
    
    # Find nearest waypoint to target position
    var nearest_waypoint = _find_nearest_waypoint(target_pos)
    if nearest_waypoint.is_empty():
        return false
    
    print("SaboteurOverride: Using waypoint ", nearest_waypoint, " to reach sound at ", target_pos)
    
    # Get path to nearest waypoint
    var path = waypoint_manager.get_path_to_room(npc_base.global_position, nearest_waypoint)
    if path.is_empty():
        print("SaboteurOverride: No path found to nearest waypoint ", nearest_waypoint)
        return false
    
    # Add the final target position to the path
    path.append(target_pos)
    
    # Set up waypoint path
    npc_base.waypoint_path = path
    npc_base.waypoint_path_index = 0
    npc_base.is_moving = true
    
    # Update path visualization
    if npc_base.show_waypoint_path:
        npc_base._visualize_waypoint_path()
    
    return true

func _find_nearest_waypoint(position: Vector3) -> String:
    """Find the nearest waypoint to a given position"""
    var waypoint_manager = get_tree().get_first_node_in_group("waypoint_network_manager")
    if not waypoint_manager or not waypoint_manager.has_method("get_all_waypoint_positions"):
        # Fallback: find waypoint based on room
        var room = _get_room_at_position(position)
        if room != "":
            return room + "_Center"
        return ""
    
    # If we have access to all waypoints, find the nearest
    var min_distance = INF
    var nearest = ""
    
    # Check room center waypoints
    for room_name in room_waypoints:
        var waypoint = get_tree().get_first_node_in_group("waypoint_" + room_name)
        if waypoint:
            var dist = waypoint.global_position.distance_to(position)
            if dist < min_distance:
                min_distance = dist
                nearest = room_name
    
    return nearest

func _get_room_at_position(position: Vector3) -> String:
    """Determine which room a position is in based on coordinates"""
    # Simple room detection based on position
    # These are approximate room boundaries
    if position.x < -30:
        return "Engineering"
    elif position.x < -10:
        return "Security"
    elif position.x > 20:
        return "MedicalBay"
    elif position.z < -10:
        return "CrewQuarters"
    elif position.z > 5:
        return "Laboratory"
    else:
        return "Cafeteria"

func set_debug_visualization(show_sound: bool):
    """Called from debug UI to toggle visualizations"""
    show_sound_detection = show_sound
    if sound_sphere_mesh:
        sound_sphere_mesh.visible = show_sound_detection
    # Hide marker if debug is off and not investigating
    if sound_marker and not show_sound:
        sound_marker.visible = false

func _exit_tree():
    # Clean up label
    if state_label:
        state_label.queue_free()
    
    # Clean up vision cone
    if vision_cone_container:
        vision_cone_container.queue_free()
    
    # Clean up sound marker
    if sound_marker:
        sound_marker.queue_free()
    
    if not npc_base:
        return
    
    # Re-enable all disabled features
    if "use_schedule" in npc_base:
        npc_base.use_schedule = true
    
    if "react_to_player_proximity" in npc_base:
        npc_base.react_to_player_proximity = true
    
    # Re-enable interaction
    npc_base.set_collision_layer_value(2, true)
    
    # Reset trigger distances to defaults
    if "idle_trigger_distance" in npc_base:
        npc_base.idle_trigger_distance = 3.0
    if "talk_trigger_distance" in npc_base:
        npc_base.talk_trigger_distance = 2.0
    
    # Re-enable dialogue
    var dialogue = npc_base.get_node_or_null("DialogueSystem")
    if dialogue:
        dialogue.set_process(true)
        dialogue.set_physics_process(true)
        if dialogue.has_method("set_enabled"):
            dialogue.set_enabled(true)
