extends Node
class_name SaboteurOverride

# This script uses the NPC's navigation but controls when to move

@export_group("Vision Settings")
@export var vision_distance: float = 15.0  # How far the saboteur can see
@export var vision_angle: float = 70.0  # FOV in degrees (human is ~70-90)
@export var vision_height: float = 1.6  # Eye height
@export var show_vision_cone: bool = true  # Debug visualization

@export_group("Sound Settings")
@export var hearing_range: float = 25.0  # Should be larger than vision!
@export var running_noise_multiplier: float = 1.5  # Running is louder
@export var walking_noise_base: float = 15.0  # Base walking detection range
@export var crouching_noise_multiplier: float = 0.3  # Crouching is quieter
@export var show_sound_detection: bool = false  # Debug visualization

@export_group("Chase Settings")
@export var chase_speed_multiplier: float = 1.3  # Speed boost when chasing
@export var lose_sight_time: float = 3.0  # Time before giving up chase after losing sight
@export var close_detection_range: float = 3.0  # Range where hiding doesn't work
@export var memory_duration: float = 5.0  # How long to remember last seen position

@export_group("Debug Settings")
@export var show_debug_overlay: bool = true  # Show debug info on player screen
@export var debug_sound_detection: bool = false  # Print detailed sound detection info
@export var debug_state_changes: bool = false  # Print state change info

var npc_base: NPCBase
var wait_time: float = 5.0
var wait_timer: float = 0.0
var debug_sound_timer: float = 0.0  # Timer for periodic debug prints
var debug_vision_timer: float = 0.0  # Timer for vision debug prints
var last_vision_blocked_by: String = ""  # Track what last blocked vision
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
var debug_overlay: Label  # Screen overlay for debugging
var player_seen_marker: MeshInstance3D  # Marker for where player was seen
var path_debug_line: MeshInstance3D  # Line showing path to target

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

# Chase state
var is_chasing: bool = false
var time_since_lost_sight: float = 0.0
var last_known_position: Vector3 = Vector3.ZERO
var search_time: float = 0.0
var max_search_time: float = 8.0  # Time to search area before giving up
var original_speed: float = 0.0
var has_warned_too_close: bool = false  # Prevent spam
var pursuing_sound_lead: bool = false  # Prevent search interruption when pursuing sound

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
    
    # Create debug overlay
    _create_debug_overlay()
    
    # Create debug markers for position tracking
    _create_debug_markers()
    
    # Create vision cone visualization - ENABLED BY DEFAULT
    show_vision_cone = true
    _create_vision_cone()
    
    # Create sound detection visualization - ENABLED BY DEFAULT  
    show_sound_detection = true
    _create_sound_detection()
    
    # Find player
    player = get_tree().get_first_node_in_group("player")
    
    # Store original speed
    if "movement_speed" in npc_base:
        original_speed = npc_base.movement_speed
    else:
        original_speed = 3.0
    
    # Wait a moment before starting
    await get_tree().create_timer(1.0).timeout
    
    # Start patrolling
    _pick_new_target()
    
    print("SaboteurOverride: Taking control of ", npc_base.name)
    print("SaboteurOverride: Vision cone enabled: ", show_vision_cone)
    print("SaboteurOverride: Sound detection enabled: ", show_sound_detection)

func _process(delta):
    if not npc_base:
        return
    
    # Check for player detection
    _check_player_detection()
    
    # Handle chase state
    if is_chasing:
        _handle_chase_state(delta)
        # Only check for sound during search phase when we've lost the player
        if search_time > 0:
            _check_sound_detection()
    elif not investigating_sound or (investigating_sound and npc_base.is_moving):
        # Only check for new sounds if not already investigating at a location
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
        if is_chasing:
            _update_state_label("PURSUING SOUND [" + str(snappedf(dist, 0.1)) + "m]")
        else:
            _update_state_label("INVESTIGATING SOUND [" + str(snappedf(dist, 0.1)) + "m]")
    
    # Check if NPC has finished moving
    if not npc_base.is_moving and not is_waiting:
        # Reached destination
        if investigating_sound:
            if is_chasing:
                # Reached sound during chase - continue searching
                print("SaboteurOverride: Reached sound location during chase, continuing search...")
                search_time = 0.1  # Start search timer
                investigating_sound = false  # Done investigating this sound
                pursuing_sound_lead = false  # Reset sound pursuit flag
                _update_state_label("SEARCHING AREA")
            else:
                print("SaboteurOverride: Reached sound location, investigating...")
                is_waiting = true
                wait_timer = 0.0
                _update_state_label("SEARCHING AT SOUND")
        elif not is_chasing:
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
    
    # Check if stuck (not moving for too long when should be)
    if not is_waiting and not npc_base.is_moving and not is_chasing:
        wait_timer += delta
        if wait_timer > 2.0:
            print("SaboteurOverride: Appears to be stuck, picking new target")
            is_waiting = false
            wait_timer = 0.0
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
    
    # ALWAYS use waypoint navigation for patrol to avoid walls
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

