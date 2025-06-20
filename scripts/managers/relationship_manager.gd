extends Node
class_name RelationshipManager

# Relationship levels
enum RelationshipLevel {
    HOSTILE = -2,    # Won't cooperate, withholds information
    UNFRIENDLY = -1, # Reluctant to help, minimal cooperation
    NEUTRAL = 0,     # Default state, normal responses
    FRIENDLY = 1,    # More helpful, shares extra details
    TRUSTED = 2      # Full cooperation, reveals secrets
}

# Track relationships with each NPC
var relationships: Dictionary = {}

# Track important decisions made
var player_decisions: Dictionary = {}

signal relationship_changed(npc_name: String, old_level: int, new_level: int)

func _ready():
    add_to_group("relationship_manager")
    
    # Initialize all NPCs at neutral
    _init_relationships()

func _init_relationships():
    relationships["Commander Chen"] = RelationshipLevel.NEUTRAL
    relationships["Dr. Webb"] = RelationshipLevel.NEUTRAL
    relationships["Riley Kim"] = RelationshipLevel.NEUTRAL
    relationships["Jake Torres"] = RelationshipLevel.UNFRIENDLY  # Starts unfriendly
    relationships["Dr. Okafor"] = RelationshipLevel.FRIENDLY     # Starts friendly

func modify_relationship(npc_name: String, change: int):
    if not relationships.has(npc_name):
        push_error("Unknown NPC: " + npc_name)
        return
    
    var old_level = relationships[npc_name]
    var new_level = clamp(old_level + change, RelationshipLevel.HOSTILE, RelationshipLevel.TRUSTED)
    
    if old_level != new_level:
        relationships[npc_name] = new_level
        relationship_changed.emit(npc_name, old_level, new_level)
        print("Relationship with ", npc_name, " changed from ", _get_level_name(old_level), " to ", _get_level_name(new_level))

func get_relationship(npc_name: String) -> int:
    return relationships.get(npc_name, RelationshipLevel.NEUTRAL)

func is_hostile(npc_name: String) -> bool:
    return get_relationship(npc_name) == RelationshipLevel.HOSTILE

func is_friendly(npc_name: String) -> bool:
    return get_relationship(npc_name) >= RelationshipLevel.FRIENDLY

func can_get_important_info(npc_name: String) -> bool:
    # Important info requires at least neutral relationship
    return get_relationship(npc_name) >= RelationshipLevel.NEUTRAL

func record_decision(decision_id: String, value: Variant):
    player_decisions[decision_id] = value
    print("Decision recorded: ", decision_id, " = ", value)

func has_made_decision(decision_id: String) -> bool:
    return player_decisions.has(decision_id)

func get_decision(decision_id: String) -> Variant:
    return player_decisions.get(decision_id, null)

func _get_level_name(level: int) -> String:
    match level:
        RelationshipLevel.HOSTILE:
            return "Hostile"
        RelationshipLevel.UNFRIENDLY:
            return "Unfriendly"
        RelationshipLevel.NEUTRAL:
            return "Neutral"
        RelationshipLevel.FRIENDLY:
            return "Friendly"
        RelationshipLevel.TRUSTED:
            return "Trusted"
        _:
            return "Unknown"

func get_relationship_color(npc_name: String) -> Color:
    match get_relationship(npc_name):
        RelationshipLevel.HOSTILE:
            return Color(0.8, 0.2, 0.2)  # Red
        RelationshipLevel.UNFRIENDLY:
            return Color(0.8, 0.5, 0.2)  # Orange
        RelationshipLevel.NEUTRAL:
            return Color(0.8, 0.8, 0.8)  # Gray
        RelationshipLevel.FRIENDLY:
            return Color(0.2, 0.8, 0.2)  # Green
        RelationshipLevel.TRUSTED:
            return Color(0.2, 0.5, 0.8)  # Blue
        _:
            return Color.WHITE
