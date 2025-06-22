extends Node
class_name EvidenceManager

var collected_evidence: Array[Dictionary] = []
var total_evidence_count: int = 0
var case_relevant_count: int = 0

signal evidence_collected(evidence_data)
signal all_evidence_collected()
signal evidence_spawned(count)

func _ready():
    add_to_group("evidence_manager")
    # Wait longer for spawn manager to create evidence
    await get_tree().create_timer(0.5).timeout
    _connect_evidence_nodes()
    
    # Also listen for spawn manager's signal
    var spawn_manager = get_tree().get_first_node_in_group("evidence_spawn_manager")
    if spawn_manager and spawn_manager.has_signal("evidence_spawned"):
        spawn_manager.evidence_spawned.connect(_on_evidence_spawned)

func _connect_evidence_nodes():
    # Find all EvidenceBase nodes in the scene
    var all_nodes = get_tree().get_nodes_in_group("evidence")
    
    # If no nodes in group, search for EvidenceBase instances
    if all_nodes.is_empty():
        _find_evidence_recursive(get_tree().root)
    else:
        for evidence in all_nodes:
            if evidence.has_signal("evidence_collected") and not evidence.evidence_collected.is_connected(_on_evidence_collected):
                evidence.evidence_collected.connect(_on_evidence_collected)
                total_evidence_count += 1
    
    print("Evidence Manager: Found ", total_evidence_count, " evidence items")
    
    # Emit signal so other systems know the count
    if total_evidence_count > 0:
        evidence_spawned.emit(total_evidence_count)

func _find_evidence_recursive(node: Node):
    if node.get_class() == "StaticBody3D" and node.has_method("get_evidence_data"):
        if node.has_signal("evidence_collected") and not node.evidence_collected.is_connected(_on_evidence_collected):
            node.evidence_collected.connect(_on_evidence_collected)
            total_evidence_count += 1
            node.add_to_group("evidence")
    
    for child in node.get_children():
        _find_evidence_recursive(child)

func _on_evidence_collected(evidence):
    var data = evidence.get_evidence_data()
    collected_evidence.append(data)
    
    if data.case_relevant:
        case_relevant_count += 1
    
    evidence_collected.emit(data)
    
    print("Evidence collected: ", data.name)
    print("Total collected: ", collected_evidence.size(), "/", total_evidence_count)
    
    if collected_evidence.size() >= total_evidence_count:
        all_evidence_collected.emit()

func get_collected_evidence() -> Array[Dictionary]:
    return collected_evidence

func get_evidence_by_name(evidence_name: String) -> Dictionary:
    for evidence in collected_evidence:
        if evidence.name == evidence_name:
            return evidence
    return {}

func get_evidence_by_type(type: String) -> Array[Dictionary]:
    var filtered = []
    for evidence in collected_evidence:
        if evidence.type == type:
            filtered.append(evidence)
    return filtered

func has_evidence(evidence_name: String) -> bool:
    return get_evidence_by_name(evidence_name).size() > 0

func get_collection_progress() -> float:
    if total_evidence_count == 0:
        return 0.0
    return float(collected_evidence.size()) / float(total_evidence_count)

func get_total_evidence_count() -> int:
    return total_evidence_count

func _on_evidence_spawned(count: int):
    print("Evidence Manager: Spawn manager created ", count, " evidence items")
    total_evidence_count = count

func add_clue(clue_id: String, clue_data: Dictionary):
    # Add a clue that isn't a physical evidence item
    var clue = {
        "name": clue_data.get("name", clue_id),
        "type": clue_data.get("type", "clue"),
        "description": clue_data.get("description", ""),
        "details": clue_data.get("details", {}),
        "case_relevant": true,
        "collected_time": Time.get_ticks_msec()
    }
    collected_evidence.append(clue)
    evidence_collected.emit(clue)
    print("Clue added: ", clue_data.get("name", clue_id))