func _create_debug_overlay():
    """Create a debug overlay on the player's screen"""
    if not show_debug_overlay:
        return
    
    # Find the player's UI layer
    var ui_layer = get_tree().get_first_node_in_group("player_ui_layer")
    if not ui_layer:
        # Try alternative path
        var player = get_tree().get_first_node_in_group("player")
        if player:
            ui_layer = player.get_node_or_null("UILayer")
    
    if not ui_layer:
        print("SaboteurOverride: Could not find UI layer for debug overlay")
        return
    
    # Create debug label
    debug_overlay = Label.new()
    debug_overlay.name = "SaboteurDebugOverlay"
    debug_overlay.text = "SABOTEUR: Initializing..."
    
    # Style the overlay
    debug_overlay.add_theme_font_size_override("font_size", 20)
    debug_overlay.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
    debug_overlay.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
    debug_overlay.add_theme_constant_override("shadow_offset_x", 2)
    debug_overlay.add_theme_constant_override("shadow_offset_y", 2)
    debug_overlay.add_theme_constant_override("outline_size", 2)
    
    # Position in top-right corner
    debug_overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    debug_overlay.position = Vector2(-400, 10)
    
    ui_layer.add_child(debug_overlay)
    print("SaboteurOverride: Debug overlay created")

func _update_debug_overlay(text: String):
    """Update the debug overlay with current state"""
    if not debug_overlay:
        return
    
    var display_text = "SABOTEUR: " + text
    
    # Add additional info
    if player and npc_base:
        var distance = npc_base.global_position.distance_to(player.global_position)
        display_text += "\nDistance: " + str(snappedf(distance, 0.1)) + "m"
        
        # Show hearing status
        if not player_detected and not is_chasing:
            display_text += "\nHearing: "
            if distance <= hearing_range:
                display_text += "In range (" + str(hearing_range) + "m)"
            else:
                display_text += "Too far"
    
    if is_chasing:
        display_text += "\nChase Mode: ACTIVE"
        if player_detected:
            display_text += " [VISUAL CONTACT]"
        elif search_time > 0:
            display_text += " [SEARCHING: " + str(snappedf(max_search_time - search_time, 0.1)) + "s]"
    
    if investigating_sound:
        display_text += "\nSound Detected!"
    
    # Add no sound reason if available
    if debug_overlay.has_meta("no_sound_reason"):
        display_text += "\nNo sound: " + debug_overlay.get_meta("no_sound_reason")
    
    debug_overlay.text = display_text
    
    # Update color based on state
    if player_detected:
        debug_overlay.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
    elif is_chasing:
        debug_overlay.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Orange
    elif investigating_sound:
        debug_overlay.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
    else:
        debug_overlay.add_theme_color_override("font_color", Color(0.5, 1, 0.5))  # Green

func _update_state_label(text: String):
    if state_label:
        state_label.text = "SABOTEUR - " + text
        if is_chasing:
            state_label.modulate = Color(1, 0, 0)  # Pure red when chasing
            if player_detected:
                state_label.text += " [EYES ON TARGET!]"
        elif player_detected:
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
    
    # Update debug overlay
    _update_debug_overlay(text)

func _check_for_doors():
    # Check for doors in multiple directions
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 1.0
    
    # Check in movement direction and forward
    var directions = []
    
    # Add velocity direction if moving significantly
    if npc_base.velocity.length() > 0.5:  # Only check if actually moving
        directions.append(npc_base.velocity.normalized())
    
    # Always check forward
    directions.append(-npc_base.global_transform.basis.z)
    
    # Store already checked doors to avoid spam
    var checked_doors = []
    
    for direction in directions:
        # Only check close distances for doors
        for distance in [1.5, 2.0]:
            var to = from + direction * distance
            
            var query = PhysicsRayQueryParameters3D.create(from, to)
            query.collision_mask = 3  # Check both environment (1) and interactable (2) layers
            query.exclude = [npc_base]
            
            var result = space_state.intersect_ray(query)
            if result:
                # Check if it's a door
                if result.collider is SlidingDoor:
                    var door = result.collider as SlidingDoor
                    
                    # Skip if already checked this frame
                    if door in checked_doors:
                        continue
                    checked_doors.append(door)
                    
                    # Only trigger closed doors that aren't already moving
                    if not door.is_open and not door.is_moving:
                        # Check if we're actually approaching the door (not moving away)
                        var to_door = (door.global_position - npc_base.global_position).normalized()
                        var movement_dir = npc_base.velocity.normalized() if npc_base.velocity.length() > 0.1 else -npc_base.global_transform.basis.z
                        
                        # Only open if we're moving towards it
                        if to_door.dot(movement_dir) > 0.5:
                            print("SaboteurOverride: Triggering door - ", door.door_name)
                            # For automatic doors, trigger the detection instead of interact
                            if door.is_powered:
                                # Add ourselves to the detection area manually
                                door._on_body_entered(npc_base)
                            else:
                                # Manual door, use interact
                                door.interact()
                            return  # Only open one door per frame

