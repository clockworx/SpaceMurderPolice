extends StaticBody3D
class_name EvidenceBase

@export_group("Evidence Properties")
@export var evidence_name: String = "Unknown Evidence"
@export var evidence_type: String = "Physical"
@export var description: String = "A piece of evidence"
@export var case_relevant: bool = true
@export var requires_analysis: bool = false

@export_group("Visual Properties")
@export var outline_color: Color = Color(1.0, 0.84, 0.0)  # Gold yellow
@export var outline_width: float = 0.05  # Proper outline width for grow

var evidence_id: String = ""  # Unique ID for story mode
var initial_position: Vector3
var collected: bool = false
var mesh_instance: MeshInstance3D
var original_material: Material

signal evidence_collected(evidence)

func _ready():
    collision_layer = 2  # Interactable layer
    collision_mask = 1   # Collide with environment
    
    # Add to evidence group
    add_to_group("evidence")
    add_to_group("interactable")
    
    initial_position = global_position
    print("Evidence '", evidence_name, "' ready at: ", global_position)
    
    # Find mesh instance
    mesh_instance = get_node_or_null("MeshInstance3D")
    if mesh_instance and mesh_instance.mesh:
        # Get the original material for outline effect
        var material = mesh_instance.get_surface_override_material(0)
        if not material:
            material = mesh_instance.mesh.surface_get_material(0)
        
        if material and material is StandardMaterial3D:
            original_material = material.duplicate() as StandardMaterial3D
            mesh_instance.set_surface_override_material(0, original_material)


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
        "collected_time": Time.get_unix_time_from_system()
    }

# Hover effects are now handled by UI, not on the mesh itself
func on_hover_start():
    pass

func on_hover_end():
    pass
