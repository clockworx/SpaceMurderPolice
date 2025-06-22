extends Node

# Test the simple direct navigation
# Add this script to a Node in your scene

func _ready():
    print("\n=== SIMPLE DIRECT NAVIGATION TEST ===")
    print("Press 9 to test simple direct navigation")

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_9:
            print("\nTesting simple direct navigation...")
            
            # Find Dr. Marcus Webb
            var npc = null
            var all_npcs = get_tree().get_nodes_in_group("npcs")
            for test_npc in all_npcs:
                if test_npc.has_method("get") and test_npc.get("npc_name") == "Dr. Marcus Webb":
                    npc = test_npc
                    break
            
            if not npc:
                print("ERROR: Dr. Marcus Webb not found!")
                return
            
            print("Found NPC: ", npc.npc_name)
            
            # Remove existing navigation
            for child in npc.get_children():
                if child.has_method("navigate_to_room"):
                    print("Removing existing navigation: ", child.name)
                    child.queue_free()
            
            # Wait a frame for cleanup
            await get_tree().process_frame
            
            # Add simple direct navigation
            var SimpleNav = preload("res://scripts/npcs/simple_direct_navigation.gd")
            var simple_nav = SimpleNav.new(npc)
            npc.add_child(simple_nav)
            
            print("Added simple direct navigation")
            
            # Start the tour
            if simple_nav.navigate_to_room("FullTour"):
                print("Started full tour with simple navigation!")
            else:
                print("Failed to start navigation")