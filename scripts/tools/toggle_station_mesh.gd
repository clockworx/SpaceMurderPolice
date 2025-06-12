@tool
extends EditorScript

func _run():
    print("=== Toggle Station Mesh Visibility ===")
    
    var edited_scene = get_editor_interface().get_edited_scene_root()
    if not edited_scene:
        print("ERROR: No scene open!")
        return
    
    # Find the original Station mesh
    var station_mesh = edited_scene.find_child("Station", true, false)
    if station_mesh:
        station_mesh.visible = !station_mesh.visible
        print("Station mesh visibility: ", station_mesh.visible)
        
        # Also toggle collision if it's a StaticBody3D
        if station_mesh is StaticBody3D:
            for child in station_mesh.get_children():
                if child is CollisionShape3D:
                    child.disabled = !station_mesh.visible
                    print("Station collision: ", !child.disabled)
    else:
        print("ERROR: Station mesh not found!")
    
    # Find CSGStation
    var csg_station = edited_scene.find_child("CSGStation", true, false)
    if csg_station:
        print("CSGStation visibility: ", csg_station.visible)
    
    print("\nTip: Run this script to toggle between OBJ and CSG station")
