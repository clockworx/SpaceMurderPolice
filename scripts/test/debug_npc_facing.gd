extends Node

# Debug script to check NPC facing direction

var debug_timer: float = 0.0
var arrow_meshes: Dictionary = {}

func _ready():
    print("=== NPC Facing Debug ===")
    print("This will show forward vectors for all NPCs")
    
    # Create debug arrows for each NPC
    await get_tree().process_frame
    
    var npcs = get_tree().get_nodes_in_group("npcs")
    for npc in npcs:
        create_debug_arrow(npc)

func create_debug_arrow(npc: Node):
    # Create a long arrow to show forward direction
    var arrow = MeshInstance3D.new()
    arrow.name = "DebugForwardArrow"
    
    # Create arrow mesh (long cylinder)
    var cylinder = CylinderMesh.new()
    cylinder.height = 3.0  # Long arrow
    cylinder.top_radius = 0.05
    cylinder.bottom_radius = 0.05
    
    arrow.mesh = cylinder
    
    # Create bright material
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color.MAGENTA
    mat.emission_enabled = true
    mat.emission = Color.MAGENTA
    mat.emission_energy = 2.0
    arrow.material_override = mat
    
    # Position extending forward from NPC
    arrow.position = Vector3(0, 1.0, 1.5)  # 1.5 units forward
    arrow.rotation_degrees = Vector3(90, 0, 0)
    
    npc.add_child(arrow)
    arrow_meshes[npc] = arrow
    
    # Also add a label showing the forward vector
    var label = Label3D.new()
    label.text = "FORWARD"
    label.position = Vector3(0, 1.0, 3.0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.modulate = Color.MAGENTA
    label.font_size = 24
    npc.add_child(label)

func _process(delta):
    debug_timer += delta
    if debug_timer < 1.0:  # Update every second
        return
    debug_timer = 0.0
    
    # Print NPC forward vectors
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("\n--- NPC Forward Vectors ---")
    for npc in npcs:
        var forward = -npc.transform.basis.z  # Forward is -Z in Godot
        var npc_name = npc.get("npc_name") if npc.get("npc_name") else npc.name
        print(npc_name, " forward: ", forward)
        
        # Check if facing seems backward
        if forward.z > 0.5:
            print("  [WARNING] This NPC seems to be facing backward!")

func _exit_tree():
    # Clean up
    for arrow in arrow_meshes.values():
        if is_instance_valid(arrow):
            arrow.queue_free()