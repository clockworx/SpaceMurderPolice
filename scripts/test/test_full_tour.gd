extends Node

# Test script to trigger full station tour
# Add this to a Node in your scene and run

@export var auto_start: bool = true
@export var npc_name_to_test: String = ""  # Leave empty to use first NPC found

var navigation_system = null
var test_npc = null

func _ready():
    print("\n=== Full Tour Test Script Loaded ===")
    print("Controls:")
    print("  F or SPACE - Start full station tour")
    print("  T - Test individual room navigation")
    print("  1-6 - Navigate to specific rooms")
    print("  Auto-start is: ", auto_start)
    
    if auto_start:
        # Wait a moment for scene to initialize
        await get_tree().create_timer(1.0).timeout
        start_full_tour()

func _input(event):
    # Use various keys for testing
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F:  # F key for full tour
                print("F key pressed - starting full tour")
                start_full_tour()
            KEY_T:  # T key for room test
                print("T key pressed - testing room navigation")
                test_room_navigation()
            KEY_SPACE:  # Space as alternative
                print("Space key pressed - starting full tour")
                start_full_tour()
            KEY_1:  # Number keys for specific rooms
                navigate_to_specific_room("MedicalBay_Waypoint")
            KEY_2:
                navigate_to_specific_room("Security_Waypoint")
            KEY_3:
                navigate_to_specific_room("Engineering_Waypoint")
            KEY_4:
                navigate_to_specific_room("CrewQuarters_Waypoint")
            KEY_5:
                navigate_to_specific_room("Cafeteria_Waypoint")
            KEY_6:
                navigate_to_specific_room("Laboratory_Waypoint")

func start_full_tour():
    print("\n=== STARTING FULL STATION TOUR ===")
    
    # Find NPC to test
    if npc_name_to_test != "":
        test_npc = get_node_or_null("/root/" + get_tree().current_scene.name + "/" + npc_name_to_test)
    else:
        test_npc = get_tree().get_first_node_in_group("npcs")
    
    if not test_npc:
        print("ERROR: No NPC found!")
        return
    
    print("Using NPC: ", test_npc.name)
    print("NPC Position: ", test_npc.global_position)
    
    # Try to find the clean navigation system
    navigation_system = null
    
    # Check different possible node names
    var possible_names = ["CleanNavWithCylinders", "@Node@", "Node", "@CleanNavWithCylinders@"]
    for node_name in possible_names:
        if test_npc.has_node(node_name):
            navigation_system = test_npc.get_node(node_name)
            if navigation_system.has_method("navigate_to"):
                print("Found navigation system as: ", node_name)
                break
            else:
                navigation_system = null
    
    # If not found by name, search by class
    if not navigation_system:
        for child in test_npc.get_children():
            if child.has_method("navigate_to"):
                navigation_system = child
                print("Found navigation system by method check: ", child.name, " (", child.get_class(), ")")
                break
    
    if navigation_system:
        # Start the full tour
        if navigation_system.navigate_to("FullTour", test_npc.global_position):
            print("Full tour navigation started!")
            print("Watch the red cylinder path visualization")
            
            # Connect to completion signal
            if not navigation_system.navigation_completed.is_connected(_on_navigation_completed):
                navigation_system.navigation_completed.connect(_on_navigation_completed)
        else:
            print("Failed to start navigation - check console for errors")
    else:
        print("ERROR: Navigation system not found on NPC")
        print("Available children:")
        for child in test_npc.get_children():
            print("  - ", child.name, " (", child.get_class(), ")")
            if child.has_method("navigate_to"):
                print("    ^ This child has navigate_to method!")

func test_room_navigation():
    if not test_npc:
        print("No NPC selected - press F first to select an NPC")
        return
        
    # Cycle through rooms for testing
    var rooms = ["MedicalBay_Waypoint", "Security_Waypoint", "Engineering_Waypoint", 
                 "CrewQuarters_Waypoint", "Cafeteria_Waypoint", "Laboratory_Waypoint"]
    
    var current_room_index = 0
    if has_meta("test_room_index"):
        current_room_index = get_meta("test_room_index")
    
    var target_room = rooms[current_room_index]
    print("\nNavigating to: ", target_room)
    
    if navigation_system and navigation_system.navigate_to(target_room, test_npc.global_position):
        print("Navigation started to ", target_room)
        
        # Update index for next test
        current_room_index = (current_room_index + 1) % rooms.size()
        set_meta("test_room_index", current_room_index)
    else:
        print("Failed to navigate to ", target_room)

func _on_navigation_completed():
    print("\n=== NAVIGATION COMPLETED ===")
    print("Final NPC position: ", test_npc.global_position)
    print("Tour finished successfully!")

func navigate_to_specific_room(room_name: String):
    print("\nNavigating to specific room: ", room_name)
    
    # Find NPC if not already found
    if not test_npc:
        test_npc = get_tree().get_first_node_in_group("npcs")
        if not test_npc:
            print("ERROR: No NPC found!")
            return
    
    # Find navigation system if not already found
    if not navigation_system:
        for child in test_npc.get_children():
            if child.has_method("navigate_to"):
                navigation_system = child
                break
        
        if not navigation_system:
            print("ERROR: Navigation system not found on NPC")
            return
    
    # Navigate to the room
    if navigation_system.navigate_to(room_name, test_npc.global_position):
        print("Started navigation to ", room_name)
    else:
        print("Failed to navigate to ", room_name)

func _exit_tree():
    # Clean up connections
    if navigation_system and navigation_system.navigation_completed.is_connected(_on_navigation_completed):
        navigation_system.navigation_completed.disconnect(_on_navigation_completed)
