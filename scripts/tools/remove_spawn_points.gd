@tool
extends EditorScript

func _run():
    var scene_root = get_scene()
    if not scene_root:
        print("No scene open!")
        return
        
    print("Removing spawn points from scene...")
    
    # Find and remove GameplayElements node (contains spawn points)
    var gameplay_elements = scene_root.get_node_or_null("GameplayElements")
    if gameplay_elements:
        print("Found GameplayElements node with ", gameplay_elements.get_child_count(), " children")
        
        # List what's being removed
        for child in gameplay_elements.get_children():
            print("  - Removing: ", child.name)
            for grandchild in child.get_children():
                print("    - ", grandchild.name)
        
        # Remove the entire GameplayElements node
        gameplay_elements.queue_free()
        print("GameplayElements node queued for deletion")
    else:
        print("No GameplayElements node found")
    
    # Also look for any stray spawn points
    var spawn_points_found = 0
    for node in _find_all_nodes(scene_root):
        if "spawn" in node.name.to_lower() and node is Marker3D:
            print("Found spawn point: ", node.name, " at ", node.get_path())
            node.queue_free()
            spawn_points_found += 1
    
    if spawn_points_found > 0:
        print("Removed ", spawn_points_found, " additional spawn points")
    
    print("\nDone! Save the scene to keep changes.")

func _find_all_nodes(node: Node) -> Array:
    var results = [node]
    for child in node.get_children():
        results.append_array(_find_all_nodes(child))
    return results