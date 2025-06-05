extends EvidenceBase
class_name DigitalEvidence

@export_group("Digital Properties")
@export var device_type: String = "Data Pad"
@export var encrypted: bool = false
@export var corrupted: bool = false
@export var access_logs: Array[String] = []
@export var file_count: int = 0

func _ready():
	evidence_type = "Digital"
	super()

func get_evidence_data() -> Dictionary:
	var data = super()
	data["device_type"] = device_type
	data["encrypted"] = encrypted
	data["corrupted"] = corrupted
	data["access_logs"] = access_logs
	data["file_count"] = file_count
	return data