func _create_vision_cone():
    # Always create the cone, just control visibility
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
    
    # Set initial visibility
    vision_cone_container.visible = show_vision_cone

func _create_debug_markers():
    """Create debug markers for player position tracking"""
    # Create player seen marker (red sphere)
    player_seen_marker = MeshInstance3D.new()
    player_seen_marker.name = "PlayerSeenMarker"
    var seen_sphere = SphereMesh.new()
    seen_sphere.radius = 0.3
    seen_sphere.height = 0.6
    player_seen_marker.mesh = seen_sphere
    
    var seen_mat = StandardMaterial3D.new()
    seen_mat.albedo_color = Color(1, 0, 0, 0.8)  # Red
    seen_mat.emission_enabled = true
    seen_mat.emission = Color(1, 0, 0)
    seen_mat.emission_energy = 2.0
    seen_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    seen_mat.no_depth_test = true
    player_seen_marker.material_override = seen_mat
    
    get_tree().current_scene.add_child(player_seen_marker)
    player_seen_marker.visible = false
    
    # Create path debug line
    path_debug_line = MeshInstance3D.new()
    path_debug_line.name = "PathDebugLine"
    var line_mesh = ImmediateMesh.new()
    path_debug_line.mesh = line_mesh
    
    var line_mat = StandardMaterial3D.new()
    line_mat.albedo_color = Color(0, 1, 1, 1)  # Cyan
    line_mat.emission_enabled = true
    line_mat.emission = Color(0, 1, 1)
    line_mat.emission_energy = 3.0
    line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    line_mat.vertex_color_use_as_albedo = true
    line_mat.no_depth_test = true
    path_debug_line.material_override = line_mat
    
    get_tree().current_scene.add_child(path_debug_line)
    path_debug_line.visible = false

func _update_player_seen_marker(position: Vector3):
    """Update the marker showing where player was last seen"""
    if player_seen_marker:
        player_seen_marker.global_position = position + Vector3.UP * 0.5
        player_seen_marker.visible = true

func _update_path_debug_line(target_position: Vector3):
    """Update the line showing path from saboteur to target"""
    if not path_debug_line:
        return
    
    var line_mesh = path_debug_line.mesh as ImmediateMesh
    line_mesh.clear_surfaces()
    line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    
    var from = npc_base.global_position + Vector3.UP * 1.0
    var to = target_position + Vector3.UP * 1.0
    
    # Draw main line
    line_mesh.surface_set_color(Color(0, 1, 1, 1))  # Cyan
    line_mesh.surface_add_vertex(from)
    line_mesh.surface_add_vertex(to)
    
    # Draw arrow at target
    var direction = (to - from).normalized()
    var arrow_size = 0.5
    var side = direction.cross(Vector3.UP).normalized() * arrow_size
    var back = -direction * arrow_size
    
    # Arrow lines
    line_mesh.surface_set_color(Color(1, 1, 0, 1))  # Yellow arrow
    line_mesh.surface_add_vertex(to)
    line_mesh.surface_add_vertex(to + back + side)
    line_mesh.surface_add_vertex(to)
    line_mesh.surface_add_vertex(to + back - side)
    
    line_mesh.surface_end()
    path_debug_line.visible = true

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
    # Use all collision layers to ensure we catch CSG geometry and walls
    query.collision_mask = 0b11111111111111111111111111111111  # Check all 32 layers
    query.exclude = [npc_base]
    query.collide_with_areas = true
    query.collide_with_bodies = true
    
    var result = space_state.intersect_ray(query)
    if not result.is_empty():
        var collider = result.collider
        
        # Check if it's the player - if so, vision is clear
        if collider == player:
            player_detected = true
            last_seen_position = player_pos
            _update_player_seen_marker(player_pos)
            if not is_chasing:
                print("SaboteurOverride: PLAYER DETECTED at distance ", distance, "m at ", player_pos)
                _start_chase()
            else:
                last_known_position = player_pos
                time_since_lost_sight = 0.0
            return
        
        # Check if it's a door - vision can go through doors
        if collider.has_method("interact") and collider.get_class() == "CharacterBody3D":
            # Door doesn't block vision completely
            pass
        else:
            # Something blocking the view (wall, CSG, etc)
            if debug_state_changes:
                var node = collider
                var is_csg = false
                while node != null:
                    if node.get_class().begins_with("CSG") or "CSG" in node.name:
                        is_csg = true
                        break
                    node = node.get_parent()
                var obstacle_type = "CSG" if is_csg else collider.get_class()
                var obstacle_name = obstacle_type + " (" + collider.name + ")"
                
                # Only print if it's a different obstacle or enough time has passed
                debug_vision_timer += get_process_delta_time()
                if last_vision_blocked_by != obstacle_name or debug_vision_timer > 2.0:
                    print("SaboteurOverride: Vision blocked by ", obstacle_name)
                    last_vision_blocked_by = obstacle_name
                    debug_vision_timer = 0.0
            
            player_detected = false
            return
    
    # No obstacles in the way - player should be detected
    player_detected = true
    last_seen_position = player_pos
    _update_player_seen_marker(player_pos)
    
    if not is_chasing:
        print("SaboteurOverride: PLAYER DETECTED at distance ", distance, "m at ", player_pos)
        _start_chase()
    else:
        # Update last seen position
        last_known_position = player_pos
        time_since_lost_sight = 0.0

