@tool
extends EditorScript

# Run this in the Script Editor with NewStation.tscn open
# It will update all NPCs to use hybrid movement and proper configuration

func _run():
    var scene = get_scene()
    if not scene or scene.name != "NewStation":
        print("Please open NewStation.tscn first!")
        return
    
    print("Updating NewStation NPCs...")
    
    # Find NPCs node
    var npcs_node = scene.get_node_or_null("NPCs")
    if not npcs_node:
        print("No NPCs node found!")
        return
    
    # Update each NPC
    for npc in npcs_node.get_children():
        if npc.has_method("set"):
            print("\nUpdating ", npc.name, "...")
            
            # Enable hybrid movement
            npc.set("use_hybrid_movement", true)
            npc.set("use_waypoints", false)  # Disable for now
            npc.set("wander_radius", 5.0)
            
            # Make sure they're on the right collision layer
            npc.set("collision_layer", 4)  # Interactable
            npc.set("collision_mask", 1)   # Collide with environment
            
            # Set to IDLE state initially
            npc.set("current_state", 1)
            
            # Fix specific NPCs
            match npc.name:
                "MedicalOfficer":
                    npc.set("npc_name", "Dr. Sarah Chen")
                    npc.set("role", "Medical Officer")
                    npc.set("can_be_saboteur", false)
                    npc.set("assigned_room", "Medical Bay")
                    # Move to Medical Bay area
                    npc.position = Vector3(43.6, 0.1, -1.0)  # Keep current position, seems good
                    
                "ChiefScientist":
                    npc.set("npc_name", "Dr. Marcus Webb")
                    npc.set("role", "Chief Scientist")
                    npc.set("can_be_saboteur", false)
                    npc.set("assigned_room", "Laboratory")
                    # Already in lab area
                    
                "Engineer":
                    npc.set("npc_name", "Alex Chen")
                    npc.set("role", "Station Engineer")
                    npc.set("can_be_saboteur", true)  # This is our saboteur!
                    npc.set("assigned_room", "Engineering Bay")
                    npc.set("enable_saboteur_behavior", true)
                    npc.set("enable_sound_detection", true)
                    npc.set("enable_los_detection", true)
                    # Already in engineering area
                    
                "SecurityChief":
                    # This was mislabeled! Fix it
                    npc.set("npc_name", "Jake Torres")
                    npc.set("role", "Security Chief")
                    npc.set("can_be_saboteur", false)
                    npc.set("assigned_room", "Security Office")
                    # Already in security area
            
            print("  - Name: ", npc.get("npc_name"))
            print("  - Role: ", npc.get("role"))
            print("  - Position: ", npc.position)
            print("  - Hybrid Movement: ", npc.get("use_hybrid_movement"))
            print("  - Can be saboteur: ", npc.get("can_be_saboteur"))
    
    # Check if we need to add missing NPCs
    var has_ai_specialist = false
    var has_security_officer = false
    
    for npc in npcs_node.get_children():
        var npc_name = npc.get("npc_name")
        if npc_name and "Zara" in npc_name:
            has_ai_specialist = true
        if npc_name and "Riley" in npc_name:
            has_security_officer = true
    
    if not has_ai_specialist:
        print("\nMissing AI Specialist - please add manually")
        print("Position: Vector3(25, 0.1, 5) - Communications Center")
        
    if not has_security_officer:
        print("\nMissing Security Officer - please add manually")
        print("Position: Vector3(-10, 0.1, 8) - Near Security Office")
    
    print("\n=== UPDATE COMPLETE ===")
    print("Remember to:")
    print("1. Save the scene (Ctrl+S)")
    print("2. Check NavigationRegion3D is properly set up")
    print("3. Add the two missing NPCs if needed")
    print("4. Test in-game to ensure movement works correctly")
