extends EvidenceBase
class_name PhysicalEvidence

@export_group("Physical Properties")
@export var weight: float = 0.1  # in kg
@export var material_type: String = "Unknown"
@export var has_fingerprints: bool = false
@export var has_dna: bool = false
@export var has_trace_elements: bool = false

func _ready():
	evidence_type = "Physical"
	super()

func get_evidence_data() -> Dictionary:
	var data = super()
	data["weight"] = weight
	data["material_type"] = material_type
	data["forensics"] = {
		"fingerprints": has_fingerprints,
		"dna": has_dna,
		"trace_elements": has_trace_elements
	}
	return data