func _create_sound_detection():
    # Create main hearing range sphere
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
    
    # Create walking range sphere
    walking_range_mesh = MeshInstance3D.new()
    walking_range_mesh.name = "WalkingRangeSphere"
    
    var walk_sphere = SphereMesh.new()
    walk_sphere.radius = walking_noise_base
    walk_sphere.height = walking_noise_base * 2
    walk_sphere.radial_segments = 24
    walk_sphere.rings = 12
    walking_range_mesh.mesh = walk_sphere
    
    var walk_mat = StandardMaterial3D.new()
    walk_mat.albedo_color = Color(0, 1, 0, 0.1)  # Green
    walk_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    walk_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    walk_mat.no_depth_test = true
    walk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    walking_range_mesh.material_override = walk_mat
    
    npc_base.add_child(walking_range_mesh)
    walking_range_mesh.visible = show_sound_detection
    
    # Create running range sphere
    running_range_mesh = MeshInstance3D.new()
    running_range_mesh.name = "RunningRangeSphere"
    
    var run_sphere = SphereMesh.new()
    run_sphere.radius = walking_noise_base * running_noise_multiplier
    run_sphere.height = walking_noise_base * running_noise_multiplier * 2
    run_sphere.radial_segments = 24
    run_sphere.rings = 12
    running_range_mesh.mesh = run_sphere
    
    var run_mat = StandardMaterial3D.new()
    run_mat.albedo_color = Color(1, 0, 0, 0.1)  # Red
    run_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    run_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    run_mat.no_depth_test = true
    run_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    running_range_mesh.material_override = run_mat
    
    npc_base.add_child(running_range_mesh)
    running_range_mesh.visible = show_sound_detection
    
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
    if not player:
        return
    
    # Don't check sound if already seeing player (except during search phase)
    if player_detected and not (is_chasing and search_time > 0):
        return
    
    var player_controller = player
    if not player_controller:
        return
    
    # Debug: Verify player object
    if debug_sound_detection and debug_sound_timer > 2.0:
        print("SaboteurOverride: Player object: ", player.name, " at ", player.global_position)
    
    # Calculate distance
    var distance = npc_base.global_position.distance_to(player.global_position)
    
    # Debug: Track player position for sound detection
    var current_player_pos = player.global_position
    var saboteur_pos = npc_base.global_position
    
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
    
    # Only consider horizontal movement for sound
    var horizontal_velocity = Vector3(player_velocity.x, 0, player_velocity.z)
    var is_moving = horizontal_velocity.length() > 0.1
    
    if not is_moving:
        return  # No sound if not moving
    
    # Calculate noise range based on movement type
    if is_crouching:
        noise_range = walking_noise_base * crouching_noise_multiplier
    elif is_sprinting:
        noise_range = walking_noise_base * running_noise_multiplier
    else:
        noise_range = walking_noise_base
    
    # Debug print periodically
    if debug_sound_detection:
        debug_sound_timer += get_process_delta_time()
        if debug_sound_timer > 1.0:
            debug_sound_timer = 0.0
            var debug_chance = 0.0
            if distance <= noise_range:
                var range_percent = distance / noise_range
                if range_percent <= 0.5:
                    debug_chance = 1.0
                elif range_percent <= 0.75:
                    debug_chance = 1.0 - (range_percent - 0.5) * 1.0
                else:
                    debug_chance = 0.75 - (range_percent - 0.75) * 2.0
                if is_crouching:
                    debug_chance *= 0.5
                elif is_sprinting:
                    debug_chance = min(debug_chance * 1.5, 1.0)
            
            print("SaboteurOverride: Sound Debug - Distance: ", snappedf(distance, 0.1), 
                  "m, Moving: ", is_moving, ", Velocity: ", horizontal_velocity.length(),
                  ", Noise Range: ", noise_range, "m, Detection Chance: ", snappedf(debug_chance * 100, 0.1), "%,",
                  " Mode: ", "crouching" if is_crouching else ("running" if is_sprinting else "walking"))
    
    # Calculate detection chance with falloff
    var detection_chance = 0.0
    
    if distance <= hearing_range:
        # Calculate base detection chance based on movement type
        var effective_range = noise_range
        
        if distance <= effective_range:
            # Within effective range - use falloff curve
            # Close range (0-50% of range): 100% detection
            # Mid range (50-75% of range): 75-100% detection  
            # Far range (75-100% of range): 25-75% detection
            var range_percent = distance / effective_range
            
            if range_percent <= 0.5:
                detection_chance = 1.0  # 100% at close range
            elif range_percent <= 0.75:
                detection_chance = 1.0 - (range_percent - 0.5) * 1.0  # 100% to 75%
            else:
                detection_chance = 0.75 - (range_percent - 0.75) * 2.0  # 75% to 25%
            
            # Apply movement modifiers
            if is_crouching:
                detection_chance *= 0.5  # Harder to detect when crouching
            elif is_sprinting:
                detection_chance *= 1.5  # Easier to detect when running
                detection_chance = min(detection_chance, 1.0)  # Cap at 100%
        
        # Roll for detection
        if detection_chance > 0 and randf() < detection_chance:
            # Sound detected!
            var new_sound_pos = current_player_pos  # Use the position from the beginning of the function
            
            # Debug: Check if there's a discrepancy
            var actual_distance = npc_base.global_position.distance_to(new_sound_pos)
            if abs(actual_distance - distance) > 1.0:
                print("SaboteurOverride: WARNING - Distance mismatch! Calculated: ", distance, "m, Actual: ", actual_distance, "m")
                print("  Saboteur at: ", npc_base.global_position)
                print("  Player at: ", new_sound_pos)
            
            # Only trigger new investigation if position changed significantly or it's a new sound
            var should_investigate = false
            
            if not sound_detected:
                # First time hearing sound
                should_investigate = true
            elif new_sound_pos.distance_to(sound_position) > 3.0:
                # Player moved significantly
                should_investigate = true
            elif not investigating_sound and not is_chasing:
                # Not currently doing anything, investigate
                should_investigate = true
            
            if should_investigate:
                sound_detected = true
                sound_position = new_sound_pos
                
                print("SaboteurOverride: SOUND at ", sound_position, " (", 
                      "crouching" if is_crouching else ("running" if is_sprinting else "walking"), 
                      ", ", snappedf(distance, 0.1), "m)")
                print("  Saboteur: ", saboteur_pos, " | Player: ", current_player_pos)
                
                # Show where sound was detected (using sound marker with different color)
                if sound_marker:
                    sound_marker.global_position = sound_position + Vector3.UP * 0.5
                    sound_marker.visible = true
                
                # Navigate to new sound position
                _investigate_sound(sound_position)
                
                # Update marker
                if sound_marker:
                    sound_marker.global_position = sound_position + Vector3.UP * 0.5
                    sound_marker.visible = show_sound_detection  # Only show if debug is on
            else:
                # Just update the position for tracking
                sound_position = new_sound_pos
                if sound_marker:
                    sound_marker.global_position = sound_position + Vector3.UP * 0.5
    else:
        # No sound detected - useful for debugging
        if is_moving and show_sound_detection:
            # Show why sound wasn't detected in debug
            var reason = ""
            if distance > hearing_range:
                reason = "too far (" + str(snappedf(distance, 0.1)) + "m > " + str(hearing_range) + "m)"
            elif distance > noise_range:
                reason = "outside noise range (" + str(snappedf(distance, 0.1)) + "m > " + str(snappedf(noise_range, 0.1)) + "m)"
            else:
                reason = "not moving"
            
            # Update debug overlay with this info
            if debug_overlay:
                debug_overlay.set_meta("no_sound_reason", reason)

