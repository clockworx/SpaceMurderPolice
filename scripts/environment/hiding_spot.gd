extends StaticBody3D
class_name HidingSpot

@export_group("Hiding Properties")
@export var hiding_type: String = "locker"  # locker, vent, desk, crate
@export var can_move_while_hidden: bool = false  # True for vents
@export var visibility_reduction: float = 0.95  # How much it reduces visibility
@export var noise_when_entering: float = 5.0  # Detection radius when entering
@export var noise_when_exiting: float = 3.0  # Detection radius when exiting

@export_group("Interaction")
@export var interaction_distance: float = 2.0
@export var entry_time: float = 1.0  # Time to enter/exit

var player_hidden: bool = false
var player_inside: Node3D = null
var original_player_position: Vector3
var hide_position: Vector3
var mesh_instance: MeshInstance3D
var original_mesh_material: Material

signal player_entered(player)
signal player_exited(player)

func _ready():
	add_to_group("interactable")
	add_to_group("hiding_spots")
	collision_layer = 2  # Interactable layer
	
	# Calculate hide position based on type
	_setup_hide_position()
	
	# Find mesh for visual feedback
	mesh_instance = find_child("*Mesh*", true, false) as MeshInstance3D
	if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
		original_mesh_material = mesh_instance.get_surface_override_material(0)

func _setup_hide_position():
	match hiding_type:
		"locker":
			hide_position = global_position + transform.basis.z * 0.3
		"vent":
			# For ceiling vents, position player inside but lower
			hide_position = global_position - Vector3(0, 0.3, 0)
		"desk":
			# Under desk - lower and slightly forward
			hide_position = global_position + Vector3(0, -0.7, 0.3)
		"crate":
			hide_position = global_position + transform.basis.z * 0.2
		_:
			hide_position = global_position

func interact():
	if player_hidden and player_inside:
		_exit_hiding()
	else:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			_enter_hiding(player)

func get_interaction_prompt() -> String:
	if player_hidden:
		return "Press [E] to exit " + hiding_type
	else:
		return "Press [E] to hide in " + hiding_type

func _enter_hiding(player: Node3D):
	# Check if Riley is too close
	var riley = get_tree().get_first_node_in_group("riley_patrol")
	if riley:
		# Riley patrol AI is a child of the NPC, get the parent's position
		var riley_npc = riley.get_parent() if riley.get_parent() else null
		if riley_npc and riley_npc is Node3D:
			var distance_to_riley = global_position.distance_to(riley_npc.global_position)
			if distance_to_riley < noise_when_entering:
				# Riley will hear you entering
				if riley.has_method("investigate_position"):
					riley.investigate_position(global_position)
	
	# Hide player
	player_inside = player
	player_hidden = true
	original_player_position = player.global_position
	
	# Disable player controls and visibility
	if player.has_method("set_hidden_state"):
		player.set_hidden_state(true, self)
	
	# Move player to hide position
	player.global_position = hide_position
	
	# Make player less visible
	if player.has_node("Head/Camera3D"):
		var camera = player.get_node("Head/Camera3D")
		camera.fov = 60  # Reduced FOV while hiding
	
	# Visual feedback
	_show_hidden_feedback()
	
	player_entered.emit(player)
	print("Player hidden in " + hiding_type)

func _exit_hiding():
	if not player_inside:
		return
	
	# Check if Riley is too close
	var riley = get_tree().get_first_node_in_group("riley_patrol")
	if riley:
		# Riley patrol AI is a child of the NPC, get the parent's position
		var riley_npc = riley.get_parent() if riley.get_parent() else null
		if riley_npc and riley_npc is Node3D:
			var distance_to_riley = global_position.distance_to(riley_npc.global_position)
			if distance_to_riley < noise_when_exiting:
				# Riley will hear you exiting
				if riley.has_method("investigate_position"):
					riley.investigate_position(global_position)
	
	# Restore player
	if player_inside.has_method("set_hidden_state"):
		player_inside.set_hidden_state(false)
	
	# Move player back out
	player_inside.global_position = original_player_position
	
	# Restore camera
	if player_inside.has_node("Head/Camera3D"):
		var camera = player_inside.get_node("Head/Camera3D")
		camera.fov = 75  # Normal FOV
	
	# Remove visual feedback
	_hide_hidden_feedback()
	
	player_exited.emit(player_inside)
	print("Player exited " + hiding_type)
	
	player_hidden = false
	player_inside = null

func _show_hidden_feedback():
	if mesh_instance:
		var material = mesh_instance.get_surface_override_material(0)
		if material and material is StandardMaterial3D:
			var new_material = material.duplicate()
			new_material.emission_enabled = true
			new_material.emission = Color(0, 0.3, 0)
			new_material.emission_energy_multiplier = 0.3
			mesh_instance.set_surface_override_material(0, new_material)

func _hide_hidden_feedback():
	if mesh_instance and original_mesh_material:
		mesh_instance.set_surface_override_material(0, original_mesh_material)

func is_player_hidden() -> bool:
	return player_hidden

func get_visibility_multiplier() -> float:
	if player_hidden:
		return 1.0 - visibility_reduction
	return 1.0

# Called by detection systems to check if player should be detected
func should_detect_player() -> bool:
	if not player_hidden:
		return true
	
	# Apply visibility reduction
	var detection_chance = 1.0 - visibility_reduction
	return randf() < detection_chance