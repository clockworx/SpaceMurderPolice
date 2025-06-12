extends Node3D

@export var test_waypoints: Array[Vector3] = [
    # Inner square
    Vector3(0, 0, 0),      # 0: Center
    Vector3(2, 0, 2),      # 1: Right-Forward
    Vector3(-2, 0, 2),     # 2: Left-Forward
    Vector3(-2, 0, -2),    # 3: Left-Back
    Vector3(2, 0, -2),     # 4: Right-Back
    
    # Outer corners
    Vector3(6, 0, 6),      # 5: Far Right-Forward
    Vector3(-6, 0, 6),     # 6: Far Left-Forward
    Vector3(-6, 0, -6),    # 7: Far Left-Back
    Vector3(6, 0, -6),     # 8: Far Right-Back
    
    # Cardinal points
    Vector3(8, 0, 0),      # 9: Far Right
    Vector3(-8, 0, 0),     # 10: Far Left
    Vector3(0, 0, 8),      # 11: Far Forward
    Vector3(0, 0, -8),     # 12: Far Back
    
    # Mid-distance points
    Vector3(4, 0, 0),      # 13: Mid Right
    Vector3(-4, 0, 0),     # 14: Mid Left
    Vector3(0, 0, 4),      # 15: Mid Forward
    Vector3(0, 0, -4),     # 16: Mid Back
    
    # Diagonal mid-points
    Vector3(4, 0, 4),      # 17: Mid Right-Forward
    Vector3(-4, 0, 4),     # 18: Mid Left-Forward
    Vector3(-4, 0, -4),    # 19: Mid Left-Back
    Vector3(4, 0, -4)      # 20: Mid Right-Back
]

var direct_npc: NPCBase
var navmesh_npc: NPCBase
var current_waypoint_index: int = 0
var waypoint_markers: Array[MeshInstance3D] = []
var debug_visualizer: Node3D
var target_indicator: MeshInstance3D
var auto_mode: bool = true
var start_delay_timer: Timer

func _ready():
    # Find NPCs
    direct_npc = get_node_or_null("../TestNPC_Direct")
    navmesh_npc = get_node_or_null("../TestNPC_NavMesh")
    
    if not direct_npc or not navmesh_npc:
        push_error("Could not find test NPCs!")
        return
    
    # Create waypoint markers
    _create_waypoint_markers()
    
    # Create target indicator
    _create_target_indicator()
    
    # Create debug visualizer
    var visualizer_script = load("res://scripts/test/movement_debug_visualizer.gd")
    debug_visualizer = Node3D.new()
    debug_visualizer.set_script(visualizer_script)
    get_parent().add_child.call_deferred(debug_visualizer)
    
    # Connect to movement system signals for debugging
    if navmesh_npc.movement_system:
        navmesh_npc.movement_system.movement_completed.connect(_on_navmesh_movement_completed)
        navmesh_npc.movement_system.movement_failed.connect(_on_navmesh_movement_failed)
    
    if direct_npc.movement_system:
        direct_npc.movement_system.movement_completed.connect(_on_direct_movement_completed)
        direct_npc.movement_system.movement_failed.connect(_on_direct_movement_failed)
    
    print("Dual NPC Movement Test Started")
    print("Direct NPC uses: ", "NavMesh" if direct_npc.use_navmesh else "Direct", " movement")
    print("NavMesh NPC uses: ", "NavMesh" if navmesh_npc.use_navmesh else "Direct", " movement")
    
    # Check for NavigationAgent3D (deferred to allow movement system to set up)
    call_deferred("_check_navigation_agent")
    
    print("\nAuto mode is ON - NPCs will move continuously")
    print("Press A to toggle auto mode")
    print("Press N to move both NPCs to next waypoint")
    print("Press R to reset positions")
    print("Press D to move only Direct NPC")
    print("Press M to move only NavMesh NPC")
    
    # Start auto movement after a short delay
    if auto_mode:
        start_delay_timer = Timer.new()
        start_delay_timer.wait_time = 1.0
        start_delay_timer.one_shot = true
        start_delay_timer.timeout.connect(_start_auto_movement)
        add_child(start_delay_timer)
        start_delay_timer.start()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_A:
                auto_mode = !auto_mode
                print("Auto mode: ", "ON" if auto_mode else "OFF")
            KEY_N:
                _move_both_to_next_waypoint()
            KEY_R:
                _reset_positions()
            KEY_D:
                _move_direct_npc()
            KEY_M:
                _move_navmesh_npc()