var rotation_tween: Tween = null  # Track rotation tween

func _investigate_sound(position: Vector3):
    # If already investigating a sound nearby, just update the position
    if investigating_sound and sound_position.distance_to(position) < 5.0:
        sound_position = position  # Update target without interrupting
        return
    
    # If we're searching (lost player during chase), this is a new lead!
    if is_chasing and search_time > 0:
        print("SaboteurOverride: NEW SOUND LEAD at ", position)
        search_time = 0.0  # Reset search timer
        pursuing_sound_lead = true  # Mark as pursuing sound
        last_seen_position = position  # Update last known position
        last_known_position = position  # Update last known for chase
        time_since_lost_sight = 0.0  # Reset lost sight timer
        
        # Immediately pursue the sound
        _chase_to_position(position)
        _update_state_label("PURSUING NEW SOUND!")
        return  # Don't do normal investigation, stay in chase mode
    
    investigating_sound = true
    sound_investigation_time = 0.0
    is_waiting = false
    wait_timer = 0.0
    
    # Cancel any existing rotation tween
    if rotation_tween and rotation_tween.is_valid():
        rotation_tween.kill()
    
    # First, turn to look at the sound
    var direction_to_sound = (position - npc_base.global_position).normalized()
    var target_rotation = atan2(direction_to_sound.x, direction_to_sound.z)
    
    # Only rotate and react if we're not already moving
    if not npc_base.is_moving or npc_base.waypoint_path.is_empty():
        # Smoothly rotate towards the sound over 0.5 seconds
        rotation_tween = get_tree().create_tween()
        rotation_tween.tween_property(npc_base, "rotation:y", target_rotation, 0.5)
        rotation_tween.tween_callback(_start_moving_to_sound.bind(position))
        
        # Show immediate reaction
        _update_state_label("HEARD SOMETHING!")
    else:
        # Already moving, just update destination
        _start_moving_to_sound(position)

