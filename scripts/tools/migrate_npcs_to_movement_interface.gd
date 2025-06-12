@tool
extends EditorScript

# Migration utility for updating NPCs to use the movement interface system
# This tool helps bulk-update NPCs to enable NavMesh movement

const NPC_SCENE_PATHS = [
	"res://scenes/npcs/",
	"res://scenes/levels/"
]

const BACKUP_SUFFIX = ".backup"

var migrated_npcs: Array[Dictionary] = []
var backup_created: bool = false

func _run():
	print("\n========== NPC Movement System Migration Tool ==========")
	print("This tool will help migrate NPCs to use the movement interface.")
	print("1. Scan for NPCs")
	print("2. Enable NavMesh on all NPCs")
	print("3. Enable NavMesh on specific NPCs")
	print("4. Test movement systems")
	print("5. Rollback changes")
	print("6. Exit")
	
	# For automated batch processing, uncomment desired action:
	# scan_for_npcs()
	# enable_navmesh_on_all()
	# test_movement_systems()
	
	# Manual interactive mode
	scan_for_npcs()

func scan_for_npcs() -> Array[String]:
	print("\nScanning for NPC scenes...")
	var npc_files: Array[String] = []
	
	for path in NPC_SCENE_PATHS:
		_scan_directory(path, npc_files)
	
	print("Found " + str(npc_files.size()) + " potential NPC files:")
	for file in npc_files:
		print("  - " + file)
	
	return npc_files

