# Add these methods to npc_base.gd for NavigationAgent3D support

func _navigate_with_agent(delta):
    if not navigation_agent or not navigation_agent is NavigationAgent3D:
        _move_to_target(delta)
        return
        
    # Check if we've reached the target
    if navigation_agent.is_navigation_finished():
        _start_idle()
        return
    
    # Get the next position from navigation agent
    var next_position = navigation_agent.get_next_path_position()
    var direction = (next_position - global_position).normalized()
    direction.y = 0  # Keep on same level
    
    # Set velocity for navigation agent
    var desired_velocity = direction * walk_speed
    
    if navigation_agent.avoidance_enabled:
        navigation_agent.velocity = desired_velocity
    else:
        velocity = desired_velocity
        move_and_slide()

func _on_navigation_velocity_computed(safe_velocity: Vector3):
    # Called by NavigationAgent3D when it computes a safe velocity
    velocity = safe_velocity
    move_and_slide()
    
    # Rotate to face movement direction
    if velocity.length() > 0.1:
        var look_target = global_position + velocity
        look_target.y = global_position.y
        look_at(look_target, Vector3.UP)
        rotation.x = 0
        rotation.z = 0

func _on_navigation_finished():
    print(npc_name + " reached navigation target")
    _start_idle()

func _on_navigation_target_reached():
    print(npc_name + " navigation target reached")
    # Can add specific behavior when reaching target