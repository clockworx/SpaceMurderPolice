extends Node
class_name UIManager

# Singleton UI manager to handle mouse mode and UI state consistently
static var instance: UIManager

enum MouseMode {
    WORLD_INTERACTION,  # Captured mouse, crosshair visible
    UI_INTERACTION      # Visible mouse, crosshair hidden
}

var current_mode: MouseMode = MouseMode.WORLD_INTERACTION
var active_ui_screens: Array[Control] = []

signal mouse_mode_changed(new_mode: MouseMode)
signal ui_state_changed(is_ui_active: bool)

func _ready():
    if instance == null:
        instance = self
        add_to_group("ui_manager")
        print("UI Manager initialized")
    else:
        queue_free()

static func get_instance() -> UIManager:
    if instance == null:
        var tree = Engine.get_main_loop() as SceneTree
        if tree:
            instance = tree.get_first_node_in_group("ui_manager")
            if instance == null:
                # Create instance if none exists
                instance = UIManager.new()
                tree.root.add_child(instance)
    return instance

func set_world_interaction_mode():
    """Switch to world interaction mode - crosshair visible, mouse captured"""
    if current_mode == MouseMode.WORLD_INTERACTION:
        return
        
    current_mode = MouseMode.WORLD_INTERACTION
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    print("UI Manager: Set mouse mode to CAPTURED")
    
    # Show crosshair and hide cursor
    _set_crosshair_visible(true)
    
    mouse_mode_changed.emit(current_mode)
    print("UI Manager: Switched to WORLD_INTERACTION mode")

func set_ui_interaction_mode():
    """Switch to UI interaction mode - mouse visible, crosshair hidden"""
    if current_mode == MouseMode.UI_INTERACTION:
        return
        
    current_mode = MouseMode.UI_INTERACTION
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    print("UI Manager: Set mouse mode to VISIBLE")
    
    # Hide crosshair and show cursor
    _set_crosshair_visible(false)
    
    mouse_mode_changed.emit(current_mode)
    print("UI Manager: Switched to UI_INTERACTION mode")

func register_ui_screen(ui_control: Control):
    """Register a UI screen that requires mouse interaction"""
    print("UI Manager: Registering UI screen: ", ui_control.name if ui_control else "null")
    if ui_control not in active_ui_screens:
        active_ui_screens.append(ui_control)
        
    # Switch to UI mode when first UI screen opens
    if active_ui_screens.size() == 1:
        print("UI Manager: First UI screen opened, switching to UI mode")
        set_ui_interaction_mode()
        ui_state_changed.emit(true)
        print("UI Manager: Emitted ui_state_changed(true)")
    
    # Connect to the UI's cleanup
    if ui_control.has_signal("tree_exiting"):
        ui_control.tree_exiting.connect(_on_ui_screen_closed.bind(ui_control))

func unregister_ui_screen(ui_control: Control):
    """Unregister a UI screen"""
    print("UI Manager: Unregistering UI screen: ", ui_control.name if ui_control else "null")
    if ui_control in active_ui_screens:
        active_ui_screens.erase(ui_control)
    
    # Switch back to world mode when no UI screens are active
    if active_ui_screens.size() == 0:
        print("UI Manager: Last UI screen closed, switching to world mode")
        set_world_interaction_mode()
        ui_state_changed.emit(false)
        print("UI Manager: Emitted ui_state_changed(false)")

func _on_ui_screen_closed(ui_control: Control):
    unregister_ui_screen(ui_control)

func _set_crosshair_visible(visible: bool):
    """Show/hide the crosshair UI"""
    var player = get_tree().get_first_node_in_group("player")
    if player:
        var player_ui = player.get_node_or_null("UILayer/PlayerUI")
        if player_ui:
            var crosshair = player_ui.get_node_or_null("Crosshair")
            if crosshair:
                crosshair.visible = visible

func is_in_ui_mode() -> bool:
    return current_mode == MouseMode.UI_INTERACTION

func force_world_mode():
    """Force world mode regardless of active UI screens (for emergency situations)"""
    active_ui_screens.clear()
    set_world_interaction_mode()
    ui_state_changed.emit(false)

func _input(event):
    # Global escape handler - closes UI screens and returns to world mode
    if event.is_action_pressed("ui_cancel") and current_mode == MouseMode.UI_INTERACTION:
        if active_ui_screens.size() > 0:
            # Close the most recent UI screen
            var latest_ui = active_ui_screens[-1]
            if latest_ui.has_method("close_ui"):
                latest_ui.close_ui()
            else:
                latest_ui.queue_free()
