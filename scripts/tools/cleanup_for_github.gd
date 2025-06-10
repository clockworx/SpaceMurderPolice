@tool
extends EditorScript

# Clean up the project for GitHub upload

func _run():
    print("=== CLEANING PROJECT FOR GITHUB ===")
    
    var scene = get_scene()
    if not scene:
        print("ERROR: No scene open")
        return
    
    # Find all NPCs
    var npcs = []
    _find_npcs(scene, npcs)
    
    print("Found ", npcs.size(), " NPCs to clean up")
    
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        print("\n", npc_name, ":")
        
        if npc.has_method("set"):
            # Disable all debug visuals
            npc.set("show_detection_indicator", false)
            npc.set("show_vision_cone", false)
            npc.set("show_state_label", false)
            npc.set("debug_state_changes", false)
            print("  ✓ Disabled all debug visuals")
            
            # Ensure detection is enabled but not visible
            npc.set("enable_los_detection", true)
            print("  ✓ Detection enabled (invisible)")
        
        # Hide any existing debug meshes
        var detection_indicator = npc.get_node_or_null("DetectionIndicator")
        if detection_indicator:
            detection_indicator.visible = false
        
        var vision_cone = npc.get_node_or_null("VisionCone")
        if vision_cone:
            vision_cone.visible = false
        
        var state_label = npc.get_node_or_null("StateLabel")
        if state_label:
            state_label.visible = false
    
    print("\n=== CLEANUP COMPLETE ===")
    print("✓ All debug visuals disabled")
    print("✓ Detection system active but invisible")
    print("✓ Ready for GitHub upload")
    print("\nDon't forget to:")
    print("1. Save all scenes")
    print("2. Close any test/debug scenes")
    print("3. Delete or move any test scripts in /scripts/tools/")
    print("4. Check .gitignore includes necessary files")

func _find_npcs(node: Node, result: Array):
    if node is CharacterBody3D:
        if node.has_method("get") and node.get("npc_name"):
            result.append(node)
    
    for child in node.get_children():
        _find_npcs(child, result)