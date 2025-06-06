extends StaticBody3D
class_name ComputerTerminal

@export var terminal_id: String = "general_terminal"
@export var terminal_name: String = "Station Terminal"
@export var requires_keycard: bool = false
@export var required_keycard_type: String = ""
@export var is_night_cycle_only: bool = false

var terminal_data: Dictionary = {}
var is_accessed: bool = false
var is_enabled: bool = true
var original_screen_material: Material
var screen_mesh: MeshInstance3D

signal terminal_accessed(terminal_id: String, data: Dictionary)

func _ready():
    add_to_group("interactable")
    add_to_group("computer_terminal")
    collision_layer = 2
    
    # Find screen mesh for visual feedback
    screen_mesh = get_node_or_null("Screen")
    if screen_mesh and screen_mesh.mesh and screen_mesh.mesh.surface_get_material(0):
        original_screen_material = screen_mesh.mesh.surface_get_material(0)
    
    _load_terminal_data()

func _load_terminal_data():
    # Load terminal content based on terminal_id
    match terminal_id:
        "security_main":
            terminal_data = {
                "name": "Security Main Terminal",
                "logs": [
                    {
                        "timestamp": "2387.03.15 14:22",
                        "author": "Jake Torres",
                        "title": "Security Log #1247",
                        "content": "Routine patrol complete. Dr. Vasquez working late in Lab 3 again. That woman never sleeps."
                    },
                    {
                        "timestamp": "2387.03.15 18:45", 
                        "author": "Jake Torres",
                        "title": "Evening Report",
                        "content": "Found Lab 3 door ajar at 18:30. Dr. Vasquez not responding to comms. Investigating."
                    },
                    {
                        "timestamp": "2387.03.15 19:15",
                        "author": "System",
                        "title": "Emergency Alert",
                        "content": "MEDICAL EMERGENCY - LAB 3. Dr. Sarah Chen responding. Security lockdown initiated."
                    }
                ],
                "files": [
                    {
                        "title": "Access Logs - Last 24 Hours",
                        "content": "Lab 3 Access:\n14:20 - Dr. Vasquez (Entry)\n16:45 - Riley Kim (Entry/Exit)\n18:15 - Riley Kim (Entry/Exit)\n18:30 - Dr. Vasquez (Emergency Exit - Door Left Open)"
                    }
                ]
            }
        
        "medical_records":
            terminal_data = {
                "name": "Medical Records Terminal",
                "logs": [
                    {
                        "timestamp": "2387.03.15 19:45",
                        "author": "Dr. Sarah Chen",
                        "title": "Autopsy Preliminary",
                        "content": "Victim: Dr. Elena Vasquez. Cause of death: Electrical trauma consistent with high-voltage equipment. Investigating equipment in Lab 3."
                    },
                    {
                        "timestamp": "2387.03.15 20:30",
                        "author": "Dr. Sarah Chen", 
                        "title": "Autopsy Update",
                        "content": "Burns indicate close contact with plasma cutter. No signs of struggle. Victim may have been unconscious when injury occurred."
                    }
                ],
                "files": [
                    {
                        "title": "Dr. Vasquez Medical Record",
                        "content": "Elena Vasquez, Age 34\nSpecialty: Xenobiology Research\nHealth Status: Excellent\nRecent Issues: Reported stress due to research deadlines\nNext of Kin: Parents on Earth Colony Beta"
                    }
                ]
            }
        
        "lab3_research":
            terminal_data = {
                "name": "Lab 3 Research Terminal",
                "logs": [
                    {
                        "timestamp": "2387.03.15 14:15",
                        "author": "Dr. Elena Vasquez",
                        "title": "Research Notes Day 127",
                        "content": "Breakthrough with the xenobiological samples! The protein structures are unlike anything we've seen. This could revolutionize medicine."
                    },
                    {
                        "timestamp": "2387.03.15 16:30",
                        "author": "Dr. Elena Vasquez",
                        "title": "Personal Log",
                        "content": "Someone's been in my lab again. Equipment moved, files accessed. Riley says it's routine maintenance but something feels off."
                    },
                    {
                        "timestamp": "2387.03.15 18:00",
                        "author": "Dr. Elena Vasquez",
                        "title": "URGENT - Data Backup",
                        "content": "Backing up all research data. If something happens to me, make sure this research reaches Earth. Too important to lose."
                    }
                ],
                "files": [
                    {
                        "title": "Project Xenobio-7 Summary",
                        "content": "Classification: TOP SECRET\nLead Researcher: Dr. Elena Vasquez\nFunding: 50M Credits (Corporate Sponsor: Helix Dynamics)\nPotential Value: 500M+ Credits\nStatus: 78% Complete"
                    }
                ]
            }
        
        "engineering_diagnostics":
            terminal_data = {
                "name": "Engineering Diagnostics",
                "logs": [
                    {
                        "timestamp": "2387.03.15 16:45",
                        "author": "Riley Kim",
                        "title": "Equipment Maintenance - Lab 3",
                        "content": "Plasma cutter calibration complete. All safety protocols verified. Equipment operating within normal parameters."
                    },
                    {
                        "timestamp": "2387.03.15 18:15",
                        "author": "Riley Kim",
                        "title": "Emergency Power Check",
                        "content": "Routine inspection of backup power systems. Lab 3 plasma cutter shows minor fluctuation in voltage regulator. Scheduling repair."
                    }
                ],
                "files": [
                    {
                        "title": "Plasma Cutter Safety Log",
                        "content": "Model: HC-2500 Industrial Plasma Cutter\nLast Safety Check: 2387.03.15 16:45\nTechnician: Riley Kim\nStatus: Minor voltage irregularity detected\nAction Required: Voltage regulator replacement"
                    }
                ]
            }
        
        "riley_personal":
            terminal_data = {
                "name": "Personal Terminal - R. Kim",
                "requires_night": true,
                "logs": [
                    {
                        "timestamp": "2387.03.12 23:45",
                        "author": "Riley Kim",
                        "title": "Personal Log",
                        "content": "The debts are getting worse. Mom's medical bills on Earth are crushing me. Corporate says they might have work for me, but it doesn't feel right."
                    },
                    {
                        "timestamp": "2387.03.14 02:30",
                        "author": "Riley Kim",
                        "title": "Decision",
                        "content": "Met with the corporate contact. They want Elena's research data. Said they'd pay enough to cover everything. Just need to... delay her progress. Nothing permanent."
                    },
                    {
                        "timestamp": "2387.03.15 17:00",
                        "author": "Riley Kim",
                        "title": "What Have I Done",
                        "content": "It wasn't supposed to happen like this. The plasma cutter malfunction - Elena was right there when it happened. I just wanted to corrupt her data files, not... God, what have I done?"
                    }
                ],
                "files": [
                    {
                        "title": "Medical Bills - Earth Colony Beta",
                        "content": "Patient: Sarah Kim (Mother)\nCondition: Chronic Neurological Disorder\nTreatment Cost: 125,000 Credits\nPayment Status: 80,000 Credits Outstanding\nCollection Notice: FINAL NOTICE"
                    }
                ]
            }
        
        _:
            terminal_data = {
                "name": "Station Terminal",
                "logs": [
                    {
                        "timestamp": "2387.03.15 12:00",
                        "author": "System",
                        "title": "Daily Status",
                        "content": "All station systems operating normally. Crew morale stable. Research projects on schedule."
                    }
                ],
                "files": []
            }

