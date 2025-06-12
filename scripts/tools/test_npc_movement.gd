@tool
extends EditorScript

func _run():
    print("=== Testing NPC Movement ===")
    
    # Get the currently open scene
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene is currently open!")
        return
    
    # Find NPCs node
    var npcs_node = edited_scene.find_child("NPCs", true, false)
    if not npcs_node:
        print("ERROR: No NPCs node found!")
        return
    
    # Create a simple test waypoint in the center
    var test_waypoint = Node3D.new()
    test_waypoint.name = "TestWaypoint"
    test_waypoint.position = Vector3(0, 0.2, 0)  # Center of the map at navmesh height
    edited_scene.add_child(test_waypoint)
    test_waypoint.owner = edited_scene
    
    # Add visual indicator
    var mesh = MeshInstance3D.new()
    var cylinder = CylinderMesh.new()
    cylinder.height = 2.0
    cylinder.top_radius = 0.5
    cylinder.bottom_radius = 0.5
    mesh.mesh = cylinder
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0, 1, 0, 1)
    material.emission_enabled = true
    material.emission = Color(0, 1, 0, 1)
    material.emission_energy = 0.5
    mesh.material_override = material
    
    test_waypoint.add_child(mesh)
    mesh.owner = edited_scene
    
    print("\nCreated test waypoint at (0, 0.2, 0)")
    print("\nTo test NPC movement:")
    print("1. Run the scene")
    print("2. NPCs should attempt to move to their waypoints")
    print("3. Check console for movement messages")
    print("\nIf NPCs are still stuck:")
    print("- Check that the navigation mesh covers the areas")
    print("- Ensure no obstacles block the paths")
    print("- Try moving NPCs to Y=0.2 (same as waypoints)")
    
    # Also update NPC heights to match waypoint height
    print("\nAdjusting NPC heights to Y=0.2...")
    for npc in npcs_node.get_children():
        if npc is Node3D:
            var old_pos = npc.position
            npc.position.y = 0.2
            print("  - Moved ", npc.name, " from Y=", old_pos.y, " to Y=0.2")
    
    print("\n✓ Test setup complete!")
