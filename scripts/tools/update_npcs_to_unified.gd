@tool
extends EditorScript

# Tool script to update NPCs to use UnifiedNPC
# Run from: Tools > Script Editor > File > Run

func _run():
    print("=== Updating NPCs to UnifiedNPC ===")
    
    # Load the unified NPC base scene
    var unified_base = load("res://scenes/npcs/unified_npc_base.tscn")
    if not unified_base:
        print("ERROR: Could not load unified_npc_base.tscn")
        return
    
    # NPCs to update
    var npc_files = [
        "res://scenes/npcs/scientist_npc.tscn",
        "res://scenes/npcs/chief_scientist_npc.tscn",
        "res://scenes/npcs/engineer_npc.tscn",
        "res://scenes/npcs/medical_officer_npc.tscn",
        "res://scenes/npcs/security_chief_npc.tscn",
        "res://scenes/npcs/security_npc.tscn",
        "res://scenes/npcs/ai_specialist_npc.tscn"
    ]
    
    for npc_path in npc_files:
        print("\nProcessing: ", npc_path)
        
        # Check if file exists
        if not FileAccess.file_exists(npc_path):
            print("  - File not found, skipping")
            continue
        
        # Load the scene
        var scene = load(npc_path)
        if not scene:
            print("  - Could not load scene")
            continue
        
        # Instantiate to check properties
        var instance = scene.instantiate()
        if not instance:
            print("  - Could not instantiate")
            continue
        
        # Get current properties
        var props = {
            "npc_name": instance.get("npc_name"),
            "role": instance.get("role"),
            "initial_dialogue_id": instance.get("initial_dialogue_id"),
            "is_suspicious": instance.get("is_suspicious"),
            "has_alibi": instance.get("has_alibi"),
            "can_be_saboteur": instance.get("can_be_saboteur")
        }
        
        print("  - Current properties:")
        for key in props:
            if props[key] != null:
                print("    ", key, " = ", props[key])
        
        # Free the instance
        instance.queue_free()
        
        print("  - To update this NPC:")
        print("    1. Open ", npc_path)
        print("    2. Right-click root node > Change Type")
        print("    3. Search for 'UnifiedNPC'")
        print("    4. Re-apply the properties above")
        print("    5. Configure Saboteur Mode settings if can_be_saboteur = true")
    
    print("\n=== Update Instructions ===")
    print("Since NPCs are scene instances, they need manual updating:")
    print("1. Open each NPC scene file")
    print("2. Change the root node type to UnifiedNPC")
    print("3. Re-configure the properties")
    print("4. The 'Saboteur Mode' group will appear for NPCs with can_be_saboteur = true")