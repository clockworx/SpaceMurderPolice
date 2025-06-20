extends Node
class_name ScheduleManager

# Room definitions from CLAUDE.md
enum Room {
	LABORATORY_3,
	MEDICAL_BAY,
	SECURITY_OFFICE,
	ENGINEERING,
	CREW_QUARTERS,
	CAFETERIA
}

# Time periods for the station
enum TimePeriod {
	EARLY_MORNING,  # 06:00 - 08:00
	MORNING,        # 08:00 - 12:00
	LUNCH,          # 12:00 - 13:00
	AFTERNOON,      # 13:00 - 17:00
	EVENING,        # 17:00 - 19:00
	NIGHT,          # 19:00 - 22:00
	LATE_NIGHT      # 22:00 - 06:00
}

# Schedule entry
class ScheduleEntry:
	var time_period: TimePeriod
	var room: Room
	var activity: String
	var duration_minutes: int = 60
	
	func _init(period: TimePeriod, target_room: Room, desc: String = "", duration: int = 60):
		time_period = period
		room = target_room
		activity = desc
		duration_minutes = duration

# Export variables
@export var current_hour: int = 8:  # Station time (24h format)
	set(value):
		current_hour = value % 24
		_on_time_changed()
@export var current_minute: int = 0:
	set(value):
		current_minute = value % 60
		if value >= 60:
			current_hour += value / 60
		_on_time_changed()
@export var time_speed_multiplier: float = 60.0  # 1 real second = 1 game minute by default
@export var paused: bool = false
@export var debug_mode: bool = true

# Room waypoint mappings
var room_waypoints: Dictionary = {
	Room.LABORATORY_3: "Laboratory_Waypoint",
	Room.MEDICAL_BAY: "MedicalBay_Waypoint",
	Room.SECURITY_OFFICE: "Security_Waypoint",
	Room.ENGINEERING: "Engineering_Waypoint",
	Room.CREW_QUARTERS: "CrewQuarters_Waypoint",
	Room.CAFETERIA: "Cafeteria_Waypoint"
}

# NPC schedules
var npc_schedules: Dictionary = {}

# Signals
signal time_changed(hour: int, minute: int)
signal time_period_changed(period: TimePeriod)
signal schedule_changed(npc_name: String, new_room: Room)

# Time tracking
var _time_accumulator: float = 0.0
var _current_time_period: TimePeriod = TimePeriod.MORNING

func _ready():
	add_to_group("schedule_manager")
	_initialize_default_schedules()
	_on_time_changed()

func _process(delta):
	if paused:
		return
		
	_time_accumulator += delta * time_speed_multiplier
	
	# Add minutes
	while _time_accumulator >= 60.0:
		_time_accumulator -= 60.0
		current_minute += 1

func _initialize_default_schedules():
	# Chief Scientist schedule
	var scientist_schedule = [
		ScheduleEntry.new(TimePeriod.EARLY_MORNING, Room.CREW_QUARTERS, "Waking up"),
		ScheduleEntry.new(TimePeriod.MORNING, Room.LABORATORY_3, "Research work", 240),
		ScheduleEntry.new(TimePeriod.LUNCH, Room.CAFETERIA, "Lunch break"),
		ScheduleEntry.new(TimePeriod.AFTERNOON, Room.LABORATORY_3, "Experiments", 180),
		ScheduleEntry.new(TimePeriod.EVENING, Room.MEDICAL_BAY, "Health checkup", 30),
		ScheduleEntry.new(TimePeriod.EVENING, Room.CAFETERIA, "Dinner", 60),
		ScheduleEntry.new(TimePeriod.NIGHT, Room.ENGINEERING, "System checks", 60),
		ScheduleEntry.new(TimePeriod.LATE_NIGHT, Room.CREW_QUARTERS, "Sleeping")
	]
	
	npc_schedules["Dr. Marcus Webb"] = scientist_schedule

