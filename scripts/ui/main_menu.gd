extends Control

@onready var story_button = $MenuContainer/StoryModeButton
@onready var random_button = $MenuContainer/RandomModeButton
@onready var unified_button = $MenuContainer/UnifiedStationButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var quit_button = $MenuContainer/QuitButton
@onready var mode_description = $ModeDescription

var hovering_story = false
var hovering_random = false

func _ready():
    # Connect button signals
    story_button.pressed.connect(_on_story_mode_pressed)
    random_button.pressed.connect(_on_random_mode_pressed)
    unified_button.pressed.connect(_on_unified_station_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    
    # Connect hover signals for mode descriptions
    story_button.mouse_entered.connect(_on_story_hover)
    story_button.mouse_exited.connect(_on_hover_exit)
    random_button.mouse_entered.connect(_on_random_hover)
    random_button.mouse_exited.connect(_on_hover_exit)
    unified_button.mouse_entered.connect(_on_unified_hover)
    unified_button.mouse_exited.connect(_on_hover_exit)
    
    # Set initial focus
    story_button.grab_focus()

func _on_story_mode_pressed():
    print("Starting Story Mode...")
    GameStateManager.set_story_mode("story1")
    get_tree().change_scene_to_file("res://scenes/levels/NewStation.tscn")

func _on_random_mode_pressed():
    print("Starting Random Mode...")
    GameStateManager.set_random_mode()
    get_tree().change_scene_to_file("res://scenes/levels/NewStation.tscn")

func _on_unified_station_pressed():
    print("Loading Unified Station...")
    get_tree().change_scene_to_file("res://scenes/levels/NewStation.tscn")

func _on_settings_pressed():
    print("Settings not yet implemented")
    # TODO: Open settings menu

func _on_quit_pressed():
    get_tree().quit()

func _on_story_hover():
    hovering_story = true
    mode_description.text = "Experience handcrafted murder mysteries with carefully placed clues and compelling narratives"

func _on_random_hover():
    hovering_random = true
    mode_description.text = "Investigate procedurally generated cases with random evidence placement for endless replayability"

func _on_unified_hover():
    mode_description.text = "Test the unified 3-level station with 20+ rooms and seamless navigation"

func _on_hover_exit():
    hovering_story = false
    hovering_random = false
    mode_description.text = "Select a game mode to begin your investigation"
