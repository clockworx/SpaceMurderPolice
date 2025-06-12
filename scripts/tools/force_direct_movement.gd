@tool
extends EditorScript

func _run():
    print("=== Force Direct Movement on NPCs ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    # Create simple movement waypoints in a large square
    var waypoint_positions = [
        Vector3(15, 0.5, 15),    # Northeast
        Vector3(15, 0.5, -15),   # Southeast  
        Vector3(-15, 0.5, -15),  # Southwest
        Vector3(-15, 0.5, 15),   # Northwest
    ]
    
    print("\nAdding direct movement to NPCs:")
    
    var npc_index = 0
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Skip if has saboteur AI
            var has_saboteur = false
            for child in npc.get_children():
                if child.name == "SaboteurPatrolAI":
                    has_saboteur = true
                    break
            
            if has_saboteur:
                print("- ", npc.name, ": Skipped (has SaboteurPatrolAI)")
                continue
            
            # Add a simple movement script to override everything
            var script_text = """
extends CharacterBody3D

var waypoints = %s
var current_waypoint = 0
var speed = 3.0
var wait_timer = 0.0
var is_waiting = false

func _ready():
    # Start at different waypoint for each NPC
    current_waypoint = %d %% waypoints.size()
    print(name + " starting at waypoint " + str(current_waypoint))

func _physics_process(delta):
    if is_waiting:
        wait_timer -= delta
        if wait_timer <= 0:
            is_waiting = false
            current_waypoint = (current_waypoint + 1) %% waypoints.size()
        return
    
    var target = waypoints[current_waypoint]
    var distance = global_position.distance_to(target)
    
    if distance < 1.0:
        # Reached waypoint
        is_waiting = true
        wait_timer = 2.0
        velocity = Vector3.ZERO
    else:
        # Move to waypoint
        var direction = (target - global_position).normalized()
        direction.y = 0
        
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        
        # Face movement direction
        if direction.length() > 0.1:
            look_at(global_position + direction, Vector3.UP)
            rotation.x = 0
            rotation.z = 0
    
    # Apply gravity
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0
    
    move_and_slide()
""" % [str(waypoint_positions), npc_index]
            
            # Create new script
            var new_script = GDScript.new()
            new_script.source_code = script_text
            
            # Store old script reference if exists
            var old_script = npc.get_script()
            
            # Apply new script
            npc.set_script(new_script)
            
            print("- ", npc.name, ": Added direct movement script")
            
            # Also fix position
            npc.position.y = 0.5
            
            npc_index += 1
    
    print("\n✓ Direct movement forced!")
    print("\nNPCs now have simple direct movement that:")
    print("- Moves between 4 waypoints in a square pattern")
    print("- Each NPC starts at a different waypoint")
    print("- Waits 2 seconds at each waypoint")
    print("- Handles gravity and collision properly")
    print("\nThis bypasses all complex movement systems.")