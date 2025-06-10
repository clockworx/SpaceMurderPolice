extends Node

# Test script for NPC movement states
# Add this to the scene to test state switching

var test_timer: float = 0.0
var current_test_phase: int = 0
var npcs: Array = []

func _ready():
    print("=== NPC State Test Started ===")
    
    # Wait for scene to load
    await get_tree().process_frame
    
    # Find all NPCs with waypoint system
    _find_waypoint_npcs(get_tree().current_scene, npcs)
    
    if npcs.is_empty():
        print("ERROR: No waypoint NPCs found!")
        queue_free()
        return
    
    print("Found ", npcs.size(), " NPCs to test")
    print("Test will cycle through states every 5 seconds")
    print("Press 1, 2, 3 keys to manually switch states")

func _find_waypoint_npcs(node: Node, result: Array):
    if node.has_method("set_state"):
        result.append(node)
        print("  - Found: ", node.name)
    
    for child in node.get_children():
        _find_waypoint_npcs(child, result)

func _input(event):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                print("\n=== Manual: Setting all NPCs to PATROL ===")
                for npc in npcs:
                    npc.set_patrol_state()
            KEY_2:
                print("\n=== Manual: Setting all NPCs to IDLE ===")
                for npc in npcs:
                    npc.set_idle_state()
            KEY_3:
                print("\n=== Manual: Setting all NPCs to TALK ===")
                # Make them face the player
                var player = get_tree().get_first_node_in_group("player")
                if player:
                    for npc in npcs:
                        npc.set_talk_state(player.global_position)
                else:
                    print("No player found, using world origin")
                    for npc in npcs:
                        npc.set_talk_state(Vector3.ZERO)
            KEY_4:
                print("\n=== Manual: Resume previous state ===")
                for npc in npcs:
                    npc.resume_previous_state()

func _process(delta):
    test_timer += delta
    
    # Auto cycle through states every 5 seconds
    if test_timer >= 5.0:
        test_timer = 0.0
        current_test_phase = (current_test_phase + 1) % 4
        
        match current_test_phase:
            0:
                print("\n=== Auto Test: PATROL state ===")
                for npc in npcs:
                    npc.set_patrol_state()
            1:
                print("\n=== Auto Test: IDLE state ===")
                for npc in npcs:
                    npc.set_idle_state()
            2:
                print("\n=== Auto Test: TALK state (facing origin) ===")
                var player = get_tree().get_first_node_in_group("player")
                var target = player.global_position if player else Vector3(0, 0, 0)
                for npc in npcs:
                    npc.set_talk_state(target)
            3:
                print("\n=== Auto Test: Resume previous state ===")
                for npc in npcs:
                    npc.resume_previous_state()

func _exit_tree():
    print("\n=== NPC State Test Ended ===")
    # Reset all NPCs to patrol
    for npc in npcs:
        if is_instance_valid(npc):
            npc.set_patrol_state()