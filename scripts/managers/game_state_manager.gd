extends Node

enum GameMode {
	STORY,
	RANDOM
}

var current_mode: GameMode = GameMode.RANDOM
var current_story_id: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_game_mode(mode: GameMode):
	current_mode = mode
	print("Game mode set to: ", GameMode.keys()[mode])

func set_story_mode(story_id: String = "story1"):
	current_mode = GameMode.STORY
	current_story_id = story_id
	print("Story mode set with story: ", story_id)

func set_random_mode():
	current_mode = GameMode.RANDOM
	current_story_id = ""
	print("Random mode set")

func is_story_mode() -> bool:
	return current_mode == GameMode.STORY

func is_random_mode() -> bool:
	return current_mode == GameMode.RANDOM

func get_current_story_id() -> String:
	return current_story_id

func get_mode_name() -> String:
	return GameMode.keys()[current_mode]