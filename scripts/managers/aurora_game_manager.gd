extends Node

func _ready():
    add_to_group("game_manager")
    
    print("\n=== AURORA GAME MANAGER STARTING ===")
    print("Scene root: ", get_tree().current_scene.name)
    
    # FIRST: Fix NPC positions immediately
    var immediate_fix = load("res://scripts/managers/immediate_npc_fix.gd")
    if immediate_fix:
        var fixer = immediate_fix.new()
        add_child(fixer)
    
    # DISABLED: Force position was causing NPCs to get stuck
    # var force_pos_script = load("res://scripts/managers/force_npc_positions.gd")
    # if force_pos_script:
    #     var force_pos = force_pos_script.new()
    #     add_child(force_pos)
    
    # DISABLE navigation mesh to stop errors
    var disable_nav_script = load("res://scripts/managers/disable_navigation_mesh.gd")
    if disable_nav_script:
        var disable_nav = disable_nav_script.new()
        add_child(disable_nav)
    
    # Fix NPC positions if they're outside station
    var fix_pos_script = load("res://scripts/managers/fix_npc_positions.gd")
    if fix_pos_script:
        var fix_pos = fix_pos_script.new()
        add_child(fix_pos)
        
    # DISABLED: Navigation is causing errors, using simple movement instead
    # var enable_nav_script = load("res://scripts/managers/enable_npc_navigation.gd")
    # if enable_nav_script:
    #     var enable_nav = enable_nav_script.new()
    #     add_child(enable_nav)
    
    # Run comprehensive NPC debug
    var debug_script = load("res://scripts/test/npc_debug.gd")
    if debug_script:
        var debugger = debug_script.new()
        add_child(debugger)
    
    # Apply NPC navigation fix
    var nav_fix_script = load("res://scripts/managers/npc_navigation_fix.gd")
    if nav_fix_script:
        var nav_fix = nav_fix_script.new()
        add_child(nav_fix)
        
    # DISABLED: These were causing conflicts
    # var comp_fix_script = load("res://scripts/managers/comprehensive_npc_fix.gd")
    # if comp_fix_script:
    #     var comp_fix = comp_fix_script.new()
    #     add_child(comp_fix)
        
    # var no_reposition_script = load("res://scripts/managers/disable_npc_repositioning.gd")
    # if no_reposition_script:
    #     var no_reposition = no_reposition_script.new()
    #     add_child(no_reposition)
    
    # Debug NPCs before anything else
    call_deferred("_debug_npcs_initial")
    
    # Add periodic debug check for NPCs
    var timer = Timer.new()
    timer.wait_time = 5.0
    timer.timeout.connect(_debug_npc_positions)
    add_child(timer)
    timer.start()
    
    # Create navigation manager first
    var nav_manager = get_tree().get_first_node_in_group("navigation_manager")
    if not nav_manager:
        var nav_manager_script = load("res://scripts/managers/navigation_manager.gd")
        if nav_manager_script:
            nav_manager = nav_manager_script.new()
            nav_manager.name = "NavigationManager"
            add_child(nav_manager)
            print("Game Manager: Created NavigationManager")
    
    # Create advanced navigation manager
    var adv_nav_manager = get_tree().get_first_node_in_group("advanced_navigation_manager")
    if not adv_nav_manager:
        var adv_nav_script = load("res://scripts/managers/advanced_navigation_manager.gd")
        if adv_nav_script:
            adv_nav_manager = adv_nav_script.new()
            adv_nav_manager.name = "AdvancedNavigationManager"
            add_child(adv_nav_manager)
            print("Game Manager: Created AdvancedNavigationManager")
    
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
    
    # Create sabotage system manager
    var sabotage_manager = get_tree().get_first_node_in_group("sabotage_manager")
    if not sabotage_manager:
        sabotage_manager = SabotageSystemManager.new()
        add_child(sabotage_manager)
        print("Game Manager: Created SabotageSystemManager")
    else:
        print("Game Manager: SabotageSystemManager already exists")
    
    # Setup saboteur character modes
    call_deferred("_setup_saboteur_character_modes")
    
    # Initialize NPC movement after a delay
    call_deferred("_initialize_npc_movement")
    
    # Find player and UI nodes
    var player = get_tree().get_first_node_in_group("player")
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
    # Called when the saboteur catches the player
    print("GAME OVER: Player caught by the saboteur!")
    
    # Pause the game
    get_tree().paused = true
    
    # Create game over screen
    var game_over = AcceptDialog.new()
    game_over.title = "CAUGHT!"
    game_over.dialog_text = "The saboteur caught you!\n\n'You know too much. I can't let you leave this station alive.'\n\nYour investigation has come to a deadly end."
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

