@tool
extends EditorScript

func _run():
    print("=== Fix Patrol Points for NPCs ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    print("\nUpdating patrol points to avoid walls:")
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Find SimplePatrolMovement node
            for child in npc.get_children():
                if child.name == "SimplePatrolMovement":
                    # Update the script with better patrol points
                    var script_code = """extends Node

var npc: CharacterBody3D
var patrol_points = []
var current_point = 0
var move_speed = 3.0
var wait_timer = 0.0
var is_waiting = false
var rotation_speed = 5.0

func _ready():
    npc = get_parent()
    
    # Define patrol points in the main hallway (safe from walls)
    match npc.name:
        "MedicalOfficer":
            patrol_points = [
                Vector3(2, 0.5, 5),     # Near medical bay door in hallway
                Vector3(2, 0.5, 10),    # North in hallway
                Vector3(0, 0.5, 10),    # Center north
                Vector3(0, 0.5, 5)      # Back to start
            ]
        "ChiefScientist":
            patrol_points = [
                Vector3(0, 0.5, 10),    # North center hallway
                Vector3(2, 0.5, 10),    # North east hallway
                Vector3(2, 0.5, 15),    # Far north
                Vector3(0, 0.5, 15)     # Far north center
            ]
        "SecurityChief":
            patrol_points = [
                Vector3(-2, 0.5, -5),   # Near security door in hallway
                Vector3(-2, 0.5, 0),    # Center west hallway
                Vector3(0, 0.5, 0),     # Center
                Vector3(0, 0.5, -5)     # Back
            ]
        "AISpecialist":
            patrol_points = [
                Vector3(0, 0.5, -10),   # South center hallway
                Vector3(2, 0.5, -10),   # South east hallway
                Vector3(2, 0.5, -15),   # Far south
                Vector3(0, 0.5, -15)    # Far south center
            ]
        "SecurityOfficer":
            patrol_points = [
                Vector3(-2, 0.5, 0),    # West hallway
                Vector3(-2, 0.5, 5),    # North west
                Vector3(-2, 0.5, -5),   # South west
                Vector3(0, 0.5, 0)      # Center
            ]
        "Engineer":
            # Special case - might have saboteur AI
            patrol_points = [
                Vector3(2, 0.5, -10),   # Near engineering in hallway
                Vector3(0, 0.5, -10),   # Center south
                Vector3(0, 0.5, -5),    # Center
                Vector3(2, 0.5, -5)     # East
            ]
        _:
            # Default safe patrol in center hallway
            patrol_points = [
                Vector3(0, 0.5, 5),
                Vector3(2, 0.5, 5),
                Vector3(2, 0.5, -5),
                Vector3(0, 0.5, -5)
            ]
    
    print(npc.name + " SimplePatrolMovement: Updated with safe hallway patrol points")

func _physics_process(delta):
    if not npc or patrol_points.is_empty():
        return
    
    if is_waiting:
        wait_timer -= delta
        if wait_timer <= 0:
            is_waiting = false
            current_point = (current_point + 1) % patrol_points.size()
        return
    
    var target = patrol_points[current_point]
    var distance = npc.global_position.distance_to(target)
    
    if distance < 1.0:
        # Reached waypoint
        is_waiting = true
        wait_timer = randf_range(1.5, 3.0)  # Random wait time
        npc.velocity = Vector3.ZERO
    else:
        # Move toward target
        var direction = (target - npc.global_position).normalized()
        direction.y = 0
        
        # Check for obstacles
        var space_state = npc.get_world_3d().direct_space_state
        var from = npc.global_position + Vector3.UP * 0.5
        var to = from + direction * 1.5
        
        var query = PhysicsRayQueryParameters3D.create(from, to)
        query.exclude = [npc]
        query.collision_mask = 1  # Environment layer
        
        var result = space_state.intersect_ray(query)
        if result:
            # Wall detected, try to move around
            var left_dir = direction.rotated(Vector3.UP, PI/2)
            var right_dir = direction.rotated(Vector3.UP, -PI/2)
            
            # Test left
            query.to = from + left_dir * 1.5
            var left_result = space_state.intersect_ray(query)
            
            # Test right
            query.to = from + right_dir * 1.5
            var right_result = space_state.intersect_ray(query)
            
            if not left_result:
                direction = left_dir
            elif not right_result:
                direction = right_dir
            else:
                # Both blocked, skip to next waypoint
                current_point = (current_point + 1) % patrol_points.size()
                return
        
        # Set velocity
        npc.velocity.x = direction.x * move_speed
        npc.velocity.z = direction.z * move_speed
        
        # Rotate smoothly toward movement direction
        if direction.length() > 0.1:
            var target_transform = npc.transform.looking_at(npc.global_position + direction, Vector3.UP)
            npc.transform = npc.transform.interpolate_with(target_transform, rotation_speed * delta)
            npc.rotation.x = 0
            npc.rotation.z = 0
    
    # Apply gravity
    if not npc.is_on_floor():
        npc.velocity.y -= 9.8 * delta
    else:
        npc.velocity.y = 0
    
    # Move the character
    npc.move_and_slide()
"""
                    
                    var new_script = GDScript.new()
                    new_script.source_code = script_code
                    child.set_script(new_script)
                    
                    print("- Updated ", npc.name, " patrol points")
                    break
    
    # Also ensure NPCs start in safe positions
    print("\nMoving NPCs to safe starting positions:")
    
    var safe_positions = {
        "MedicalOfficer": Vector3(2, 0.5, 5),
        "ChiefScientist": Vector3(0, 0.5, 10),
        "SecurityChief": Vector3(-2, 0.5, -5),
        "AISpecialist": Vector3(0, 0.5, -10),
        "SecurityOfficer": Vector3(-2, 0.5, 0),
        "Engineer": Vector3(2, 0.5, -10)
    }
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D and npc.name in safe_positions:
            npc.position = safe_positions[npc.name]
            print("- Moved ", npc.name, " to ", safe_positions[npc.name])
    
    print("\n✓ Patrol points fixed!")
    print("\nWhat was changed:")
    print("- All patrol points now in the main hallway (X between -2 and 2)")
    print("- Added obstacle detection to avoid walls")
    print("- NPCs start in safe positions")
    print("- Random wait times at waypoints")
    print("\nNPCs should no longer get stuck on walls!")