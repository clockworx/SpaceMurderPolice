extends StaticBody3D
class_name FurnitureCollision

# Simple furniture collision script that ensures NPCs don't walk through objects

func _ready():
	# Ensure we're on the environment collision layer
	collision_layer = 1  # Environment layer that NPCs collide with
	collision_mask = 0   # Furniture doesn't need to detect collisions
	
	# Check if we have collision shapes as children
	var has_collision = false
	for child in get_children():
		if child is CollisionShape3D:
			has_collision = true
			break
	
	if not has_collision:
		# Try to create a collision shape based on mesh
		_create_collision_from_mesh()

func _create_collision_from_mesh():
	# Look for a MeshInstance3D child
	var mesh_instance: MeshInstance3D = null
	for child in get_children():
		if child is MeshInstance3D:
			mesh_instance = child
			break
	
	if not mesh_instance or not mesh_instance.mesh:
		push_warning("FurnitureCollision: No mesh found to create collision from")
		return
	
	# Create a simple box collision shape based on mesh AABB
	var aabb = mesh_instance.mesh.get_aabb()
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	
	# Set box size to match mesh bounds
	box_shape.size = aabb.size
	collision_shape.shape = box_shape
	
	# Position collision shape at mesh center
	collision_shape.position = aabb.get_center()
	
	add_child(collision_shape)
	print("FurnitureCollision: Created collision shape for ", name)