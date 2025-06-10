extends Node3D

# Test script for sound detection behavior
# Attach this to the root of a test scene

var test_npc: NPCBase
var player: CharacterBody3D

func _ready():
    print("=== Sound Detection Test ===")
    
    # Find the test NPC
    test_npc = get_node_or_null("TestNPC")
    if not test_npc:
        push_error("TestNPC not found in scene")
        return
    
    # Find player
    player = get_tree().get_first_node_in_group("player")
    if not player:
        push_error("Player not found in scene")
        return
    
    # Configure NPC for sound detection
    test_npc.can_be_saboteur = true
    test_npc.enable_sound_detection = true
    test_npc.sound_detection_radius = 8.0
    test_npc.crouched_sound_radius_multiplier = 0.4
    test_npc.running_sound_radius_multiplier = 1.5
    test_npc.sound_investigation_duration = 2.0
    test_npc.show_sound_detection_area = true
    test_npc.show_state_label = true
    test_npc.debug_state_changes = true
    
    print("Test NPC configured:")
    print("- Name: ", test_npc.npc_name)
    print("- Sound detection enabled: ", test_npc.enable_sound_detection)
    print("- Sound detection radius: ", test_npc.sound_detection_radius)
    print("- Crouch multiplier: ", test_npc.crouched_sound_radius_multiplier)
    print("- Run multiplier: ", test_npc.running_sound_radius_multiplier)
    
    # Connect to state changes
    test_npc.state_changed.connect(_on_npc_state_changed)
    
    print("\nTest Instructions:")
    print("1. Walk near NPC (out of sight) - should hear you at 8m")
    print("2. Crouch and move - detection range reduced to 3.2m (40%)")
    print("3. Run near NPC - detection range increased to 12m")
    print("4. NPC should investigate sound location for 2 seconds")
    print("5. After investigation, NPC returns to patrol")
    print("\nPress 'S' to manually trigger a sound at player position")
    print("Press 'D' to toggle sound detection area visualization")

func _on_npc_state_changed(old_state, new_state):
    var old_name = NPCBase.MovementState.keys()[old_state]
    var new_name = NPCBase.MovementState.keys()[new_state]
    print("NPC State Changed: ", old_name, " -> ", new_name)
    
    if new_state == NPCBase.MovementState.INVESTIGATE and test_npc.is_investigating_sound:
        print("  Sound detected! NPC is investigating noise.")
    elif new_state == NPCBase.MovementState.RETURN_TO_PATROL:
        print("  Investigation complete. Returning to patrol.")

func _input(event):
    if event.is_action_pressed("ui_text_submit") and Input.is_key_pressed(KEY_S):
        # Manually trigger sound at player position
        if player and test_npc:
            print("\nManually triggering sound at player position")
            test_npc.hear_sound(player.global_position, 10.0)
    
    if event.is_action_pressed("ui_text_submit") and Input.is_key_pressed(KEY_D):
        # Toggle sound detection visualization
        if test_npc:
            test_npc.show_sound_detection_area = not test_npc.show_sound_detection_area
            print("\nSound detection area visible: ", test_npc.show_sound_detection_area)