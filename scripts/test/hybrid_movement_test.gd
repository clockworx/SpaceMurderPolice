extends Node3D

@export var test_waypoints: Array[Vector3] = [
    # Test various scenarios
    Vector3(0, 0, 0),       # Center
    Vector3(5, 0, 0),       # Simple straight line
    Vector3(5, 0, 5),       # Turn
    Vector3(-5, 0, 5),      # Long distance
    Vector3(-5, 0, -5),     # Another turn
    Vector3(0, 0, -8),      # Behind obstacle (should trigger switch)
    Vector3(8, 0, -8),      # Far corner
    Vector3(8, 0, 0),       # Side
    Vector3(0, 0, 0),       # Back to center
]

var hybrid_npc: NPCBase
var current_waypoint_index: int = 0
var waypoint_markers: Array[MeshInstance3D] = []
var auto_mode: bool = true
var performance_display: RichTextLabel

func _ready():
    # Find NPC
    hybrid_npc = get_node_or_null("../HybridTestNPC")
    
    if not hybrid_npc:
        push_error("Could not find HybridTestNPC!")
        return
    
    # Create waypoint markers
    _create_waypoint_markers()
    
    # Create performance display
    _create_performance_display()
    
    # Connect to movement signals
    if hybrid_npc.movement_system:
        hybrid_npc.movement_system.movement_completed.connect(_on_movement_completed)
        hybrid_npc.movement_system.movement_failed.connect(_on_movement_failed)
    
    print("Hybrid Movement Test Started")
    print("NPC uses: Hybrid movement system")
    print("\nAuto mode is ON - NPC will move continuously")
    print("Press A to toggle auto mode")
    print("Press N to move to next waypoint")
    print("Press R to reset position")
    print("Press S to show performance stats")
    print("Press F to force switch movement system")
    
    # Start auto movement after a short delay
    if auto_mode:
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.one_shot = true
        timer.timeout.connect(_start_auto_movement)
        add_child(timer)
        timer.start()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_A:
                auto_mode = !auto_mode
                print("Auto mode: ", "ON" if auto_mode else "OFF")
            KEY_N:
                _move_to_next_waypoint()
            KEY_R:
                _reset_position()
            KEY_S:
                _show_performance_stats()
            KEY_F:
                _force_switch_system()

func _move_to_next_waypoint():
    var target = test_waypoints[current_waypoint_index]
    print("\n=== Moving to waypoint ", current_waypoint_index, " at ", target, " ===")
    
    if hybrid_npc:
        print("NPC position: ", hybrid_npc.global_position)
        hybrid_npc.set_patrol_state()
        hybrid_npc.move_to_position(target)
        
        if hybrid_npc.movement_system and hybrid_npc.movement_system.has_method("get_current_system"):
            var system = hybrid_npc.movement_system.get_current_system()
            print("Using movement system: ", system)
    
    # Update waypoint index
    current_waypoint_index = (current_waypoint_index + 1) % test_waypoints.size()
    _update_marker_colors()

func _reset_position():
    print("\nResetting NPC position")
    
    if hybrid_npc:
        hybrid_npc.global_position = Vector3(0, 0.1, 0)
        hybrid_npc.stop_movement()
        hybrid_npc.set_idle_state()
    
    current_waypoint_index = 0
    _update_marker_colors()

func _show_performance_stats():
    if hybrid_npc and hybrid_npc.movement_system and hybrid_npc.movement_system.has_method("get_performance_stats"):
        var stats = hybrid_npc.movement_system.get_performance_stats()
        print("\n=== Performance Stats ===")
        print("Current system: ", stats.current_system)
        print("Last successful: ", stats.last_successful)
        print("Direct - Successes: ", stats.stats.direct.successes, ", Failures: ", stats.stats.direct.failures)
        print("NavMesh - Successes: ", stats.stats.navmesh.successes, ", Failures: ", stats.stats.navmesh.failures)