func _move_both_to_next_waypoint():
    var target = test_waypoints[current_waypoint_index]
    print("\n=== Moving both NPCs to waypoint ", current_waypoint_index, " at ", target, " ===")
    
    if direct_npc:
        print("Direct NPC current position: ", direct_npc.global_position)
        print("Direct NPC state before move: ", direct_npc.current_state)
        direct_npc.set_patrol_state()
        direct_npc.move_to_position(target)
        print("Direct NPC state after move: ", direct_npc.current_state)
    
    if navmesh_npc:
        print("NavMesh NPC current position: ", navmesh_npc.global_position)
        print("NavMesh NPC state before move: ", navmesh_npc.current_state)
        navmesh_npc.set_patrol_state()
        navmesh_npc.move_to_position(target)
        print("NavMesh NPC state after move: ", navmesh_npc.current_state)
        print("NavMesh NPC movement system active: ", navmesh_npc.movement_system.is_active if navmesh_npc.movement_system else "No movement system")
    
    # Update waypoint index
    current_waypoint_index = (current_waypoint_index + 1) % test_waypoints.size()
    _update_marker_colors()

func _move_direct_npc():
    if not direct_npc:
        return
        
    var target = test_waypoints[current_waypoint_index]
    print("\nMoving Direct NPC to waypoint ", current_waypoint_index, " at ", target)
    
    direct_npc.set_patrol_state()
    direct_npc.move_to_position(target)

func _move_navmesh_npc():
    if not navmesh_npc:
        return
        
    var target = test_waypoints[current_waypoint_index]
    print("\nMoving NavMesh NPC to waypoint ", current_waypoint_index, " at ", target)
    
    navmesh_npc.set_patrol_state()
    navmesh_npc.move_to_position(target)
    print("NavMesh NPC current position: ", navmesh_npc.global_position)
    print("NavMesh NPC movement system active: ", navmesh_npc.movement_system.is_active if navmesh_npc.movement_system else "No movement system")

func _reset_positions():
    print("\nResetting NPC positions")
    
    if direct_npc:
        direct_npc.global_position = Vector3(-5, 0.1, 0)
        direct_npc.stop_movement()
        direct_npc.set_idle_state()
    
    if navmesh_npc:
        navmesh_npc.global_position = Vector3(5, 0.1, 0)
        navmesh_npc.stop_movement()
        navmesh_npc.set_idle_state()
    
    current_waypoint_index = 0
    _update_marker_colors()

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
    
    # Highlight first waypoint (deferred to ensure markers are added)
    call_deferred("_update_marker_colors")

func _update_marker_colors():
    for i in range(waypoint_markers.size()):
        var material = waypoint_markers[i].material_override as StandardMaterial3D
        if material:
            if i == current_waypoint_index:
                material.albedo_color = Color.YELLOW  # Next target
                material.emission = Color.YELLOW
                material.emission_energy = 0.5
            elif i == (current_waypoint_index - 1) % test_waypoints.size():
                material.albedo_color = Color.GREEN  # Previous target
                material.emission = Color.GREEN
                material.emission_energy = 0.3
            else:
                material.albedo_color = Color.WHITE
                material.emission = Color.WHITE
                material.emission_energy = 0.3
    
    # Update target indicator position
    if target_indicator and current_waypoint_index < test_waypoints.size():
        target_indicator.position = test_waypoints[current_waypoint_index]
        target_indicator.position.y = 2.5
        target_indicator.visible = true
                
