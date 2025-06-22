@tool
extends EditorScript

# Tool script to add visualizer to all waypoints
# Run this from Script Editor: File -> Run

func _run():
	var scene_root = get_scene()
	if not scene_root:
		print("No scene open!")
		return
	
	# Find Waypoints node
	var waypoints_parent = scene_root.get_node_or_null("Waypoints")
	if not waypoints_parent:
		print("No Waypoints node found!")
		return
	
	# Load the visualizer script
	var visualizer_script = load("res://scripts/tools/waypoint_visualizer.gd")
	if not visualizer_script:
		print("Could not load waypoint_visualizer.gd!")
		return
	
	var updated_count = 0
	
	# Add visualizer to each waypoint
	for waypoint in waypoints_parent.get_children():
		if waypoint is Node3D:
			# Add the visualizer script
			waypoint.set_script(visualizer_script)
			
			# Set color based on type
			if waypoint.name.ends_with("_Center"):
				waypoint.set("waypoint_color", Color.BLUE)
				waypoint.set("waypoint_size", 0.4)
			elif waypoint.name.begins_with("Hallway_"):
				waypoint.set("waypoint_color", Color.YELLOW)
				waypoint.set("waypoint_size", 0.3)
			elif waypoint.name.begins_with("Corner_"):
				waypoint.set("waypoint_color", Color.ORANGE)
				waypoint.set("waypoint_size", 0.25)
			elif waypoint.name.begins_with("Nav_"):
				waypoint.set("waypoint_color", Color.CYAN)
				waypoint.set("waypoint_size", 0.25)
			else:
				waypoint.set("waypoint_color", Color.WHITE)
				waypoint.set("waypoint_size", 0.3)
			
			waypoint.set("show_label", true)
			
			# Ensure it updates in editor
			waypoint.notify_property_list_changed()
			
			updated_count += 1
			print("Updated waypoint: ", waypoint.name)
	
	print("\nUpdated ", updated_count, " waypoints with visualizer!")
	print("Color coding:")
	print("  - Blue: Room centers")
	print("  - Yellow: Hallway waypoints")
	print("  - Orange: Corner waypoints")
	print("  - Cyan: Navigation aids")
	
	# Mark scene as modified
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene_root)
	
	print("\nWaypoints now have visual meshes in the editor!")