extends Node
class_name NavigationMapFixer

# Fixes navigation map cell size mismatch

func _ready():
	print("\n=== Navigation Map Fixer ===")
	
	# Wait for navigation to be ready
	await get_tree().process_frame
	
	# Get all navigation maps
	var maps = NavigationServer3D.get_maps()
	print("Found ", maps.size(), " navigation maps")
	
	for map in maps:
		# Get current settings
		var current_cell_size = NavigationServer3D.map_get_cell_size(map)
		var current_cell_height = NavigationServer3D.map_get_cell_height(map)
		
		print("\nMap ", map, ":")
		print("  Current cell_size: ", current_cell_size)
		print("  Current cell_height: ", current_cell_height)
		
		# Fix the cell size to match NavigationMesh
		NavigationServer3D.map_set_cell_size(map, 0.1)
		NavigationServer3D.map_set_cell_height(map, 0.05)
		
		print("  Fixed cell_size to: 0.1")
		print("  Fixed cell_height to: 0.05")
		
		# Force update
		NavigationServer3D.map_force_update(map)
	
	# Also set project settings for future maps
	ProjectSettings.set_setting("navigation/3d/default_cell_size", 0.1)
	ProjectSettings.set_setting("navigation/3d/default_cell_height", 0.05)
	
	print("\nProject settings updated for future navigation maps")
	print("Navigation map cell sizes fixed!")
	print("=== End Navigation Map Fixer ===\n")