func _debug_npcs_initial():
    print("\n=== INITIAL NPC DEBUG ===")
    
    # Check NPCs parent node
    var npcs_parent = get_node_or_null("../NPCs")
    if npcs_parent:
        print("NPCs parent found with ", npcs_parent.get_child_count(), " children:")
        for child in npcs_parent.get_children():
            print("  - ", child.name, ":")
            print("    Class: ", child.get_class())
            print("    Script: ", child.get_script())
            print("    Visible: ", child.visible)
            print("    Position: ", child.position)
            print("    Global Position: ", child.global_position)
            if child.has_method("get_property_list"):
                for prop in child.get_property_list():
                    if prop.name == "npc_name":
                        print("    NPC Name: ", child.get("npc_name"))
    else:
        print("ERROR: NPCs parent node not found!")
    
    # Check nodes in npcs group
    var npcs_in_group = get_tree().get_nodes_in_group("npcs")
    print("\nNodes in 'npcs' group: ", npcs_in_group.size())
    for npc in npcs_in_group:
        print("  - ", npc.name, " (", npc.get("npc_name") if npc.has_method("get") else "?", ")")
    
    print("=== END INITIAL DEBUG ===")

func _debug_npc_positions():
    print("\n=== NPC POSITION CHECK ===")
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("Total NPCs in group: ", npcs.size())
    
    for npc in npcs:
        var room = ""
        var pos = npc.global_position
        
        # Determine which room they're in based on position
        if pos.z > 7 and pos.z < 13:
            if pos.x < -5:
                room = "Laboratory 3"
            elif pos.x > 5:
                room = "Medical Bay"
            else:
                room = "Hallway near Lab/Medical"
        elif pos.z > 2 and pos.z < 8:
            if pos.x > 5:
                room = "Medical Bay area"
            else:
                room = "Hallway center"
        elif pos.z > -8 and pos.z < -2:
            if pos.x < -5:
                room = "Security Office area"
            else:
                room = "Hallway"
        elif pos.z > -13 and pos.z < -7:
            if pos.x > 5:
                room = "Engineering area"
            else:
                room = "Hallway"
        elif pos.z > -18 and pos.z < -12:
            if pos.x < -5:
                room = "Crew Quarters area"
            else:
                room = "Hallway"
        elif pos.z > -23 and pos.z < -17:
            if pos.x > 5:
                room = "Cafeteria area"
            else:
                room = "Hallway"
        else:
            room = "Unknown/Hallway"
        
        var npc_name = npc.get("npc_name") if npc.get("npc_name") else "Unknown"
        print("  ", npc_name, " - Pos: ", pos, " - Room: ", room, " - Visible: ", npc.visible)
    
    print("=== END POSITION CHECK ===")

func _setup_navigation():
    # DISABLED: User has added NavigationRegion3D manually
    print("Game Manager: Skipping navigation setup - using scene NavigationRegion3D")
    return
    
    # Check if NavigationRegion3D already exists
    var existing_nav = get_tree().get_first_node_in_group("navigation_region")
    if existing_nav:
        print("Game Manager: Navigation already exists")
        return
    
    # Create NavigationRegion3D for the level
    var nav_region = NavigationRegion3D.new()
    nav_region.name = "NavigationRegion3D"
    nav_region.add_to_group("navigation_region")
    get_tree().current_scene.add_child(nav_region)
    
    # Create comprehensive navigation mesh for the entire station
    var nav_mesh = NavigationMesh.new()
    
    # Optimal settings for indoor space station (matching default cell size)
    nav_mesh.cell_size = 0.25
    nav_mesh.cell_height = 0.25
    nav_mesh.agent_height = 2.0
    nav_mesh.agent_radius = 0.4
    nav_mesh.agent_max_climb = 0.3
    nav_mesh.agent_max_slope = 45.0
    nav_mesh.region_min_size = 2
    nav_mesh.region_merge_size = 20
    nav_mesh.edge_max_length = 12.0
    nav_mesh.edge_max_error = 1.3
    nav_mesh.vertices_per_polygon = 6
    nav_mesh.detail_sample_distance = 6.0
    nav_mesh.detail_sample_max_error = 1.0
    
    # Set geometry parsing to use static colliders
    nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
    nav_mesh.geometry_collision_mask = 1  # Environment layer
    
    # Create navigation polygons for each area
    var vertices = PackedVector3Array()
    var polygons = []
    
    # Define navigation areas with proper connectivity
    var areas = [
        # Main hallway (entire length)
        {"min": Vector2(-2, -25), "max": Vector2(2, 20)},
        # Laboratory 3
        {"min": Vector2(-12, 5), "max": Vector2(-2.5, 15)},
        # Medical Bay
        {"min": Vector2(2.5, 0), "max": Vector2(12, 10)},
        # Security Office
        {"min": Vector2(-12, -9), "max": Vector2(-2.5, 0)},
        # Engineering
        {"min": Vector2(2.5, -15), "max": Vector2(12, -5)},
        # Crew Quarters
        {"min": Vector2(-12, -19), "max": Vector2(-2.5, -10)},
        # Cafeteria
        {"min": Vector2(2.5, -25), "max": Vector2(12, -16)}
    ]
    
    # Build navigation mesh vertices
    for area in areas:
        var min_x = area.min.x
        var max_x = area.max.x
        var min_z = area.min.y
        var max_z = area.max.y
        
        # Add vertices for this area (clockwise)
        var base_idx = vertices.size()
        vertices.append(Vector3(min_x, 0.1, min_z))  # 0: Bottom-left
        vertices.append(Vector3(max_x, 0.1, min_z))  # 1: Bottom-right
        vertices.append(Vector3(max_x, 0.1, max_z))  # 2: Top-right
        vertices.append(Vector3(min_x, 0.1, max_z))  # 3: Top-left
        
        # Create polygon (counter-clockwise for Godot)
        polygons.append([base_idx + 3, base_idx + 2, base_idx + 1, base_idx + 0])
    
    # Apply vertices
    nav_mesh.vertices = vertices
    
    # Add polygons
    nav_mesh.clear_polygons()
    for polygon in polygons:
        nav_mesh.add_polygon(PackedInt32Array(polygon))
    
    # Set the navigation mesh
    nav_region.navigation_mesh = nav_mesh
    
    # Force navigation server update
    NavigationServer3D.region_set_navigation_mesh(
        nav_region.get_rid(),
        nav_mesh
    )
    
    print("Game Manager: Created comprehensive navigation mesh for station")

