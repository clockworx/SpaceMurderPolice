@tool
extends EditorScript

func _run():
    print("=== Add Simple Patrol Movement to NPCs ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs found!")
        return
    
    print("\nAdding SimplePatrolMovement to NPCs:")
    
    for npc in npcs_node.get_children():
        if npc is CharacterBody3D:
            # Skip if has saboteur AI
            var has_saboteur = false
            for child in npc.get_children():
                if child.name == "SaboteurPatrolAI":
                    has_saboteur = true
                    print("- ", npc.name, ": Has SaboteurPatrolAI (skipping)")
                    break
            
            if has_saboteur:
                continue
            
            # Remove any existing patrol movement
            for child in npc.get_children():
                if child.name == "SimplePatrolMovement":
                    child.queue_free()
            
            # Add new simple patrol movement node
            var patrol_node = Node.new()
            patrol_node.name = "SimplePatrolMovement"
            
            # Create the patrol script
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
    
    # Define patrol points based on NPC
    match npc.name:
        "MedicalOfficer":
            patrol_points = [
                Vector3(30, 0.5, 0),
                Vector3(35, 0.5, 5),
                Vector3(30, 0.5, 10),
                Vector3(25, 0.5, 5)
            ]
        "ChiefScientist":
            patrol_points = [
                Vector3(0, 0.5, 0),
                Vector3(5, 0.5, 5),
                Vector3(0, 0.5, 10),
                Vector3(-5, 0.5, 5)
            ]
        "SecurityChief":
            patrol_points = [
                Vector3(-10, 0.5, -5),
                Vector3(-5, 0.5, -10),
                Vector3(0, 0.5, -5),
                Vector3(-5, 0.5, 0)
            ]
        "AISpecialist":
            patrol_points = [
                Vector3(15, 0.5, -10),
                Vector3(20, 0.5, -5),
                Vector3(15, 0.5, 0),
                Vector3(10, 0.5, -5)
            ]
        "SecurityOfficer":
            patrol_points = [
                Vector3(-15, 0.5, 10),
                Vector3(-10, 0.5, 15),
                Vector3(-5, 0.5, 10),
                Vector3(-10, 0.5, 5)
            ]
        _:
            # Default patrol square
            patrol_points = [
                Vector3(10, 0.5, 10),
                Vector3(10, 0.5, -10),
                Vector3(-10, 0.5, -10),
                Vector3(-10, 0.5, 10)
            ]
    
    print(npc.name + " SimplePatrolMovement: Initialized with " + str(patrol_points.size()) + " patrol points")
    
    # Disable parent's physics processing if it exists
    if npc.has_method("set_physics_process"):
        npc.set_physics_process(false)

func _physics_process(delta):
    if not npc or patrol_points.is_empty():
        return
    
    if is_waiting:
        wait_timer -= delta
        if wait_timer <= 0:
            is_waiting = false
            current_point = (current_point + 1) % patrol_points.size()
            print(npc.name + " moving to point " + str(current_point))
        return
    
    var target = patrol_points[current_point]
    var distance = npc.global_position.distance_to(target)
    
    if distance < 1.0:
        # Reached waypoint
        is_waiting = true
        wait_timer = 2.0
        npc.velocity = Vector3.ZERO
        print(npc.name + " reached point " + str(current_point))
    else:
        # Move toward target
        var direction = (target - npc.global_position).normalized()
        direction.y = 0
        
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
            patrol_node.set_script(new_script)
            
            # Add to NPC
            npc.add_child(patrol_node)
            patrol_node.owner = edited_scene
            
            print("- ", npc.name, ": Added SimplePatrolMovement")
            
            # Fix NPC position
            npc.position.y = 0.5
    
    print("\n✓ Simple patrol movement added!")
    print("\nWhat this does:")
    print("- Each NPC gets a dedicated patrol movement node")
    print("- Movement is handled directly with velocity and move_and_slide()")
    print("- Each NPC has unique patrol points")
    print("- Parent physics processing is disabled to avoid conflicts")
    print("\nThis should make NPCs move like the saboteur does!")
