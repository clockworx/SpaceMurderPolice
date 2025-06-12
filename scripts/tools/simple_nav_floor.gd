@tool
extends EditorScript

func _run():
    print("=== Creating Simple Navigation Floor ===")
    
    # Get the currently open scene in the editor
    var editor_selection = get_editor_interface().get_selection()
    var edited_scene = get_editor_interface().get_edited_scene_root()
    
    if not edited_scene:
        print("ERROR: No scene is currently open in the editor!")
        print("Please open the NewStation scene and run this script again.")
        return
    
    print("Working with scene: ", edited_scene.name)
    
    # Find NavigationRegion3D
    var nav_region = edited_scene.find_child("NavigationRegion3D", true, false)
    if not nav_region:
        print("ERROR: No NavigationRegion3D found in the current scene!")
        return
    
    print("Found NavigationRegion3D")
    
    # Create a simple floor
    print("\nCreating navigation floor...")
    
    # Create CSGBox3D for the floor (CSG nodes automatically generate collision)
    var floor = CSGBox3D.new()
    floor.name = "NavigationFloor"
    floor.size = Vector3(200, 1, 200)
    floor.position = Vector3(0, -0.5, 0)
    floor.use_collision = true
    floor.collision_layer = 1
    floor.collision_mask = 0
    
    # Add to scene
    edited_scene.add_child(floor)
    floor.owner = edited_scene
    
    # Create a material for visibility
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.3, 0.3, 1.0)
    floor.material = material
    
    print("✓ Navigation floor created!")
    print("\nNow you can:")
    print("1. Select the NavigationRegion3D node")
    print("2. Click 'Bake NavigationMesh' in the toolbar")
    print("3. You should see a blue mesh overlay on the floor")
    print("\nNote: You can delete or hide the NavigationFloor node after baking if needed.")
