extends StaticBody3D
class_name PhysicalEvidence

@export_group("Evidence Properties")
@export var evidence_name: String = "Unknown Evidence"
@export var evidence_type: String = "Physical"
@export var description: String = "A piece of evidence"
@export var case_relevant: bool = true
@export var requires_analysis: bool = false

@export_group("Physical Properties")
@export var weight: float = 0.1  # in kg
@export var material_type: String = "Unknown"
@export var has_fingerprints: bool = false
@export var has_dna: bool = false
@export var has_trace_elements: bool = false

@export_group("Visual Properties")
@export var hover_amplitude: float = 0.1
@export var hover_speed: float = 2.0
@export var rotation_speed: float = 1.0
@export var emission_color: Color = Color(0.5, 0.8, 1.0)
@export var emission_strength: float = 2.0

var initial_position: Vector3
var time_elapsed: float = 0.0
var collected: bool = false
var mesh_instance: MeshInstance3D
var original_material: Material

signal evidence_collected(evidence)

func _ready():
	add_to_group("evidence")
	collision_layer = 2  # Interactable layer
	collision_mask = 1   # Collide with environment
	
	initial_position = position
	
	# Find mesh instance
	mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.mesh:
		# Create emissive material override
		var material = mesh_instance.get_surface_override_material(0)
		if not material:
			material = mesh_instance.mesh.surface_get_material(0)
		
		if material and material is StandardMaterial3D:
			original_material = material
			var new_material = material.duplicate() as StandardMaterial3D
			new_material.emission_enabled = true
			new_material.emission = emission_color
			new_material.emission_energy_multiplier = emission_strength
			mesh_instance.set_surface_override_material(0, new_material)

func _physics_process(delta):
	if collected:
		return
		
	time_elapsed += delta
	
	# Hover animation
	position.y = initial_position.y + sin(time_elapsed * hover_speed) * hover_amplitude
	
	# Rotation animation
	if mesh_instance:
		mesh_instance.rotate_y(rotation_speed * delta)

func interact():
	if collected:
		return
		
	collected = true
	evidence_collected.emit(self)
	
	# Play collection animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
	tween.tween_property(self, "position:y", position.y + 1.0, 0.3)
	tween.chain().tween_callback(queue_free)
	
	print("Collected evidence: ", evidence_name)

func get_interaction_prompt() -> String:
	return "Press [E] to collect " + evidence_name

func get_evidence_data() -> Dictionary:
	return {
		"name": evidence_name,
		"type": evidence_type,
		"description": description,
		"case_relevant": case_relevant,
		"requires_analysis": requires_analysis,
		"collected_time": Time.get_unix_time_from_system(),
		"weight": weight,
		"material_type": material_type,
		"forensics": {
			"fingerprints": has_fingerprints,
			"dna": has_dna,
			"trace_elements": has_trace_elements
		}
	}
