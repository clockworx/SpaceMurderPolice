extends Node3D

var debug_lines: Array[MeshInstance3D] = []
var line_material: StandardMaterial3D

func _ready():
    # Create material for debug lines
    line_material = StandardMaterial3D.new()
    line_material.vertex_color_use_as_albedo = true
    line_material.albedo_color = Color.RED
    line_material.emission_enabled = true
    line_material.emission = Color.RED
    line_material.emission_energy = 0.5

func draw_line(from: Vector3, to: Vector3, color: Color = Color.RED, duration: float = 1.0):
    if not is_inside_tree():
        return
        
    var line_mesh = BoxMesh.new()
    var distance = from.distance_to(to)
    line_mesh.size = Vector3(0.05, 0.05, distance)
    
    var line_instance = MeshInstance3D.new()
    line_instance.mesh = line_mesh
    
    # Create unique material for this line
    var mat = line_material.duplicate()
    mat.albedo_color = color
    mat.emission = color
    line_instance.material_override = mat
    
    # Add to scene first
    add_child(line_instance)
    debug_lines.append(line_instance)
    
    # Then position and rotate
    line_instance.global_position = (from + to) / 2.0
    line_instance.look_at_from_position(line_instance.global_position, to, Vector3.UP)

func clear_all_lines():
    for line in debug_lines:
        if line and is_instance_valid(line):
            line.queue_free()
    debug_lines.clear()
