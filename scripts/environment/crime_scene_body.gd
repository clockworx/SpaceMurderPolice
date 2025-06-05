extends StaticBody3D
class_name CrimeSceneBody

@export var victim_name: String = "Captain Diane Foster"
@export var cause_of_death: String = "Plasma cutter burns"
@export var time_of_death: String = "2387.11.15 - 02:47 Station Time"
@export var body_temperature: float = 24.3  # Celsius
@export var evidence_markers: Array[String] = [
    "Defensive wounds on hands",
    "Plasma burns on torso",
    "Torn uniform",
    "Missing security badge"
]

var examined: bool = false

func _ready():
    add_to_group("interactable")
    add_to_group("crime_scene")
    collision_layer = 2

func interact():
    if not examined:
        examined = true
        _reveal_evidence()
    
    _show_examination_details()

func get_interaction_prompt() -> String:
    if not examined:
        return "Press [E] to examine body"
    else:
        return "Press [E] to re-examine body"

func _reveal_evidence():
    # Notify evidence manager about examination
    var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    if evidence_manager and evidence_manager.has_method("add_clue"):
        evidence_manager.add_clue("body_examined", {
            "victim": victim_name,
            "cause": cause_of_death,
            "time": time_of_death,
            "temperature": body_temperature,
            "wounds": evidence_markers
        })
    else:
        push_warning("Crime Scene Body: Evidence manager not found or missing add_clue method")
        # Still show the examination details even if we can't record the clue
        print("Body examination clue would have been added: ", victim_name)

func _show_examination_details():
    # Create examination UI
    var exam_text = "Victim: " + victim_name + "\n"
    exam_text += "Cause of Death: " + cause_of_death + "\n"
    exam_text += "Time of Death: " + time_of_death + "\n"
    exam_text += "Body Temperature: " + str(body_temperature) + "°C\n\n"
    exam_text += "Notable Evidence:\n"
    
    for marker in evidence_markers:
        exam_text += "• " + marker + "\n"
    
    # Show notification
    _display_examination_popup(exam_text)

func _display_examination_popup(text: String):
    # Create popup
    var popup = AcceptDialog.new()
    popup.title = "Crime Scene Examination"
    popup.dialog_text = text
    popup.add_theme_font_size_override("font_size", 16)
    
    # Add to UI
    var ui_layer = get_tree().get_first_node_in_group("ui_layer")
    if not ui_layer:
        ui_layer = get_node("/root/" + get_tree().current_scene.name + "/Player/UILayer")
    
    if ui_layer:
        ui_layer.add_child(popup)
        popup.popup_centered(Vector2(500, 400))
        popup.confirmed.connect(popup.queue_free)
