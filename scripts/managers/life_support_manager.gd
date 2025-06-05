extends Node
class_name LifeSupportManager

# Life support failure system for adding urgency to investigations
@export var initial_oxygen_minutes: float = 45.0  # 45 minutes of oxygen
@export var warning_thresholds: Array[float] = [30.0, 15.0, 5.0, 2.0]  # Warning times in minutes
@export var failure_delay_minutes: float = 5.0  # Delay before life support starts failing

var current_oxygen_time: float = 0.0
var is_life_support_active: bool = true
var failure_started: bool = false
var warnings_shown: Array[bool] = []
var emergency_lights_active: bool = false

signal life_support_warning(minutes_remaining: float)
signal life_support_critical(minutes_remaining: float)
signal life_support_failure()
signal emergency_power_activated()

func _ready():
	add_to_group("life_support_manager")
	current_oxygen_time = initial_oxygen_minutes * 60.0  # Convert to seconds
	
	# Initialize warnings array
	warnings_shown.resize(warning_thresholds.size())
	for i in range(warnings_shown.size()):
		warnings_shown[i] = false
	
	# Start failure timer
	await get_tree().create_timer(failure_delay_minutes * 60.0).timeout
	_start_life_support_failure()
	
	print("Life Support Manager initialized - ", initial_oxygen_minutes, " minutes of oxygen available")

func _process(delta):
	if not is_life_support_active and failure_started:
		current_oxygen_time -= delta
		current_oxygen_time = max(0.0, current_oxygen_time)
		
		_check_warning_thresholds()
		
		if current_oxygen_time <= 0.0:
			_trigger_life_support_failure()

func _start_life_support_failure():
	if failure_started:
		return
		
	failure_started = true
	is_life_support_active = false
	
	print("Life Support: System failure detected! Oxygen supply compromised.")
	
	# Trigger emergency lighting
	_activate_emergency_lighting()
	
	# Show initial warning
	_show_life_support_warning("LIFE SUPPORT FAILURE DETECTED", "Station oxygen reserves: " + str(int(current_oxygen_time / 60.0)) + " minutes remaining")

func _check_warning_thresholds():
	var minutes_remaining = current_oxygen_time / 60.0
	
	for i in range(warning_thresholds.size()):
		var threshold = warning_thresholds[i]
		if minutes_remaining <= threshold and not warnings_shown[i]:
			warnings_shown[i] = true
			
			if threshold <= 5.0:
				life_support_critical.emit(minutes_remaining)
				_show_critical_warning(minutes_remaining)
			else:
				life_support_warning.emit(minutes_remaining)
				_show_life_support_warning("OXYGEN WARNING", str(int(minutes_remaining)) + " minutes of oxygen remaining")

func _show_life_support_warning(title: String, message: String):
	# Create warning UI
	var warning_ui = preload("res://scenes/ui/life_support_warning.tscn")
	if warning_ui:
		var warning_instance = warning_ui.instantiate()
		get_tree().root.add_child(warning_instance)
		warning_instance.show_warning(title, message)
	else:
		# Fallback to print
		print("LIFE SUPPORT WARNING: ", title, " - ", message)

func _show_critical_warning(minutes_remaining: float):
	var title = "CRITICAL OXYGEN SHORTAGE"
	var message = ""
	
	if minutes_remaining <= 2.0:
		message = "IMMEDIATE EVACUATION REQUIRED - " + str(int(minutes_remaining * 60)) + " seconds remaining"
	else:
		message = "OXYGEN CRITICALLY LOW - " + str(int(minutes_remaining)) + " minutes remaining"
	
	_show_life_support_warning(title, message)
	
	# Start emergency flashing
	if not emergency_lights_active:
		_start_emergency_flashing()

func _activate_emergency_lighting():
	emergency_lights_active = true
	emergency_power_activated.emit()
	
	# Dim main lights and activate emergency lighting
	var world_env = get_tree().get_first_node_in_group("world_environment")
	if world_env and world_env.environment:
		# Reduce ambient lighting
		world_env.environment.ambient_light_energy = 1.0
		world_env.environment.ambient_light_color = Color(1, 0.3, 0.3)  # Red tint
	
	# Find all room lights and dim them
	var room_lights = get_tree().get_nodes_in_group("room_lights")
	for light in room_lights:
		if light is Light3D:
			light.light_energy *= 0.3  # Dim to 30%
			light.light_color = Color(1, 0.4, 0.4)  # Red emergency tint

func _start_emergency_flashing():
	var flash_timer = Timer.new()
	flash_timer.wait_time = 0.5
	flash_timer.timeout.connect(_flash_emergency_lights)
	flash_timer.autostart = true
	add_child(flash_timer)

func _flash_emergency_lights():
	var room_lights = get_tree().get_nodes_in_group("room_lights")
	for light in room_lights:
		if light is Light3D:
			# Toggle between dim and dimmer
			if light.light_energy > 0.2:
				light.light_energy = 0.1
			else:
				light.light_energy = 0.3

func _trigger_life_support_failure():
	life_support_failure.emit()
	
	# Show game over screen
	_show_life_support_warning("LIFE SUPPORT FAILURE", "Oxygen depleted. Investigation terminated.")
	
	# Trigger game over after delay
	await get_tree().create_timer(3.0).timeout
	_handle_game_over()

func _handle_game_over():
	# Return to main menu or restart level
	print("Game Over: Life support failure")
	# You could add a game over screen here or restart the level
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func get_remaining_time_minutes() -> float:
	return current_oxygen_time / 60.0

func get_remaining_time_formatted() -> String:
	var minutes = int(current_oxygen_time / 60.0)
	var seconds = int(current_oxygen_time) % 60
	return str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

func is_critical() -> bool:
	return current_oxygen_time <= 5.0 * 60.0  # Last 5 minutes are critical

func extend_life_support(additional_minutes: float):
	# Allow extending life support through story events
	current_oxygen_time += additional_minutes * 60.0
	print("Life Support: Emergency reserves activated. +" + str(additional_minutes) + " minutes added.")

func repair_life_support():
	# Allow full repair through story progression
	is_life_support_active = true
	failure_started = false
	current_oxygen_time = initial_oxygen_minutes * 60.0
	
	# Restore normal lighting
	var world_env = get_tree().get_first_node_in_group("world_environment")
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = 2.5
		world_env.environment.ambient_light_color = Color(1, 1, 1)
	
	var room_lights = get_tree().get_nodes_in_group("room_lights")
	for light in room_lights:
		if light is Light3D:
			light.light_energy = 2.0  # Restore full brightness
			light.light_color = Color(1, 1, 1)  # Normal white light
	
	print("Life Support: System fully repaired and operational.")