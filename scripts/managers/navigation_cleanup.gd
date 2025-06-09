extends Node

# This script completely cleans up navigation issues

func _ready():
    print("\n=== NAVIGATION CLEANUP ===")
    
    # First, clear ALL navigation regions
    var all_nav_regions = []
    _find_all_nodes_of_type(get_tree().root, NavigationRegion3D, all_nav_regions)
    
    print("Found ", all_nav_regions.size(), " NavigationRegion3D nodes in entire tree")
    
    # Remove all but the one in the current scene
    var scene_nav_region = null
    for nav in all_nav_regions:
        if get_tree().current_scene.is_ancestor_of(nav):
            if scene_nav_region == null:
                scene_nav_region = nav
                print("Keeping scene NavigationRegion3D: ", nav.get_path())
            else:
                print("Removing duplicate NavigationRegion3D: ", nav.get_path())
                nav.queue_free()
        else:
            print("Removing out-of-scene NavigationRegion3D: ", nav.get_path())
            nav.queue_free()
    
    # If no navigation region in scene, NPCs will use simple movement
    if not scene_nav_region:
        print("No NavigationRegion3D in scene - NPCs will use simple movement")
        return
    
    # Clear the navigation server to reset everything
    NavigationServer3D.map_force_update(scene_nav_region.get_navigation_map())
    
    # Check project settings
    var project_cell_size = ProjectSettings.get_setting("navigation/3d/default_cell_size", 0.25)
    var merge_scale = ProjectSettings.get_setting("navigation/3d/merge_rasterizer_cell_scale", 1.0)
    
    print("\nProject Settings:")
    print("  Default cell size: ", project_cell_size)
    print("  Merge rasterizer scale: ", merge_scale)
    
    # Temporarily set merge scale to avoid conflicts
    if merge_scale != 0.001:
        print("  Setting merge_rasterizer_cell_scale to 0.001 to avoid edge conflicts")
        ProjectSettings.set_setting("navigation/3d/merge_rasterizer_cell_scale", 0.001)
    
    # Ensure the navigation mesh has proper settings
    if scene_nav_region.navigation_mesh:
        var nav_mesh = scene_nav_region.navigation_mesh
        print("\nNavigation Mesh Settings:")
        print("  Cell size: ", nav_mesh.cell_size)
        print("  Cell height: ", nav_mesh.cell_height)
        
        # Force update to match project settings
        if abs(nav_mesh.cell_size - project_cell_size) > 0.001:
            print("  Updating cell size to match project: ", project_cell_size)
            nav_mesh.cell_size = project_cell_size
            nav_mesh.cell_height = project_cell_size
    
    print("\n=== NAVIGATION CLEANUP COMPLETE ===")

func _find_all_nodes_of_type(node: Node, type: Variant, result: Array):
    if is_instance_of(node, type):
        result.append(node)
    for child in node.get_children():
        _find_all_nodes_of_type(child, type, result)