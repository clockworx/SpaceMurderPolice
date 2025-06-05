extends StaticBody3D
class_name ComputerTerminal

@export var terminal_id: String = "general_terminal"
@export var terminal_name: String = "Station Terminal"
@export var requires_keycard: bool = false
@export var required_keycard_type: String = ""
@export var is_night_cycle_only: bool = false

var terminal_data: Dictionary = {}
var is_accessed: bool = false

signal terminal_accessed(terminal_id: String, data: Dictionary)

func _ready():
	add_to_group("interactable")
	collision_layer = 2
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
	var day_night = get_tree().get_first_node_in_group("day_night_manager")
	
	# Check if requires night cycle
	if terminal_data.has("requires_night") and terminal_data.requires_night:
		if not day_night or day_night.is_day_time():
			print("This terminal is locked during day hours.")
			return
	
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
			var log = terminal_data.logs[0]
			print("\nLatest Log Entry:")
			print("[" + log.timestamp + "] " + log.title)
			print("By: " + log.author)
			print(log.content)

func get_interaction_prompt() -> String:
	var evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
	if requires_keycard and not _has_required_keycard(evidence_manager):
		return "Press [E] to access terminal (Keycard Required)"
	
	var day_night = get_tree().get_first_node_in_group("day_night_manager")
	if terminal_data.has("requires_night") and terminal_data.requires_night:
		if not day_night or day_night.is_day_time():
			return "Press [E] to access terminal (Locked - Night Access Only)"
	
	return "Press [E] to access " + terminal_data.get("name", terminal_name)

func on_hover_start():
	pass

func on_hover_end():
	pass