func _start_moving_to_sound(position: Vector3):
    """Start moving to the sound position after turning"""
    # Make sure we're not waiting
    is_waiting = false
    wait_timer = 0.0
    
    # Always use waypoints for sound investigation
    if _navigate_to_position_with_waypoints(position):
        var dist = npc_base.global_position.distance_to(position)
        _update_path_debug_line(position)
        if is_chasing:
            _update_state_label("PURSUING SOUND [" + str(snappedf(dist, 0.1)) + "m]")
        else:
            _update_state_label("INVESTIGATING SOUND [" + str(snappedf(dist, 0.1)) + "m]")
    else:
        # Fallback to direct movement if no waypoint path found
        print("SaboteurOverride: WARNING - No waypoint path to sound, using direct movement")
        npc_base.move_to_position(position)
        var dist = npc_base.global_position.distance_to(position)
        _update_path_debug_line(position)
        if is_chasing:
            _update_state_label("PURSUING SOUND [" + str(snappedf(dist, 0.1)) + "m]")
        else:
            _update_state_label("INVESTIGATING SOUND [" + str(snappedf(dist, 0.1)) + "m]")

func _navigate_to_position_with_waypoints(target_pos: Vector3) -> bool:
    """Navigate to a position using the waypoint system to avoid walls"""
    
    # Check if we're already navigating to a similar position
    if npc_base.is_moving and npc_base.waypoint_path.size() > 0:
        var current_target = npc_base.waypoint_path[-1]
        if current_target.distance_to(target_pos) < 2.0:
            # Already navigating to a nearby position, don't interrupt
            return true
    
    # Get waypoint network manager
    var waypoint_manager = get_tree().get_first_node_in_group("waypoint_network_manager")
    if not waypoint_manager:
        print("SaboteurOverride: No waypoint manager found")
        return false
    
    # Find nearest waypoint to target position
    var nearest_waypoint = _find_nearest_waypoint(target_pos)
    if nearest_waypoint.is_empty():
        return false
    
    # Get path to nearest waypoint
    var path = waypoint_manager.get_path_to_room(npc_base.global_position, nearest_waypoint)
    if path.is_empty():
        print("SaboteurOverride: No path found to nearest waypoint ", nearest_waypoint)
        return false
    
    # Add the target position to the path
    path.append(target_pos)
    
    # Only update if the path is significantly different
    if npc_base.waypoint_path.size() == 0 or path.size() != npc_base.waypoint_path.size():
        # Stop current movement before setting new path
        npc_base.stop_movement()
        
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

func _is_position_outside_station(position: Vector3) -> bool:
    """Check if a position is outside the station boundaries"""
    # More generous station boundaries
    var min_bounds = Vector3(-20, -5, -15)  # Minimum x, y, z
    var max_bounds = Vector3(20, 10, 15)    # Maximum x, y, z
    
    # Check if position is outside bounds
    if position.x < min_bounds.x or position.x > max_bounds.x:
        return true
    if position.y < min_bounds.y or position.y > max_bounds.y:
        return true
    if position.z < min_bounds.z or position.z > max_bounds.z:
        return true
    
    return false

