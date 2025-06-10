extends Node3D

# Visual debug for saboteur detection
# Add as child of UnifiedNPC to see detection areas

@onready var npc: UnifiedNPC = get_parent()
var detection_sphere: MeshInstance3D
var vision_cone: MeshInstance3D
var detection_material: StandardMaterial3D
var vision_material: StandardMaterial3D

func _ready():
    if not npc:
        return
    
    # Create detection range sphere
    detection_sphere = MeshInstance3D.new()
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radial_segments = 32
    sphere_mesh.rings = 16
    sphere_mesh.radius = 1.0  # Will be scaled
    sphere_mesh.height = 2.0
    detection_sphere.mesh = sphere_mesh
    
    detection_material = StandardMaterial3D.new()
    detection_material.albedo_color = Color(0, 1, 0, 0.1)
    detection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    detection_material.no_depth_test = true
    detection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    detection_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    detection_sphere.material_override = detection_material
    detection_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    
    add_child(detection_sphere)
    
    # Create vision cone
    vision_cone = MeshInstance3D.new()
    var cone_mesh = CylinderMesh.new()
    cone_mesh.top_radius = 0.0
    cone_mesh.bottom_radius = 1.0
    cone_mesh.height = 1.0
    cone_mesh.radial_segments = 32
    vision_cone.mesh = cone_mesh
    
    vision_material = StandardMaterial3D.new()
    vision_material.albedo_color = Color(1, 1, 0, 0.2)
    vision_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    vision_material.no_depth_test = true
    vision_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    vision_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    vision_cone.material_override = vision_material
    vision_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    
    vision_cone.position.y = 1.5  # Eye height
    vision_cone.rotation.x = deg_to_rad(90)
    
    add_child(vision_cone)

func _process(_delta):
    if not npc or not npc.enable_saboteur_behavior:
        visible = false
        return
    
    visible = npc.show_state_label  # Show when debug is on
    
    # Update detection sphere size
    detection_sphere.scale = Vector3.ONE * npc.detection_range
    
    # Update vision cone size and shape
    var cone_length = npc.detection_range * 0.8
    var cone_radius = tan(deg_to_rad(npc.vision_angle / 2)) * cone_length
    vision_cone.scale = Vector3(cone_radius * 2, cone_length, cone_radius * 2)
    vision_cone.position.z = -cone_length / 2
    
    # Update colors based on state
    match npc.current_state:
        UnifiedNPC.MovementState.INVESTIGATE:
            detection_material.albedo_color = Color(1, 0, 0, 0.2)
            vision_material.albedo_color = Color(1, 0, 0, 0.3)
        UnifiedNPC.MovementState.RETURN_TO_PATROL:
            detection_material.albedo_color = Color(1, 0.5, 0, 0.15)
            vision_material.albedo_color = Color(1, 0.5, 0, 0.25)
        _:
            detection_material.albedo_color = Color(0, 1, 0, 0.1)
            vision_material.albedo_color = Color(1, 1, 0, 0.2)