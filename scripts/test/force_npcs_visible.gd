@tool
extends EditorScript

func _run():
    var scene_root = get_scene()
    if not scene_root:
        print("No scene open!")
        return
        
    print("Forcing all NPCs visible in scene...")
    
    # Find NPCs parent
    var npcs_parent = scene_root.get_node_or_null("NPCs")
    if npcs_parent:
        npcs_parent.visible = true
        print("Set NPCs parent visible")
        
        for child in npcs_parent.get_children():
            child.visible = true
            print("Set ", child.name, " visible")
            
            # Also check child nodes
            var mesh = child.get_node_or_null("MeshInstance3D")
            if mesh:
                mesh.visible = true
                
            var head = child.get_node_or_null("Head")
            if head:
                head.visible = true
                for label in head.get_children():
                    label.visible = true
    
    # Check for NPCs anywhere in the scene
    var all_npcs = _find_nodes_by_group(scene_root, "npcs")
    print("\nFound ", all_npcs.size(), " NPCs in 'npcs' group")
    for npc in all_npcs:
        npc.visible = true
        npc.owner = scene_root  # Ensure it's saved with the scene
        print("Ensured ", npc.name, " is visible and owned by scene")
    
    print("\nDone! Save the scene to keep changes.")

func _find_nodes_by_group(node: Node, group: String) -> Array:
    var results = []
    if node.is_in_group(group):
        results.append(node)
    for child in node.get_children():
        results.append_array(_find_nodes_by_group(child, group))
    return results