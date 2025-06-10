extends Node

# Quick toggle for NPC state labels
# Add this to the scene for easy debugging

func _ready():
    print("=== State Label Toggle Ready ===")
    print("Press L to toggle state labels on all NPCs")

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_L:
            toggle_all_state_labels()

func toggle_all_state_labels():
    var npcs = get_tree().get_nodes_in_group("npcs")
    var any_visible = false
    
    # Check if any labels are currently visible
    for npc in npcs:
        if npc.has_method("get") and npc.get("show_state_label"):
            any_visible = true
            break
    
    # Toggle all
    var new_state = not any_visible
    for npc in npcs:
        if npc.has_method("set"):
            npc.set("show_state_label", new_state)
            
            # Update existing label visibility
            var label = npc.get_node_or_null("StateLabel")
            if label:
                label.visible = new_state
            elif new_state and npc.has_method("_create_state_label"):
                # Create label if it doesn't exist
                npc.call("_create_state_label")
    
    print("State labels: ", "ON" if new_state else "OFF")