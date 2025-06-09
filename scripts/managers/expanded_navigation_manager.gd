extends Node
class_name ExpandedNavigationManager

# Navigation manager for the expanded station
# Handles NPC spawning and navigation setup

var waypoint_navigation: WaypointNavigationSystem

func _ready():
    # Wait for station to be built
    await get_tree().process_frame
    await get_tree().process_frame
    
    # Create waypoint navigation system
    waypoint_navigation = WaypointNavigationSystem.new()
    waypoint_navigation.name = "WaypointNavigation"
    waypoint_navigation.add_to_group("waypoint_navigation")
    add_child(waypoint_navigation)
    
    # Initialize NPCs
    _initialize_npcs()

func _initialize_npcs():
    # Make sure all NPCs are properly positioned
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("ExpandedNavigationManager: Initializing ", npcs.size(), " NPCs")
    
    for npc in npcs:
        if not is_instance_valid(npc):
            continue
            
        # Ensure NPC is at correct Y position
        if npc.global_position.y < 0.5:
            npc.global_position.y = 1.0
        
        # DISABLED: User has manually placed NPCs
        # Don't reassign rooms
        # if npc.has_method("_assign_npc_to_room"):
        #     npc._assign_npc_to_room()
        
        var npc_name = npc.get("npc_name") if npc.get("npc_name") else npc.name
        var assigned_room = npc.get("assigned_room") if npc.get("assigned_room") else "unknown"
        print("  - ", npc_name, " at ", npc.global_position, " in room: ", assigned_room)