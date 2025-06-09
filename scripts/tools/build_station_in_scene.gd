@tool
extends EditorScript

# This tool script builds the complete station directly in the scene

func _run():
	print("Building complete station in scene...")
	
	var scene_root = get_scene()
	if not scene_root:
		push_error("No scene open!")
		return
	
	# Clear existing station nodes if any
	for child in scene_root.get_children():
		if child.name in ["Deck1_Operations", "Deck2_Living", "Deck3_Engineering", "CentralStairwell"]:
			child.queue_free()
	
	# Build the station
	var builder = preload("res://scripts/builders/complete_station_builder.gd").new()
	scene_root.add_child(builder)
	builder.build_complete_station()
	
	# Reparent all built nodes to scene root and remove builder
	for child in builder.get_children():
		builder.remove_child(child)
		scene_root.add_child(child)
		set_owner_recursive(child, scene_root)
	
	builder.queue_free()
	
	print("Station built! Save the scene to keep changes.")