func get_current_time_period() -> TimePeriod:
	if current_hour >= 6 and current_hour < 8:
		return TimePeriod.EARLY_MORNING
	elif current_hour >= 8 and current_hour < 12:
		return TimePeriod.MORNING
	elif current_hour >= 12 and current_hour < 13:
		return TimePeriod.LUNCH
	elif current_hour >= 13 and current_hour < 17:
		return TimePeriod.AFTERNOON
	elif current_hour >= 17 and current_hour < 19:
		return TimePeriod.EVENING
	elif current_hour >= 19 and current_hour < 22:
		return TimePeriod.NIGHT
	else:
		return TimePeriod.LATE_NIGHT

func get_room_name(room: Room) -> String:
	match room:
		Room.LABORATORY_3: return "Laboratory 3"
		Room.MEDICAL_BAY: return "Medical Bay"
		Room.SECURITY_OFFICE: return "Security Office"
		Room.ENGINEERING: return "Engineering"
		Room.CREW_QUARTERS: return "Crew Quarters"
		Room.CAFETERIA: return "Cafeteria"
		_: return "Unknown"

func get_time_period_name(period: TimePeriod) -> String:
	match period:
		TimePeriod.EARLY_MORNING: return "Early Morning"
		TimePeriod.MORNING: return "Morning"
		TimePeriod.LUNCH: return "Lunch"
		TimePeriod.AFTERNOON: return "Afternoon"
		TimePeriod.EVENING: return "Evening"
		TimePeriod.NIGHT: return "Night"
		TimePeriod.LATE_NIGHT: return "Late Night"
		_: return "Unknown"

func get_npc_scheduled_room(npc_name: String) -> Room:
	if not npc_schedules.has(npc_name):
		return Room.LABORATORY_3  # Default room
	
	var schedule = npc_schedules[npc_name]
	var current_period = get_current_time_period()
	
	# Find the scheduled room for current time period
	for entry in schedule:
		if entry.time_period == current_period:
			return entry.room
	
	# If no exact match, return the last scheduled room before current time
	var last_room = Room.CREW_QUARTERS
	for entry in schedule:
		if entry.time_period <= current_period:
			last_room = entry.room
		else:
			break
	
	return last_room

func get_room_waypoint_name(room: Room) -> String:
	return room_waypoints.get(room, "")

func get_npc_current_activity(npc_name: String) -> String:
	if not npc_schedules.has(npc_name):
		return "Idle"
	
	var schedule = npc_schedules[npc_name]
	var current_period = get_current_time_period()
	
	for entry in schedule:
		if entry.time_period == current_period:
			return entry.activity
	
	return "Transitioning"

func _on_time_changed():
	var new_period = get_current_time_period()
	if new_period != _current_time_period:
		_current_time_period = new_period
		time_period_changed.emit(new_period)
		_update_all_npc_schedules()
	
	time_changed.emit(current_hour, current_minute)

func _update_all_npc_schedules():
	for npc_name in npc_schedules:
		var scheduled_room = get_npc_scheduled_room(npc_name)
		schedule_changed.emit(npc_name, scheduled_room)

func force_time_period(period: TimePeriod):
	# Debug function to jump to a specific time period
	match period:
		TimePeriod.EARLY_MORNING:
			current_hour = 6
			current_minute = 0
		TimePeriod.MORNING:
			current_hour = 8
			current_minute = 0
		TimePeriod.LUNCH:
			current_hour = 12
			current_minute = 0
		TimePeriod.AFTERNOON:
			current_hour = 13
			current_minute = 0
		TimePeriod.EVENING:
			current_hour = 17
			current_minute = 0
		TimePeriod.NIGHT:
			current_hour = 19
			current_minute = 0
		TimePeriod.LATE_NIGHT:
			current_hour = 22
			current_minute = 0

func advance_time(minutes: int):
	current_minute += minutes

func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]