extends Node
class_name DayNightManager

# DEPRECATED: This manager has been replaced by SabotageSystemManager
# This stub exists only to prevent scene loading errors

enum TimeOfDay {
    DAY,
    NIGHT
}

var current_time: TimeOfDay = TimeOfDay.DAY
var evidence_collected: int = 0

# Signals kept for compatibility but not used
# signal day_started()
# signal night_started()
# signal transition_started(to_night: bool)
# signal transition_completed(to_night: bool)

func _ready():
    add_to_group("day_night_manager")
    print("DayNightManager: DEPRECATED - This system has been replaced by SabotageSystemManager")
    
    # Remove this node after a short delay to allow scene to load
    queue_free.call_deferred()

func trigger_night_cycle():
    # Do nothing - replaced by sabotage system
    pass

func force_day_cycle():
    # Do nothing - replaced by sabotage system
    pass

func is_night_time() -> bool:
    return false

func is_day_time() -> bool:
    return true

func get_evidence_progress() -> float:
    return 0.0
