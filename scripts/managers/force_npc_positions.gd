extends Node

# This script FORCEFULLY keeps NPCs at their scene-defined positions
# It runs continuously to override any other system

var npc_scene_positions: Dictionary = {}
var monitoring: bool = true

func _ready():
    print("\n=== FORCE NPC POSITIONS ACTIVE ===")
    
    # Get scene file to read actual positions
    var scene_path = get_tree().current_scene.scene_file_path
    print("Current scene: ", scene_path)
    
    # Manually define the positions as placed in the scene
    # These are the positions you manually set
    npc_scene_positions = {
        "Dr. Marcus Webb": null,  # Will capture from scene
        "Dr. Sarah Chen": null,
        "Jake Torres": null,
        "Alex Chen": null
    }
    
    # Capture initial positions immediately
    await get_tree().process_frame
    _capture_positions()
    
    # Start monitoring
    set_process(true)

func _capture_positions():
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        if npc_name in npc_scene_positions:
            npc_scene_positions[npc_name] = npc.global_position
            print("Captured position for ", npc_name, ": ", npc.global_position)

func _process(_delta):
    if not monitoring:
        return
        
    # Force NPCs back to their positions every frame
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        if not is_instance_valid(npc):
            continue
            
        var npc_name = npc.get("npc_name") if npc.has_method("get") else npc.name
        if npc_name in npc_scene_positions and npc_scene_positions[npc_name] != null:
            var correct_pos = npc_scene_positions[npc_name]
            
            # Only move if significantly different
            if npc.global_position.distance_to(correct_pos) > 5.0:
                print("FORCING ", npc_name, " back to correct position")
                print("  Was at: ", npc.global_position)
                print("  Moving to: ", correct_pos)
                npc.global_position = correct_pos
                
                # Update all position variables
                if "initial_position" in npc:
                    npc.initial_position = correct_pos
                if "current_target" in npc:
                    npc.current_target = correct_pos
                    
                # Stop any movement
                if "velocity" in npc:
                    npc.velocity = Vector3.ZERO
                if "is_idle" in npc:
                    npc.is_idle = true

func stop_monitoring():
    monitoring = false
    print("=== FORCE NPC POSITIONS STOPPED ===")

# Call this to allow NPCs to move freely
func start_monitoring():
    monitoring = true
    print("=== FORCE NPC POSITIONS RESUMED ===")