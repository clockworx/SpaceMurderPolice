extends Node

# Autoload manager to fix waypoint reach distances at runtime

func _ready():
    # Connect to scene changed signal to fix NPCs whenever a new scene loads
    get_tree().node_added.connect(_on_node_added)
    
    # Fix any existing NPCs
    await get_tree().process_frame
    _fix_all_npcs()

func _on_node_added(node: Node):
    # Check if this is an NPC with waypoint settings
    if node.has_method("set") and node.get("waypoint_reach_distance") != null:
        var current_value = node.get("waypoint_reach_distance")
        if current_value > 1.0:
            node.set("waypoint_reach_distance", 0.3)
            print("[WaypointFixManager] Fixed ", node.name, " reach distance: ", current_value, " -> 0.3")
        
        # Also ensure is_paused is initialized
        if node.get("is_paused") == null:
            node.set("is_paused", false)

func _fix_all_npcs():
    var all_nodes = []
    if get_tree().current_scene:
        _get_all_nodes(get_tree().current_scene, all_nodes)
        
        var fixed_count = 0
        for node in all_nodes:
            if node.has_method("set") and node.get("waypoint_reach_distance") != null:
                var current_value = node.get("waypoint_reach_distance") 
                if current_value > 1.0:
                    node.set("waypoint_reach_distance", 0.3)
                    print("[WaypointFixManager] Fixed ", node.name, " reach distance: ", current_value, " -> 0.3")
                    fixed_count += 1
        
        if fixed_count > 0:
            print("[WaypointFixManager] Fixed ", fixed_count, " NPCs total")

func _get_all_nodes(node: Node, result: Array):
    result.append(node)
    for child in node.get_children():
        _get_all_nodes(child, result)