func _on_navmesh_movement_completed():
    print("NavMesh NPC reached destination")
    if auto_mode:
        _check_both_npcs_completed()
    
func _on_navmesh_movement_failed(reason: String):
    print("NavMesh NPC movement failed: ", reason)
    
func _on_direct_movement_completed():
    print("Direct NPC reached destination")
    if auto_mode:
        _check_both_npcs_completed()
    
func _on_direct_movement_failed(reason: String):
    print("Direct NPC movement failed: ", reason)
    if auto_mode:
        _check_both_npcs_completed()

func _start_auto_movement():
    print("\nStarting automatic movement...")
    # Prevent NPCs from going back to idle positions
    if direct_npc:
        direct_npc.use_waypoints = false
        direct_npc.wander_radius = 0.0
    if navmesh_npc:
        navmesh_npc.use_waypoints = false
        navmesh_npc.wander_radius = 0.0
    
    _move_both_to_next_waypoint()

func _check_both_npcs_completed():
    # Check if both NPCs have finished moving
    var direct_done = !direct_npc or !direct_npc.movement_system or !direct_npc.movement_system.is_active
    var navmesh_done = !navmesh_npc or !navmesh_npc.movement_system or !navmesh_npc.movement_system.is_active
    
    if direct_done and navmesh_done:
        # Wait a bit then move to next waypoint
        var timer = Timer.new()
        timer.wait_time = 0.5
        timer.one_shot = true
        timer.timeout.connect(_move_both_to_next_waypoint)
        add_child(timer)
        timer.start()

func _check_navigation_agent():
    if navmesh_npc:
        var nav_agent_found = false
        for child in navmesh_npc.get_children():
            if child is NavigationAgent3D:
                nav_agent_found = true
                print("NavigationAgent3D found in NavMesh NPC")
                break
        if not nav_agent_found:
            print("WARNING: No NavigationAgent3D found in NavMesh NPC!")

func _create_target_indicator():
    # Create a large arrow or cylinder to show current target
    target_indicator = MeshInstance3D.new()
    
    var cylinder = CylinderMesh.new()
    cylinder.height = 5.0
    cylinder.top_radius = 0.1
    cylinder.bottom_radius = 0.5
    
    target_indicator.mesh = cylinder
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.RED
    material.emission_enabled = true
    material.emission = Color.RED
    material.emission_energy = 1.0
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.5
    
    target_indicator.material_override = material
    target_indicator.visible = false
    
    get_parent().add_child.call_deferred(target_indicator)

func _process(_delta: float) -> void:
    # Draw debug lines for active movement
    if debug_visualizer:
        # Clear old lines
        debug_visualizer.clear_all_lines()
        
        # Draw line for Direct NPC
        if direct_npc and direct_npc.movement_system and direct_npc.movement_system.is_active:
            if direct_npc.movement_system.has_method("get_current_target"):
                var target = direct_npc.movement_system.get_current_target()
                if target != Vector3.ZERO:
                    debug_visualizer.draw_line(
                        direct_npc.global_position + Vector3.UP * 0.5,
                        target + Vector3.UP * 0.5,
                        Color.BLUE,
                        0.1
                    )
        
        # Draw line for NavMesh NPC
        if navmesh_npc and navmesh_npc.movement_system and navmesh_npc.movement_system.is_active:
            if navmesh_npc.movement_system.has_method("get_current_target"):
                var target = navmesh_npc.movement_system.get_current_target()
                if target != Vector3.ZERO:
                    debug_visualizer.draw_line(
                        navmesh_npc.global_position + Vector3.UP * 0.5,
                        target + Vector3.UP * 0.5,
                        Color.GREEN,
                        0.1
                    )