func _setup_saboteur_character_modes():
    print("Game Manager: Setting up saboteur character modes...")
    
    # Find all NPCs that can be saboteurs
    var npcs = get_tree().get_nodes_in_group("npcs")
    var saboteur_npc = null
    
    for npc in npcs:
        if npc.can_be_saboteur:
            saboteur_npc = npc
            break
    
    if not saboteur_npc:
        print("Game Manager: No saboteur NPC found!")
        return
    
    print("Game Manager: Found saboteur NPC at ", saboteur_npc.get_path())
    
    # Check if SaboteurPatrolAI already exists
    var patrol_ai = saboteur_npc.get_node_or_null("SaboteurPatrolAI")
    if not patrol_ai:
        # Create and add SaboteurPatrolAI (but start it as inactive)
        patrol_ai = Node.new()
        patrol_ai.name = "SaboteurPatrolAI"
        patrol_ai.set_script(load("res://scripts/npcs/saboteur_patrol_ai.gd"))
        saboteur_npc.add_child(patrol_ai)
        print("Game Manager: Added SaboteurPatrolAI to saboteur NPC")
        
        # Wait for it to initialize then deactivate it
        await get_tree().process_frame
        if patrol_ai.has_method("set_active"):
            patrol_ai.set_active(false)
            print("Game Manager: Deactivated SaboteurPatrolAI for normal mode")
    else:
        print("Game Manager: SaboteurPatrolAI already exists")
        # Make sure it's inactive for normal mode
        if patrol_ai.has_method("set_active"):
            patrol_ai.set_active(false)
    
    # Check if SaboteurCharacterModes already exists
    var character_modes = saboteur_npc.get_node_or_null("SaboteurCharacterModes")
    if not character_modes:
        # Create and add SaboteurCharacterModes
        character_modes = Node.new()
        character_modes.name = "SaboteurCharacterModes"
        character_modes.set_script(load("res://scripts/npcs/saboteur_character_modes.gd"))
        saboteur_npc.add_child(character_modes)
        print("Game Manager: Added SaboteurCharacterModes to saboteur NPC")
    else:
        print("Game Manager: SaboteurCharacterModes already exists")
    
    # Ensure NPC is marked as saboteur
    saboteur_npc.can_be_saboteur = true
    
    print("Game Manager: Saboteur setup complete - PatrolAI: ", patrol_ai != null, ", CharacterModes: ", character_modes != null)

func _initialize_npc_movement():
    # Wait for NPCs to be positioned
    await get_tree().create_timer(1.0).timeout
    
    print("Game Manager: Initializing NPC movement...")
    
    # Debug: List all NPCs in the scene
    print("Game Manager: Searching for NPCs...")
    var npcs_parent = get_node_or_null("../NPCs")
    if npcs_parent:
        print("Game Manager: Found NPCs parent node with ", npcs_parent.get_child_count(), " children")
        for child in npcs_parent.get_children():
            print("  - Child: ", child.name, " (visible: ", child.visible, ", position: ", child.global_position, ")")
    else:
        print("Game Manager: NPCs parent node not found!")
    
    var npcs = get_tree().get_nodes_in_group("npcs")
    print("Game Manager: Found ", npcs.size(), " NPCs in 'npcs' group")
    
    for npc in npcs:
        print("Game Manager: NPC ", npc.npc_name, " - visible: ", npc.visible, ", position: ", npc.global_position)
        if npc.has_method("_choose_new_target"):
            # Force NPCs to start moving
            npc.idle_timer = 0.1
            print("Game Manager: Triggered movement for " + npc.npc_name)
