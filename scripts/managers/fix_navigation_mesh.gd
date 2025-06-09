extends Node

# This script fixes navigation mesh conflicts

func _ready():
    print("\n=== FIXING NAVIGATION MESH ===")
    
    # Wait for scene to load
    await get_tree().process_frame
    
    # Find all NavigationRegion3D nodes
    var nav_regions = []
    _find_all_navigation_regions(get_tree().current_scene, nav_regions)
    
    print("Found ", nav_regions.size(), " NavigationRegion3D nodes")
    
    if nav_regions.size() > 1:
        print("WARNING: Multiple NavigationRegion3D nodes found! This causes conflicts.")
        print("Disabling extra navigation regions...")
        
        # Keep only the first one active
        for i in range(1, nav_regions.size()):
            nav_regions[i].enabled = false
            print("  Disabled: ", nav_regions[i].get_path())
    
    # Check the main navigation region
    if nav_regions.size() > 0:
        var main_nav = nav_regions[0]
        print("\nMain NavigationRegion3D: ", main_nav.get_path())
        
        if main_nav.navigation_mesh:
            var nav_mesh = main_nav.navigation_mesh
            print("  Cell size: ", nav_mesh.cell_size)
            print("  Cell height: ", nav_mesh.cell_height)
            
            # Ensure cell size matches the global setting
            var default_cell_size = ProjectSettings.get_setting("navigation/3d/default_cell_size", 0.25)
            if abs(nav_mesh.cell_size - default_cell_size) > 0.001:
                print("  WARNING: Cell size mismatch! Nav mesh: ", nav_mesh.cell_size, " vs Default: ", default_cell_size)
                print("  Updating navigation mesh cell size to match...")
                nav_mesh.cell_size = default_cell_size
                nav_mesh.cell_height = default_cell_size
        else:
            print("  ERROR: No navigation mesh found!")
            print("  Creating a basic navigation mesh...")
            _create_basic_nav_mesh(main_nav)
    
    # Also check for the navigation region created by aurora_game_manager
    var created_nav = get_tree().get_first_node_in_group("navigation_region")
    if created_nav and created_nav not in nav_regions:
        print("\nFound programmatically created NavigationRegion3D - disabling it")
        created_nav.queue_free()
    
    print("=== NAVIGATION MESH FIX COMPLETE ===\n")

func _find_all_navigation_regions(node: Node, regions: Array):
    if node is NavigationRegion3D:
        regions.append(node)
    for child in node.get_children():
        _find_all_navigation_regions(child, regions)

func _create_basic_nav_mesh(nav_region: NavigationRegion3D):
    var nav_mesh = NavigationMesh.new()
    
    # Use default cell size from project settings
    var cell_size = ProjectSettings.get_setting("navigation/3d/default_cell_size", 0.25)
    nav_mesh.cell_size = cell_size
    nav_mesh.cell_height = cell_size
    
    # Basic settings for indoor navigation
    nav_mesh.agent_height = 2.0
    nav_mesh.agent_radius = 0.5
    nav_mesh.agent_max_climb = 0.3
    nav_mesh.agent_max_slope = 45.0
    
    # Set to parse static colliders
    nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
    nav_mesh.geometry_collision_mask = 1  # Environment layer
    
    nav_region.navigation_mesh = nav_mesh
    print("  Created basic navigation mesh - you should bake it in the editor!")