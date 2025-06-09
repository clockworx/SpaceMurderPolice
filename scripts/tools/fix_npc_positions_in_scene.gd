@tool
extends EditorScript

# Run this script in the editor to permanently fix NPC positions in the scene

func _run():
    var scene_root = get_scene()
    if not scene_root:
        print("No scene open! Open NewStation.tscn first.")
        return
        
    print("Fixing NPC positions in scene...")
    
    # Correct positions for each NPC
    var correct_positions = {
        "ChiefScientist": Vector3(-8.0, 0.1, 10.0),    # Dr. Marcus Webb - Laboratory 3
        "MedicalOfficer": Vector3(8.0, 0.1, 5.0),       # Dr. Sarah Chen - Medical Bay
        "SecurityChief": Vector3(-8.0, 0.1, -5.0),      # Jake Torres - Security Office
        "Engineer": Vector3(8.0, 0.1, -10.0)            # Alex Chen - Engineering
    }
    
    # Find NPCs node
    var npcs_node = scene_root.get_node_or_null("NPCs")
    if not npcs_node:
        print("ERROR: NPCs node not found!")
        return
        
    print("Found NPCs node with ", npcs_node.get_child_count(), " children")
    
    # Fix each NPC
    for child in npcs_node.get_children():
        if child.name in correct_positions:
            var old_pos = child.position
            var new_pos = correct_positions[child.name]
            
            child.position = new_pos
            child.owner = scene_root  # Ensure it's saved with the scene
            
            print("  ", child.name, ":")
            print("    Old position: ", old_pos)
            print("    New position: ", new_pos)
            
            # Try to get NPC name for clarity
            if child.has_property("npc_name"):
                print("    Character: ", child.get("npc_name"))
    
    print("\nDone! Save the scene (Ctrl+S) to keep these changes permanently.")