func _scan_directory(path: String, files: Array[String]):
	var dir = DirAccess.open(path)
	if not dir:
		print("Failed to open directory: " + path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory(full_path, files)
		elif file_name.ends_with(".tscn") and _is_npc_scene(full_path):
			files.append(full_path)
		
		file_name = dir.get_next()

func _is_npc_scene(path: String) -> bool:
	# Check if scene contains NPC nodes
	var scene = load(path) as PackedScene
	if not scene:
		return false
	
	var instance = scene.instantiate()
	if not instance:
		return false
	
	var is_npc = instance is NPCBase or instance is UnifiedNPC or instance.has_method("interact")
	
	# Also check for NPC in filename
	var filename_check = path.to_lower().contains("npc") or path.to_lower().contains("character")
	
	instance.queue_free()
	
	return is_npc or filename_check

func enable_navmesh_on_all():
	print("\nEnabling NavMesh movement on all NPCs...")
	var npc_files = scan_for_npcs()
	
	for file in npc_files:
		_enable_navmesh_on_npc(file)
	
	print("\nMigration complete!")
	print("Migrated " + str(migrated_npcs.size()) + " NPCs")
	_save_migration_report()

func enable_navmesh_on_specific(npc_names: Array[String]):
	print("\nEnabling NavMesh movement on specific NPCs...")
	var npc_files = scan_for_npcs()
	
	for file in npc_files:
		for npc_name in npc_names:
			if file.to_lower().contains(npc_name.to_lower()):
				_enable_navmesh_on_npc(file)
				break

func _enable_navmesh_on_npc(scene_path: String) -> bool:
	print("\nProcessing: " + scene_path)
	
	# Create backup
	if not backup_created:
		_create_backup(scene_path)
	
	# Load scene
	var scene = load(scene_path) as PackedScene
	if not scene:
		print("  ERROR: Failed to load scene")
		return false
	
	var instance = scene.instantiate()
	if not instance:
		print("  ERROR: Failed to instantiate scene")
		return false
	
	# Check if it's an NPC
	var npc = instance as NPCBase
	if not npc and instance.has_method("get"):
		npc = instance
	
	if not npc:
		print("  SKIP: Not an NPC scene")
		instance.queue_free()
		return false
	
	# Update properties
	var old_value = npc.get("use_navmesh") if npc.has_method("get") else false
	
	if npc.has_method("set"):
		npc.set("use_navmesh", true)
		
		# Record migration
		migrated_npcs.append({
			"path": scene_path,
			"name": npc.get("npc_name") if npc.has_method("get") else "Unknown",
			"old_navmesh": old_value,
			"new_navmesh": true
		})
		
		print("  SUCCESS: Enabled NavMesh movement")
		
		# Save the modified scene
		var packed = PackedScene.new()
		packed.pack(instance)
		ResourceSaver.save(packed, scene_path)
	else:
		print("  SKIP: NPC doesn't support use_navmesh property")
	
	instance.queue_free()
	return true

func test_movement_systems():
	print("\nTesting movement systems...")
	
	# Create test scene
	var test_scene = preload("res://scenes/test/movement_test.tscn")
	if not test_scene:
		print("ERROR: Test scene not found. Please ensure movement_test.tscn exists.")
		return
	
	print("Test scene loaded. Please run the scene to test movement systems.")
	print("Controls:")
	print("  SPACE - Toggle between Direct and NavMesh movement")
	print("  N - Move to next waypoint")
	print("  R - Reset to start")

func rollback_changes():
	print("\nRolling back changes...")
	
	for migration in migrated_npcs:
		var backup_path = migration.path + BACKUP_SUFFIX
		
		if FileAccess.file_exists(backup_path):
			# Copy backup over original
			var dir = DirAccess.open("res://")
			dir.copy(backup_path, migration.path)
			print("  Restored: " + migration.path)
			
			# Remove backup
			dir.remove(backup_path)
		else:
			print("  WARNING: No backup found for " + migration.path)
	
	migrated_npcs.clear()
	print("Rollback complete!")

func _create_backup(scene_path: String):
	var backup_path = scene_path + BACKUP_SUFFIX
	
	if not FileAccess.file_exists(backup_path):
		var dir = DirAccess.open("res://")
		dir.copy(scene_path, backup_path)
		print("  Created backup: " + backup_path)
		backup_created = true

func _save_migration_report():
	var report = "NPC Movement System Migration Report\n"
	report += "====================================\n"
	report += "Date: " + Time.get_datetime_string_from_system() + "\n\n"
	
	report += "Migrated NPCs:\n"
	for migration in migrated_npcs:
		report += "- " + migration.name + " (" + migration.path + ")\n"
		report += "  NavMesh: " + str(migration.old_navmesh) + " -> " + str(migration.new_navmesh) + "\n"
	
	var file = FileAccess.open("res://migration_report.txt", FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("\nMigration report saved to: res://migration_report.txt")

# Batch processing functions
func batch_enable_navmesh_for_saboteurs():
	print("\nEnabling NavMesh for all saboteur-capable NPCs...")
	var npc_files = scan_for_npcs()
	
	for file in npc_files:
		var scene = load(file) as PackedScene
		if not scene:
			continue
		
		var instance = scene.instantiate()
		if instance and instance.has_method("get"):
			var can_be_saboteur = instance.get("can_be_saboteur")
			if can_be_saboteur:
				_enable_navmesh_on_npc(file)
		
		if instance:
			instance.queue_free()

func batch_enable_navmesh_by_role(role: String):
	print("\nEnabling NavMesh for NPCs with role: " + role)
	var npc_files = scan_for_npcs()
	
	for file in npc_files:
		var scene = load(file) as PackedScene
		if not scene:
			continue
		
		var instance = scene.instantiate()
		if instance and instance.has_method("get"):
			var npc_role = instance.get("role")
			if npc_role and npc_role.to_lower().contains(role.to_lower()):
				_enable_navmesh_on_npc(file)
		
		if instance:
			instance.queue_free()

# Validation functions
func validate_movement_systems():
	print("\nValidating movement systems...")
	var npc_files = scan_for_npcs()
	var validation_results = []
	
	for file in npc_files:
		var scene = load(file) as PackedScene
		if not scene:
			continue
		
		var instance = scene.instantiate()
		if instance and instance.has_method("get"):
			var use_navmesh = instance.get("use_navmesh")
			var has_waypoints = instance.get("use_waypoints") and instance.get("waypoint_nodes").size() > 0
			
			validation_results.append({
				"path": file,
				"name": instance.get("npc_name") if instance.has_method("get") else "Unknown",
				"navmesh_enabled": use_navmesh,
				"has_waypoints": has_waypoints,
				"status": "OK" if (use_navmesh or not has_waypoints) else "NEEDS_NAVMESH"
			})
		
		if instance:
			instance.queue_free()
	
	print("\nValidation Results:")
	for result in validation_results:
		print(result.name + ": " + result.status)
		if result.status != "OK":
			print("  - NavMesh: " + str(result.navmesh_enabled))
			print("  - Waypoints: " + str(result.has_waypoints))