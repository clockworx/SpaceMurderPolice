extends StaticBody3D
class_name BodyExamination

@export var victim_name: String = "Dr. Elena Vasquez"
@export var examination_duration: float = 3.0

var is_examined: bool = false
var examination_data: Dictionary = {}

signal examination_complete(data: Dictionary)

func _ready():
    add_to_group("interactable")
    collision_layer = 2
    _setup_examination_data()

func _setup_examination_data():
    examination_data = {
        "victim_name": victim_name,
        "initial_observations": [
            "Victim appears to be Dr. Elena Vasquez, 34 years old",
            "Body found in Laboratory 3 near research equipment",
            "No obvious signs of struggle or defensive wounds",
            "Severe electrical burns on torso and hands"
        ],
        "detailed_findings": [
            "Cause of death: High-voltage electrical trauma",
            "Burns consistent with industrial plasma cutter contact",
            "Victim was likely unconscious when fatal injury occurred",
            "Time of death: Approximately 18:30 station time",
            "No foreign DNA or fingerprints found on victim",
            "Victim's research notes were found scattered nearby"
        ],
        "conclusions": [
            "Death appears accidental but circumstances are suspicious",
            "Plasma cutter safety protocols were bypassed",
            "Recommend investigation of equipment maintenance records",
            "Victim may have been working alone when incident occurred"
        ],
        "medical_history": {
            "age": 34,
            "health_status": "Excellent physical condition",
            "medications": "None",
            "allergies": "None on record",
            "next_of_kin": "Parents on Earth Colony Beta"
        }
    }

func interact():
    if is_examined:
        print("You have already examined the body thoroughly.")
        _show_examination_summary()
        return
    
    print("Beginning examination of " + victim_name + "...")
    _start_examination()

func _start_examination():
    # Create examination UI
    var examination_ui = preload("res://scenes/ui/examination_ui.tscn")
    if examination_ui:
        var ui_instance = examination_ui.instantiate()
        get_tree().root.add_child(ui_instance)
        ui_instance.start_examination(examination_data, examination_duration)
        ui_instance.examination_finished.connect(_on_examination_finished)
    else:
        # Fallback if no UI scene exists
        print("Conducting detailed examination...")
        await get_tree().create_timer(examination_duration).timeout
        _on_examination_finished()

func _on_examination_finished():
    is_examined = true
    print("Examination complete. Autopsy findings added to case files.")
    
    # Add findings to evidence or case file system
    var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    if evidence_manager:
        var autopsy_evidence = {
            "name": "Autopsy Report - " + victim_name,
            "type": "document",
            "description": "Complete medical examination findings",
            "details": examination_data,
            "timestamp": Time.get_unix_time_from_system()
        }
        evidence_manager.add_clue("autopsy_report_" + victim_name, autopsy_evidence)
    
    examination_complete.emit(examination_data)

func _show_examination_summary():
    print("\n=== EXAMINATION SUMMARY ===")
    print("Victim: " + examination_data.victim_name)
    print("\nKey Findings:")
    for finding in examination_data.detailed_findings:
        print("• " + finding)

func get_interaction_prompt() -> String:
    if is_examined:
        return "Press [E] to review examination findings"
    else:
        return "Press [E] to examine body"

func on_hover_start():
    pass

func on_hover_end():
    pass
