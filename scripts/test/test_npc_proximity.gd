extends Node

# Test proximity-based state changes
# NPCs will go IDLE when player is near, TALK when very close

var check_timer: float = 0.0
var idle_distance: float = 5.0  # Distance to trigger IDLE
var talk_distance: float = 2.0  # Distance to trigger TALK

func _ready():
    print("=== NPC Proximity Test ===")
    print("NPCs will react to player proximity:")
    print("- Within 5 units: IDLE state")
    print("- Within 2 units: TALK state (face player)")
    print("- Beyond 5 units: Resume PATROL")

func _process(delta):
    check_timer += delta
    if check_timer < 0.2:  # Check 5 times per second
        return
    check_timer = 0.0
    
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return
    
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if not npc.has_method("set_state"):
            continue
            
        # Skip if in dialogue
        if npc.get("is_talking"):
            continue
            
        var distance = npc.global_position.distance_to(player.global_position)
        var current_state = npc.get("current_state")
        
        if distance <= talk_distance:
            # Very close - face the player
            if current_state != npc.MovementState.TALK:
                npc.set_talk_state(player.global_position)
                print(npc.get("npc_name"), " noticed player very close!")
                
        elif distance <= idle_distance:
            # Near - stop and idle
            if current_state == npc.MovementState.PATROL:
                npc.set_idle_state()
                print(npc.get("npc_name"), " noticed player nearby")
                
        else:
            # Far - resume patrol
            if current_state != npc.MovementState.PATROL:
                npc.set_patrol_state()
                print(npc.get("npc_name"), " resumed patrol")