func _has_clear_path_to(target_pos: Vector3) -> bool:
    """Check if there's a clear path to the target position"""
    var space_state = npc_base.get_world_3d().direct_space_state
    var from = npc_base.global_position + Vector3.UP * 1.0  # NPC position at chest height
    var to = target_pos + Vector3.UP * 0.5  # Target at waist height (account for crouching)
    
    # Cast multiple rays to check for obstacles (center and sides)
    var offsets = [Vector3.ZERO, Vector3.LEFT * 0.3, Vector3.RIGHT * 0.3]
    
    for offset in offsets:
        var query = PhysicsRayQueryParameters3D.create(from + offset, to + offset)
        # Use all collision layers to ensure we catch CSG geometry
        query.collision_mask = 0b11111111111111111111111111111111  # Check all 32 layers
        query.exclude = [npc_base]
        query.collide_with_areas = true
        query.collide_with_bodies = true
        
        var result = space_state.intersect_ray(query)
        if not result.is_empty():
            var collider = result.collider
            
            # Check if it's a door - if so, it's OK
            if collider.has_method("interact") and collider.get_class() == "CharacterBody3D":
                continue
            
            # Check specifically for CSG shapes which might not be on expected layers
            var node = collider
            var is_csg = false
            
            # Walk up the scene tree to check for CSG nodes
            while node != null:
                if node.get_class().begins_with("CSG") or "CSG" in node.name:
                    is_csg = true
                    break
                node = node.get_parent()
            
            # Found an obstacle
            if debug_state_changes:
                var obstacle_type = "CSG" if is_csg else collider.get_class()
                print("SaboteurOverride: Path blocked by ", obstacle_type, " (", collider.name, ") at ", result.position)
            
            return false
    
    # All rays are clear
    return true

func set_debug_visualization(show_sound: bool):
    """Called from debug UI to toggle visualizations"""
    show_sound_detection = show_sound
    
    # Update all sound detection visualizations
    if sound_sphere_mesh:
        sound_sphere_mesh.visible = show_sound_detection
    if walking_range_mesh:
        walking_range_mesh.visible = show_sound_detection
    if running_range_mesh:
        running_range_mesh.visible = show_sound_detection
    
    # Hide marker if debug is off and not investigating
    if sound_marker and not show_sound:
        sound_marker.visible = false

func set_vision_cone_visibility(show: bool):
    """Toggle vision cone visibility from debug UI"""
    show_vision_cone = show
    if vision_cone_container:
        vision_cone_container.visible = show
    print("SaboteurOverride: Vision cone visibility set to ", show)

func _start_chase():
    """Start chasing the player"""
    if is_chasing:
        return
    
    is_chasing = true
    time_since_lost_sight = 0.0
    search_time = 0.0
    last_known_position = last_seen_position
    
    # Cancel any sound investigation
    investigating_sound = false
    sound_detected = false
    sound_position = Vector3.ZERO
    sound_investigation_time = 0.0
    
    # Hide sound marker
    if sound_marker:
        sound_marker.visible = false
    
    # Stop any current movement from sound investigation
    npc_base.stop_movement()
    is_waiting = false
    wait_timer = 0.0
    
    # Increase movement speed
    if npc_base:
        npc_base.movement_speed = original_speed * chase_speed_multiplier
        npc_base.walk_speed = original_speed * chase_speed_multiplier
    
    print("SaboteurOverride: CHASE STARTED!")
    _update_state_label("CHASING")

func _handle_chase_state(delta):
    """Handle the chase behavior"""
    if not player:
        return
    
    # If we can see the player, chase them
    if player_detected:
        # Always update last seen position when we have visual
        last_seen_position = player.global_position
        time_since_lost_sight = 0.0
        search_time = 0.0
        
        # Only update navigation if player moved significantly or NPC is stuck
        var player_moved = last_known_position.distance_to(player.global_position) > 3.0
        var stuck = not npc_base.is_moving
        
        if player_moved or stuck:
            _chase_to_position(player.global_position)
            last_known_position = player.global_position
    else:
        # Lost sight of player
        time_since_lost_sight += delta
        
        # Check if player is hiding too close
        var distance = npc_base.global_position.distance_to(player.global_position)
        if distance <= close_detection_range:
            # Check line of sight even at close range
            var space_state = npc_base.get_world_3d().direct_space_state
            var eye_pos = npc_base.global_position + Vector3.UP * vision_height
            var player_pos = player.global_position + Vector3.UP * 0.9
            
            var query = PhysicsRayQueryParameters3D.create(eye_pos, player_pos)
            query.collision_mask = 0b11111111111111111111111111111111  # Check all collision layers
            query.exclude = [npc_base]
            query.collide_with_areas = true
            query.collide_with_bodies = true
            
            var result = space_state.intersect_ray(query)
            if result.is_empty() or result.collider == player:  # Clear line of sight or hit player directly
                # Player is too close to hide effectively
                if not has_warned_too_close:
                    print("SaboteurOverride: Player too close to hide! (", distance, "m)")
                    has_warned_too_close = true
                
                # Always update detection and positions when too close
                player_detected = true
                last_seen_position = player.global_position
                last_known_position = player.global_position
                return
        else:
            # Player is far enough away, reset the warning flag
            has_warned_too_close = false
        
        # If recently lost sight, go to last known position
        if time_since_lost_sight < lose_sight_time:
            if pursuing_sound_lead:
                _update_state_label("PURSUING NEW SOUND!")
            else:
                _update_state_label("PURSUING [Lost sight: " + str(snappedf(time_since_lost_sight, 0.1)) + "s]")
            
            if not npc_base.is_moving and search_time == 0.0 and not pursuing_sound_lead:
                # Reached last known position, start searching
                search_time = 0.1
                _update_state_label("SEARCHING AREA")
                print("SaboteurOverride: Searching last known position")
        else:
            # Search the area
            search_time += delta
            _update_state_label("SEARCHING [" + str(snappedf(max_search_time - search_time, 0.1)) + "s]")
            
            if search_time >= max_search_time:
                # Give up chase
                _end_chase()

