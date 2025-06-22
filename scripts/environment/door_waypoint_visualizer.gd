@tool
extends Node3D

# Simple script to show waypoint debug spheres in editor only
# Green sphere = Entry waypoint (approach side)
# Red sphere = Exit waypoint (departure side)
# If they appear flipped, adjust the waypoint positions or door rotation

func _ready():
    if Engine.is_editor_hint():
        # In editor, make debug spheres visible
        for child in get_children():
            if child.name == "DebugSphere" and child is MeshInstance3D:
                child.visible = true
    else:
        # In game, hide debug spheres
        for child in get_children():
            if child.name == "DebugSphere" and child is MeshInstance3D:
                child.visible = false