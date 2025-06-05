extends Node

func _ready():
    add_to_group("game_manager")
    
    # Setup navigation first (deferred to avoid busy parent error)
    call_deferred("_setup_navigation")
    
    # Wait for scene to be ready
    await get_tree().process_frame
    
    # Ensure relationship manager exists
    var rel_manager = get_tree().get_first_node_in_group("relationship_manager")
    if not rel_manager:
        rel_manager = RelationshipManager.new()
        get_tree().root.add_child(rel_manager)
        print("Game Manager: Created RelationshipManager")
    
    # Create day/night manager
    var day_night = get_tree().get_first_node_in_group("day_night_manager")
    if not day_night:
        day_night = DayNightManager.new()
        add_child(day_night)
        print("Game Manager: Created DayNightManager")
    else:
        print("Game Manager: DayNightManager already exists")
    
    # Find player and UI nodes
    var player = get_node_or_null("../Player")
    var player_ui = player.get_node_or_null("UILayer/PlayerUI") if player else null
    
    if not player:
        push_error("Game Manager: Player node not found!")
        return
        
    if not player_ui:
        push_error("Game Manager: PlayerUI node not found!")
        return
    
    # Connect interaction signals
    if player.has_signal("interactable_detected") and player.has_signal("interactable_lost"):
        player.interactable_detected.connect(_on_interactable_detected.bind(player_ui))
        player.interactable_lost.connect(_on_interactable_lost.bind(player_ui))
        print("Game Manager: Connected player interaction signals")
    else:
        push_error("Game Manager: Player missing interaction signals!")

func _on_interactable_detected(interactable, ui):
    print("Interactable detected: ", interactable)
    if interactable.has_method("interact"):
        var prompt = interactable.get_interaction_prompt() if interactable.has_method("get_interaction_prompt") else "Press [E] to interact"
        print("Showing prompt: ", prompt)
        ui.show_interaction_prompt(prompt)

func _on_interactable_lost(ui):
    print("Interactable lost")
    ui.hide_interaction_prompt()

func on_player_caught():
    # Called when Riley catches the player
    print("GAME OVER: Player caught by Riley!")
    
    # Pause the game
    get_tree().paused = true
    
    # Create game over screen
    var game_over = AcceptDialog.new()
    game_over.title = "CAUGHT!"
    game_over.dialog_text = "Riley caught you!\n\n'I knew you were up to something. You won't get away with this!'\n\nYou have been detained by station security."
    game_over.add_theme_font_size_override("font_size", 20)
    game_over.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    
    # Add to UI
    var ui_layer = get_node("/root/" + get_tree().current_scene.name + "/Player/UILayer")
    if ui_layer:
        ui_layer.add_child(game_over)
        game_over.popup_centered(Vector2(600, 300))
        game_over.confirmed.connect(_restart_game)

func _restart_game():
    get_tree().paused = false
    get_tree().reload_current_scene()

func _setup_navigation():
    # Check if NavigationRegion3D already exists
    var existing_nav = get_tree().get_first_node_in_group("navigation_region")
    if existing_nav:
        print("Game Manager: Navigation already exists")
        return
    
    # Create NavigationRegion3D for the level
    var nav_region = NavigationRegion3D.new()
    nav_region.name = "NavigationRegion3D"
    nav_region.add_to_group("navigation_region")
    get_tree().current_scene.add_child.call_deferred(nav_region)
    
    # Create a simple navigation mesh covering main areas
    var nav_mesh = NavigationMesh.new()
    nav_mesh.cell_size = 0.25
    nav_mesh.cell_height = 0.25
    nav_mesh.agent_height = 2.0
    nav_mesh.agent_radius = 0.6
    nav_mesh.agent_max_climb = 0.3
    nav_mesh.agent_max_slope = 45.0
    
    # We'll use a pre-baked approach since runtime baking is limited
    # Create vertices for navigation areas
    var vertices = PackedVector3Array()
    
    # Main hallway navigation mesh (simplified box)
    for x in range(-3, 4):
        for z in range(-30, 31, 5):
            vertices.append(Vector3(x, 0.1, z))
    
    nav_mesh.vertices = vertices
    
    # Create a simple polygon covering the main hallway
    # This is a simplified approach - in production you'd bake this in editor
    nav_region.navigation_mesh = nav_mesh
    
    print("Game Manager: Created navigation mesh for level")
