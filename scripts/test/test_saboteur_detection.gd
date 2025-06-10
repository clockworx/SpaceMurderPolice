extends Node3D

# Test script for saboteur detection behavior
# Attach this to the root of a test scene

var test_npc: UnifiedNPC
var player: CharacterBody3D

func _ready():
    print("=== Saboteur Detection Test ===")
    
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
    
    # Configure NPC for saboteur behavior
    test_npc.can_be_saboteur = true
    test_npc.enable_saboteur_behavior = true
    test_npc.detection_range = 10.0
    test_npc.vision_angle = 60.0
    test_npc.investigation_duration = 3.0
    test_npc.show_state_label = true
    test_npc.debug_state_changes = true
    
    print("Test NPC configured:")
    print("- Name: ", test_npc.npc_name)
    print("- Can be saboteur: ", test_npc.can_be_saboteur)
    print("- Saboteur behavior enabled: ", test_npc.enable_saboteur_behavior)
    print("- Detection range: ", test_npc.detection_range)
    print("- Vision angle: ", test_npc.vision_angle)
    
    # Connect to state changes
    test_npc.state_changed.connect(_on_npc_state_changed)
    
    print("\nTest Instructions:")
    print("1. Move player in front of NPC to trigger INVESTIGATE state")
    print("2. Hide and watch NPC investigate for 3 seconds")
    print("3. NPC should return to PATROL after investigation")
    print("4. Press 'T' to toggle saboteur behavior on/off")

func _on_npc_state_changed(old_state, new_state):
    var old_name = UnifiedNPC.MovementState.keys()[old_state]
    var new_name = UnifiedNPC.MovementState.keys()[new_state]
    print("NPC State Changed: ", old_name, " -> ", new_name)
    
    if new_state == UnifiedNPC.MovementState.INVESTIGATE:
        print("  Detection triggered! NPC is investigating.")
    elif new_state == UnifiedNPC.MovementState.RETURN_TO_PATROL:
        print("  Investigation complete. Returning to patrol.")
    elif new_state == UnifiedNPC.MovementState.PATROL and old_state == UnifiedNPC.MovementState.RETURN_TO_PATROL:
        print("  Successfully returned to patrol route!")

func _input(event):
    if event.is_action_pressed("ui_text_submit"):  # T key
        if test_npc:
            test_npc.enable_saboteur_behavior = not test_npc.enable_saboteur_behavior
            print("\nSaboteur behavior toggled: ", test_npc.enable_saboteur_behavior)