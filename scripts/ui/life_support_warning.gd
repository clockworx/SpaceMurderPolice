extends Control
class_name LifeSupportWarning

@onready var warning_title = $WarningPanel/VBoxContainer/WarningTitle
@onready var warning_message = $WarningPanel/VBoxContainer/WarningMessage
@onready var close_timer = $CloseTimer
@onready var animation_player = $AnimationPlayer

func _ready():
	close_timer.timeout.connect(_close_warning)

func show_warning(title: String, message: String):
	warning_title.text = title
	warning_message.text = message
	
	# Determine animation based on severity
	if title.contains("CRITICAL") or title.contains("FAILURE"):
		animation_player.play("flash")
	
	# Auto-close after timer
	close_timer.start()

func _close_warning():
	queue_free()

func _input(event):
	# Allow manual close with any key
	if event.is_pressed():
		_close_warning()