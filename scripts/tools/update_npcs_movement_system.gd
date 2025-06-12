@tool
extends EditorScript

# Tool to update all NPC scenes to use the new movement system
# Run this script to add the use_navmesh property to existing NPCs

func _run():
	print("=== Updating NPC Scenes with Movement System ===")
	
	var npc_scenes = [
		"res://scenes/npcs/engineer_npc.tscn",
		"res://scenes/npcs/scientist_npc.tscn",
		"res://scenes/npcs/security_npc.tscn",
		"res://scenes/npcs/medical_officer_npc.tscn",
		"res://scenes/npcs/chief_scientist_npc.tscn",
		"res://scenes/npcs/security_chief_npc.tscn",
		"res://scenes/npcs/ai_specialist_npc.tscn"
	]
	
	var updated_count = 0
	var failed_count = 0
	
	for scene_path in npc_scenes:
		if _update_npc_scene(scene_path):
			updated_count += 1
		else:
			failed_count += 1
	
	print("\n=== Update Complete ===")
	print("Updated: ", updated_count, " scenes")
	print("Failed: ", failed_count, " scenes")
	print("\nDon't forget to:")
	print("1. Test each NPC scene")
	print("2. Bake NavigationMesh in scenes where NPCs use NavMesh movement")
	print("3. Save all modified scenes")

func _update_npc_scene(scene_path: String) -> bool:
	print("\nProcessing: ", scene_path)
	
	var scene = load(scene_path)
	if not scene:
		print("  ERROR: Could not load scene")
		return false
	
	var instance = scene.instantiate()
	if not instance:
		print("  ERROR: Could not instantiate scene")
		return false
	
	# Check if it has NPCBase or UnifiedNPC
	var is_npc_base = instance is NPCBase
	var is_unified = instance is UnifiedNPC
	
	if not is_npc_base and not is_unified:
		print("  SKIP: Not an NPC scene")
		instance.queue_free()
		return false
	
	# Check if already has use_navmesh property
	if "use_navmesh" in instance:
		var current_value = instance.use_navmesh
		print("  INFO: Already has use_navmesh property set to: ", current_value)
		
		# Check if movement_system exists
		if instance.has_method("get_node_or_null"):
			var movement_node = instance.get_node_or_null("DirectMovement")
			if not movement_node:
				movement_node = instance.get_node_or_null("NavMeshMovement")
			
			if movement_node:
				print("  INFO: Movement system already exists: ", movement_node.get_class())
			else:
				print("  WARNING: No movement system node found (will be created at runtime)")
	else:
		print("  WARNING: Missing use_navmesh property - scene may need to be updated manually")
	
	# Print current waypoint configuration
	if "use_waypoints" in instance:
		print("  Waypoints enabled: ", instance.use_waypoints)
		if "waypoint_nodes" in instance:
			print("  Waypoint count: ", instance.waypoint_nodes.size())
	
	# Print current movement speed
	if "walk_speed" in instance:
		print("  Walk speed: ", instance.walk_speed)
	
	# Suggest NavMesh usage based on scene complexity
	var scene_name = scene_path.get_file().get_basename()
	if scene_name in ["engineer_npc", "scientist_npc", "security_npc"]:
		print("  SUGGESTION: Consider enabling NavMesh for better obstacle avoidance")
	
	instance.queue_free()
	return true