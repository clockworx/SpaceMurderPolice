extends Node3D
class_name ShipInterior

# The Deduction - Mobile forensics laboratory and investigation hub

# Persistent data that travels between missions
static var collected_evidence_archive: Array[Dictionary] = []
static var case_notes: Dictionary = {}
static var solved_cases: Array[String] = []
static var ship_upgrades: Dictionary = {
    "forensics_level": 1,
    "computer_level": 1,
    "evidence_storage": 10,
    "deduction_assists": 3
}

# Current mission data (static so it can be accessed from ship_entrance)
static var current_case_evidence: Array[Dictionary] = []
var current_suspects: Array[String] = []
var current_connections: Array[Dictionary] = []

# Ship stations
@onready var evidence_board = $Stations/EvidenceBoard
@onready var forensics_station = $Stations/ForensicsStation
@onready var computer_station = $Stations/ComputerStation
@onready var case_file_station = $Stations/CaseFileStation
@onready var exit_door = $ExitDoor

# UI References
var case_file_ui: Control
var evidence_board_ui: Control
var terminal_ui: Control

signal exit_to_mission()
signal case_solved(case_id: String)
signal evidence_analyzed(evidence_data: Dictionary)

func _ready():
    add_to_group("ship_interior")
    
    # Load any saved persistent data
    _load_persistent_data()
    
    print("The Deduction: Systems online. Ready for investigation.")


func interact_with_station(station_type: String):
    match station_type:
        "evidence_board":
            _open_evidence_board()
        "forensics":
            _open_forensics_lab()
        "computer":
            _open_computer_terminal()
        "case_files":
            _open_case_files()
        "exit_door":
            _exit_to_mission()

func _open_evidence_board():
    print("Opening evidence connection interface...")
    # TODO: Create evidence board UI scene
    
func _open_forensics_lab():
    print("Opening forensics analysis...")
    # TODO: Create forensics UI scene
    
func _open_computer_terminal():
    print("Opening ship computer...")
    # TODO: Create terminal UI scene
    
func _open_case_files():
    print("Opening case files...")
    # TODO: Create case file UI scene
    
func _exit_to_mission():
    print("Returning to mission...")
    # Use ship manager to return to mission
    var ship_manager = get_tree().get_first_node_in_group("ship_manager")
    if not ship_manager:
        ship_manager = ShipManager.new()
        get_tree().root.add_child(ship_manager)
    ship_manager.exit_ship()
    exit_to_mission.emit()

func add_evidence_to_ship(evidence_data: Dictionary):
    # Add evidence collected from mission to ship's database
    current_case_evidence.append(evidence_data)
    
    # Check storage capacity
    if current_case_evidence.size() > ship_upgrades["evidence_storage"]:
        print("Warning: Evidence storage full! Upgrade ship storage capacity.")
    
    print("Evidence added to ship database: ", evidence_data.name)

func analyze_evidence(evidence_data: Dictionary) -> Dictionary:
    # Forensics analysis based on ship upgrade level
    var analysis_results = {
        "evidence_name": evidence_data.name,
        "type": evidence_data.type,
        "base_info": evidence_data.description,
        "forensic_details": []
    }
    
    # Higher forensics level reveals more details
    if ship_upgrades["forensics_level"] >= 1:
        analysis_results.forensic_details.append("Basic analysis complete")
    if ship_upgrades["forensics_level"] >= 2:
        analysis_results.forensic_details.append("DNA/fingerprint analysis available")
    if ship_upgrades["forensics_level"] >= 3:
        analysis_results.forensic_details.append("Advanced molecular analysis unlocked")
    
    evidence_analyzed.emit(analysis_results)
    return analysis_results

func connect_evidence(evidence1: Dictionary, evidence2: Dictionary, connection_type: String):
    # Create a connection between two pieces of evidence
    var connection = {
        "from": evidence1.name,
        "to": evidence2.name,
        "type": connection_type,
        "timestamp": Time.get_unix_time_from_system()
    }
    current_connections.append(connection)
    print("Connected: ", evidence1.name, " -> ", evidence2.name, " (", connection_type, ")")

func save_case_note(note_title: String, note_content: String):
    # Save investigation notes
    if not case_notes.has("current_case"):
        case_notes["current_case"] = {}
    
    case_notes["current_case"][note_title] = {
        "content": note_content,
        "timestamp": Time.get_unix_time_from_system()
    }
    print("Case note saved: ", note_title)

func check_deduction(_suspect: String, _evidence_chain: Array[String]) -> bool:
    # Use deduction assists to verify theory
    if ship_upgrades["deduction_assists"] > 0:
        ship_upgrades["deduction_assists"] -= 1
        # TODO: Implement deduction logic
        return true
    else:
        print("No deduction assists remaining!")
        return false

func solve_case(case_id: String, culprit: String, motive: String):
    # Mark case as solved
    var _case_data = {
        "id": case_id,
        "culprit": culprit,
        "motive": motive,
        "evidence_count": current_case_evidence.size(),
        "solve_time": Time.get_unix_time_from_system()
    }
    solved_cases.append(case_id)
    
    # Archive current evidence
    collected_evidence_archive.append_array(current_case_evidence)
    
    # Clear current case data
    current_case_evidence.clear()
    current_suspects.clear()
    current_connections.clear()
    
    case_solved.emit(case_id)
    print("Case solved! Culprit: ", culprit, ", Motive: ", motive)

func upgrade_ship(upgrade_type: String):
    # Upgrade ship capabilities
    if ship_upgrades.has(upgrade_type):
        ship_upgrades[upgrade_type] += 1
        print("Ship upgraded: ", upgrade_type, " -> Level ", ship_upgrades[upgrade_type])

func _load_persistent_data():
    # TODO: Load from save file
    print("Ship data loaded. Solved cases: ", solved_cases.size())

func _save_persistent_data():
    # TODO: Save to file
    print("Ship data saved.")

func get_interaction_prompt() -> String:
    return "Press [E] to interact"

func get_ship_stats() -> Dictionary:
    return {
        "evidence_collected": collected_evidence_archive.size(),
        "cases_solved": solved_cases.size(),
        "forensics_level": ship_upgrades["forensics_level"],
        "computer_level": ship_upgrades["computer_level"],
        "storage_capacity": ship_upgrades["evidence_storage"],
        "deduction_assists": ship_upgrades["deduction_assists"]
    }