func interact():
    if not is_enabled:
        print("Terminal offline due to power failure")
        return
    
    # Night cycle check removed - now handled by sabotage system
    # Terminal access is controlled by power status instead
    
    # Check keycard requirement
    if requires_keycard:
        var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
        if not evidence_manager or not _has_required_keycard(evidence_manager):
            print("Access denied. Required keycard not found.")
            return
    
    print("Accessing terminal: " + terminal_data.name)
    _open_terminal_ui()
    is_accessed = true
    terminal_accessed.emit(terminal_id, terminal_data)

func _has_required_keycard(evidence_manager) -> bool:
    if not evidence_manager or not evidence_manager.has_method("get_collected_evidence"):
        return false
    
    for evidence in evidence_manager.collected_evidence:
        if evidence.type == "keycard" and evidence.name.to_lower().contains(required_keycard_type.to_lower()):
            return true
    return false

func _open_terminal_ui():
    # Create a simple terminal UI
    var terminal_ui = preload("res://scenes/ui/terminal_ui.tscn")
    if terminal_ui:
        var ui_instance = terminal_ui.instantiate()
        get_tree().root.add_child(ui_instance)
        ui_instance.setup_terminal(terminal_data)
    else:
        # Fallback to print output if no UI scene exists yet
        print("\n=== " + terminal_data.name + " ===")
        print("Access granted. Select option:")
        print("1. View System Logs")
        print("2. Access Files")
        
        # For now, just print the first log entry
        if terminal_data.logs.size() > 0:
            var log_entry = terminal_data.logs[0]
            print("\nLatest Log Entry:")
            print("[" + log_entry.timestamp + "] " + log_entry.title)
            print("By: " + log_entry.author)
            print(log_entry.content)

func get_interaction_prompt() -> String:
    var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    if requires_keycard and not _has_required_keycard(evidence_manager):
        return "Press [E] to access terminal (Keycard Required)"
    
    # Night cycle check removed - terminals now controlled by power status
    
    if not is_enabled:
        return "Terminal Offline - Power Failure"
    
    return "Press [E] to access " + terminal_data.get("name", terminal_name)

func disable():
    is_enabled = false
    _update_screen_visual(false)
    print("Terminal ", terminal_id, " disabled due to power outage")

func enable():
    is_enabled = true
    _update_screen_visual(true)
    print("Terminal ", terminal_id, " power restored")

func _update_screen_visual(powered: bool):
    if not screen_mesh or not original_screen_material:
        return
    
    if powered:
        # Restore original material
        screen_mesh.mesh.surface_set_material(0, original_screen_material)
    else:
        # Create offline material
        var offline_material = StandardMaterial3D.new()
        offline_material.albedo_color = Color(0.1, 0.1, 0.1)
        offline_material.metallic = 0.1
        offline_material.roughness = 0.9
        offline_material.emission_enabled = false
        screen_mesh.mesh.surface_set_material(0, offline_material)

func get_room_name() -> String:
    # Determine which room this terminal is in based on position
    var pos = global_position
    
    if abs(pos.x - 7) < 5 and abs(pos.z + 10) < 10:
        return "Laboratory 3"
    elif abs(pos.x) < 5 and pos.z > 25:
        return "Engineering"
    elif abs(pos.x + 6) < 5 and abs(pos.z + 11) < 5:
        return "Crew Quarters"
    elif abs(pos.x + 7) < 5 and abs(pos.z + 5) < 5:
        return "Security Office"
    elif abs(pos.x - 6) < 5 and abs(pos.z - 4) < 5:
        return "Medical Bay"
    elif abs(pos.x) < 5 and abs(pos.z + 20) < 5:
        return "Cafeteria"
    
    return ""

func on_hover_start():
    pass

func on_hover_end():
    pass
