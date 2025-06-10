@tool
extends NPCBase
class_name WaypointNPC

# This NPC extends NPCBase with waypoint creation functionality for the editor
# All state management, waypoint navigation, and movement features are in NPCBase

@export_group("Waypoint Creation")
@export var auto_create_waypoints: int = 0 : set = create_waypoints
@export var waypoint_color: Color = Color.CYAN
@export var waypoint_size: float = 0.5
@export var show_waypoint_labels: bool = true

func _ready():
    # Call parent ready
    super._ready()
    
    # Enable waypoints by default for this class
    if not Engine.is_editor_hint():
        use_waypoints = true

func create_waypoints(count: int):
    if count <= 0:
        return
        
    if not Engine.is_editor_hint():
        return
    
    # Ensure Waypoints container exists
    var waypoints_container = get_node_or_null("Waypoints")
    if not waypoints_container:
        waypoints_container = Node3D.new()
        waypoints_container.name = "Waypoints"
        add_child(waypoints_container)
        if get_tree():
            waypoints_container.owner = get_tree().edited_scene_root if get_tree().edited_scene_root else owner
    
    # Create waypoint nodes
    var waypoint_script = load("res://scripts/npcs/waypoint_3d.gd")
    
    for i in range(count):
        var waypoint = Node3D.new()
        if waypoint_script:
            waypoint.set_script(waypoint_script)
        
        waypoint.name = "Waypoint" + str(waypoints_container.get_child_count() + 1)
        
        # Position in a circle around the NPC
        var angle = (i / float(count)) * TAU
        var radius = 5.0
        waypoint.position = Vector3(
            cos(angle) * radius,
            0,
            sin(angle) * radius
        )
        
        # Set waypoint properties
        waypoint.set("waypoint_index", waypoints_container.get_child_count())
        waypoint.set("waypoint_color", waypoint_color)
        waypoint.set("waypoint_size", waypoint_size)
        waypoint.set("show_label", show_waypoint_labels)
        waypoint.set("label_text", "W" + str(waypoints_container.get_child_count()))
        
        waypoints_container.add_child(waypoint)
        if get_tree():
            waypoint.owner = get_tree().edited_scene_root if get_tree().edited_scene_root else owner
        
        # Add to waypoint_nodes array
        waypoint_nodes.append(waypoint)
    
    print("Created ", count, " waypoints")
    notify_property_list_changed()
    
    # Reset the creation counter
    auto_create_waypoints = 0

func set_waypoint_nodes(value: Array[Node3D]):
    waypoint_nodes = value
    if Engine.is_editor_hint():
        notify_property_list_changed()