func _chase_to_position(position: Vector3):
    """Navigate to a position while chasing"""
    var dist = npc_base.global_position.distance_to(position)
    
    # If we have clear line of sight and are close, use direct movement
    var has_clear_path = _has_clear_path_to(position)
    
    # Only print chase debug occasionally to avoid spam
    if debug_state_changes:
        print("SaboteurOverride: Chase Debug - Distance: ", dist, "m, Clear path: ", has_clear_path, ", Player detected: ", player_detected)
    
    if player_detected and has_clear_path and dist < 10.0:
        # Direct chase when we can see the player clearly AND no obstacles
        npc_base.stop_movement()  # Clear waypoint path
        npc_base.move_to_position(position)
        _update_path_debug_line(position)
        _update_state_label("CHASING [DIRECT] [" + str(snappedf(dist, 0.1)) + "m]")
        if debug_state_changes:
            print("SaboteurOverride: Using DIRECT chase - clear path")
    elif player_detected and has_clear_path and dist < 20.0:
        # Direct chase for medium distances if path is clear
        npc_base.stop_movement()  # Clear waypoint path
        npc_base.move_to_position(position)
        _update_path_debug_line(position)
        _update_state_label("CHASING [DIRECT] [" + str(snappedf(dist, 0.1)) + "m]")
        if debug_state_changes:
            print("SaboteurOverride: Using DIRECT chase - medium range, clear path")
    else:
        # Use waypoints when path is blocked or for longer distances
        if debug_state_changes:
            if has_clear_path:
                print("SaboteurOverride: Using WAYPOINT navigation - long distance")
            else:
                print("SaboteurOverride: Using WAYPOINT navigation - path blocked by obstacle")
        
        if _navigate_to_position_with_waypoints(position):
            _update_path_debug_line(position)
            _update_state_label("CHASING [WAYPOINT] [" + str(snappedf(dist, 0.1)) + "m]")
        else:
            # Only fallback to direct if we're very close and waypoints fail
            if dist < 5.0:
                if debug_state_changes:
                    print("SaboteurOverride: FALLBACK - Very close, using direct movement despite obstacles")
                npc_base.move_to_position(position)
                _update_path_debug_line(position)
                _update_state_label("CHASING [FALLBACK] [" + str(snappedf(dist, 0.1)) + "m]")
            else:
                print("SaboteurOverride: WARNING - No waypoint path found and target too far for direct fallback")
                # Try to get closer using the last known position
                var closer_position = npc_base.global_position + (position - npc_base.global_position).normalized() * 5.0
                npc_base.move_to_position(closer_position)
                _update_state_label("CHASING [APPROACH] [" + str(snappedf(dist, 0.1)) + "m]")

func _end_chase():
    """End the chase and return to patrol"""
    is_chasing = false
    player_detected = false
    time_since_lost_sight = 0.0
    search_time = 0.0
    pursuing_sound_lead = false  # Reset sound pursuit flag
    
    # Reset movement speed
    if npc_base:
        npc_base.movement_speed = original_speed
        npc_base.walk_speed = original_speed
    
    print("SaboteurOverride: Lost player, returning to patrol")
    _update_state_label("RESUMING PATROL")
    
    # Hide debug markers
    if player_seen_marker:
        player_seen_marker.visible = false
    if path_debug_line:
        path_debug_line.visible = false
    
    # Resume normal behavior
    is_waiting = true
    wait_timer = wait_time - 2.0  # Start patrolling sooner

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
    
    # Clean up debug overlay
    if debug_overlay:
        debug_overlay.queue_free()
    
    # Clean up debug markers
    if player_seen_marker:
        player_seen_marker.queue_free()
    if path_debug_line:
        path_debug_line.queue_free()
    
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