func _force_switch_system():
    if hybrid_npc and hybrid_npc.movement_system and hybrid_npc.movement_system.has_method("get_current_system"):
        var current = hybrid_npc.movement_system.get_current_system()
        var new_system = "direct" if current == "navmesh" else "navmesh"
        hybrid_npc.movement_system.force_switch_to(new_system)
        print("Forced switch to: ", new_system)

func _start_auto_movement():
    print("\nStarting automatic movement...")
    if hybrid_npc:
        hybrid_npc.use_waypoints = false
        hybrid_npc.wander_radius = 0.0
    
    _move_to_next_waypoint()

func _on_movement_completed():
    print("Movement completed successfully")
    _update_performance_display()
    
    if auto_mode:
        # Wait a bit then move to next waypoint
        var timer = Timer.new()
        timer.wait_time = 0.5
        timer.one_shot = true
        timer.timeout.connect(_move_to_next_waypoint)
        add_child(timer)
        timer.start()

func _on_movement_failed(reason: String):
    print("Movement failed: ", reason)
    _update_performance_display()
    
    if auto_mode:
        # Continue to next waypoint even on failure
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.one_shot = true
        timer.timeout.connect(_move_to_next_waypoint)
        add_child(timer)
        timer.start()

func _create_waypoint_markers():
    for i in range(test_waypoints.size()):
        var marker = MeshInstance3D.new()
        
        # Create sphere mesh
        var sphere = SphereMesh.new()
        sphere.radius = 0.3
        sphere.height = 0.6
        sphere.radial_segments = 16
        sphere.rings = 8
        
        marker.mesh = sphere
        
        # Create material
        var material = StandardMaterial3D.new()
        material.albedo_color = Color.WHITE
        material.emission_enabled = true
        material.emission = Color.WHITE
        material.emission_energy = 0.3
        
        marker.material_override = material
        marker.position = test_waypoints[i]
        marker.position.y = 0.5  # Raise markers slightly
        
        # Add label
        var label = Label3D.new()
        label.text = str(i)
        label.position.y = 0.5
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.modulate = Color.BLACK
        label.pixel_size = 0.01
        label.no_depth_test = true
        marker.add_child(label)
        
        get_parent().add_child.call_deferred(marker)
        waypoint_markers.append(marker)
    
    # Highlight first waypoint
    call_deferred("_update_marker_colors")

func _update_marker_colors():
    for i in range(waypoint_markers.size()):
        var material = waypoint_markers[i].material_override as StandardMaterial3D
        if material:
            if i == current_waypoint_index:
                material.albedo_color = Color.YELLOW  # Next target
                material.emission = Color.YELLOW
                material.emission_energy = 0.5
            else:
                material.albedo_color = Color.WHITE
                material.emission = Color.WHITE
                material.emission_energy = 0.3

func _create_performance_display():
    performance_display = RichTextLabel.new()
    performance_display.set_size(Vector2(300, 100))
    performance_display.set_position(Vector2(10, 10))
    performance_display.bbcode_enabled = true
    performance_display.add_theme_color_override("default_color", Color.WHITE)
    performance_display.add_theme_color_override("font_outline_color", Color.BLACK)
    performance_display.add_theme_constant_override("outline_size", 2)
    get_viewport().add_child.call_deferred(performance_display)
    call_deferred("_update_performance_display")

func _update_performance_display():
    if not performance_display:
        return
        
    var text = "[b]Hybrid Movement System[/b]\n"
    
    if hybrid_npc and hybrid_npc.movement_system and hybrid_npc.movement_system.has_method("get_current_system"):
        var system = hybrid_npc.movement_system.get_current_system()
        var color = "green" if system == "navmesh" else "yellow"
        text += "Current: [color=" + color + "]" + system.to_upper() + "[/color]\n"
        
        if hybrid_npc.movement_system.has_method("get_performance_stats"):
            var stats = hybrid_npc.movement_system.get_performance_stats()
            text += "Direct: " + str(stats.stats.direct.successes) + "/" + str(stats.stats.direct.successes + stats.stats.direct.failures) + "\n"
            text += "NavMesh: " + str(stats.stats.navmesh.successes) + "/" + str(stats.stats.navmesh.successes + stats.stats.navmesh.failures)
    
    performance_display.text = text
