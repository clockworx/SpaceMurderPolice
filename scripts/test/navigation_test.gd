extends Node3D

# Navigation Test Script - Tests if player can navigate through all rooms and floors

var test_points = [
	# Deck 1 test points
	{"name": "Docking Bay Center", "pos": Vector3(-15, 1, 15)},
	{"name": "Docking Bay Door", "pos": Vector3(-15, 1, 9)},
	{"name": "Corridor Outside Docking", "pos": Vector3(-15, 1, 5)},
	{"name": "Central Corridor", "pos": Vector3(0, 1, 0)},
	{"name": "Medical Bay Door", "pos": Vector3(-9, 1, 0)},
	{"name": "Medical Bay Center", "pos": Vector3(-15, 1, 0)},
	{"name": "Command Center Door", "pos": Vector3(9, 1, -15)},
	{"name": "Command Center", "pos": Vector3(15, 1, -15)},
	
	# Stairwell test points
	{"name": "Stairwell Entrance Deck 1", "pos": Vector3(0, 1, -3.5)},
	{"name": "Stairs Bottom", "pos": Vector3(0, 0.5, -2)},
	{"name": "Stairs Middle to Deck 2", "pos": Vector3(0, 2, 0)},
	{"name": "Platform Deck 2", "pos": Vector3(0, 4, 0)},
	
	# Deck 2 test points
	{"name": "Deck 2 Corridor", "pos": Vector3(0, 5, 0)},
	{"name": "Crew Quarters A Door", "pos": Vector3(-9, 5, 15)},
	{"name": "Crew Quarters A", "pos": Vector3(-15, 5, 15)},
	
	# Stairs to Deck 3
	{"name": "Stairs to Deck 3", "pos": Vector3(0, 6, 0)},
	{"name": "Deck 3 Floor", "pos": Vector3(0, 8.5, 0)},
	{"name": "Engineering Door", "pos": Vector3(-9, 9, 15)},
	{"name": "Main Engineering", "pos": Vector3(-15, 9, 15)}
]

var current_test = 0
var player: CharacterBody3D
var space_state: PhysicsDirectSpaceState3D
var test_results = []

func _ready():
	# Wait a frame for physics to initialize
	await get_tree().process_frame
	
	# Get player reference
	player = get_node("/root/SimpleStation/Player")
	if not player:
		push_error("Player not found!")
		return
		
	# Get physics space
	space_state = get_world_3d().direct_space_state
	
	# Start testing
	print("\n=== NAVIGATION TEST STARTED ===\n")
	run_navigation_tests()

func run_navigation_tests():
	for point in test_points:
		var result = test_navigation_to_point(point.name, point.pos)
		test_results.append(result)
		
	# Print summary
	print_test_summary()

func test_navigation_to_point(point_name: String, target_pos: Vector3) -> Dictionary:
	print("Testing: " + point_name + " at " + str(target_pos))
	
	var result = {
		"name": point_name,
		"position": target_pos,
		"floor_collision": false,
		"wall_collision": false,
		"can_reach": false,
		"details": ""
	}
	
	# Test 1: Check if there's floor at this position
	var floor_ray = PhysicsRayQueryParameters3D.create(
		target_pos + Vector3(0, 2, 0),  # Start above
		target_pos - Vector3(0, 1, 0)   # End below floor
	)
	var floor_hit = space_state.intersect_ray(floor_ray)
	
	if floor_hit:
		result.floor_collision = true
		print("  ✓ Floor found at Y=" + str(floor_hit.position.y))
	else:
		result.details = "No floor detected"
		print("  ✗ No floor found!")
		return result
	
	# Test 2: Check for walls blocking the path (simple line of sight)
	if current_test > 0:
		var prev_point = test_points[current_test - 1].pos
		var wall_ray = PhysicsRayQueryParameters3D.create(
			prev_point + Vector3(0, 0.5, 0),
			target_pos + Vector3(0, 0.5, 0)
		)
		var wall_hit = space_state.intersect_ray(wall_ray)
		
		if wall_hit and wall_hit.position.distance_to(target_pos) > 0.5:
			result.wall_collision = true
			result.details = "Wall blocking at " + str(wall_hit.position)
			print("  ✗ Wall blocking path at " + str(wall_hit.position))
		else:
			print("  ✓ Clear path from previous point")
	
	# Test 3: Check if position is inside a room (no collision at point)
	var space_check = PhysicsPointQueryParameters3D.new()
	space_check.position = target_pos
	space_check.collision_mask = 1  # Check collision layer 1
	var collisions = space_state.intersect_point(space_check, 1)
	
	if collisions.is_empty():
		result.can_reach = true
		print("  ✓ Position is accessible (no collisions)")
	else:
		result.details = "Position blocked by: " + str(collisions[0].collider)
		print("  ✗ Position blocked by collision")
	
	current_test += 1
	print("")
	return result

func print_test_summary():
	print("\n=== TEST SUMMARY ===\n")
	
	var passed = 0
	var failed = 0
	
	for result in test_results:
		if result.can_reach and result.floor_collision:
			passed += 1
			print("✓ " + result.name + " - ACCESSIBLE")
		else:
			failed += 1
			print("✗ " + result.name + " - BLOCKED: " + result.details)
	
	print("\nTotal: " + str(passed) + " passed, " + str(failed) + " failed")
	
	# Specific checks
	print("\n=== CRITICAL PATH CHECKS ===")
	
	# Check if player can exit spawn room
	var spawn_accessible = test_results[0].can_reach
	var door_accessible = test_results[1].can_reach
	var corridor_accessible = test_results[2].can_reach
	
	if spawn_accessible and corridor_accessible:
		print("✓ Player can exit Docking Bay")
	else:
		print("✗ Player CANNOT exit Docking Bay!")
		
	# Check stairwell access
	var stair_entrance = false
	var deck2_platform = false
	var deck3_access = false
	
	for result in test_results:
		if result.name == "Stairwell Entrance Deck 1" and result.can_reach:
			stair_entrance = true
		if result.name == "Platform Deck 2" and result.can_reach:
			deck2_platform = true
		if result.name == "Deck 3 Floor" and result.can_reach:
			deck3_access = true
			
	if stair_entrance and deck2_platform and deck3_access:
		print("✓ All floors accessible via stairs")
	else:
		print("✗ Stairwell navigation FAILED")
		if not stair_entrance:
			print("  - Cannot enter stairwell")
		if not deck2_platform:
			print("  - Cannot reach Deck 2")
		if not deck3_access:
			print("  - Cannot reach Deck 3")

# Visualize test points in editor
func _draw_debug():
	if Engine.is_editor_hint():
		for point in test_points:
			# Draw a sphere at each test point
			# This would need custom drawing implementation
			pass