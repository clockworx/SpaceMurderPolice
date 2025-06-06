extends Control
class_name PowerGridRepairUI

@export var grid_size: int = 5
@export var tile_size: int = 70

# Pipe types
enum PipeType {
    EMPTY,         # Empty grid cell
    STRAIGHT_H,    # Horizontal straight pipe ─
    STRAIGHT_V,    # Vertical straight pipe │
    CORNER_TL,     # Top-left corner ┌
    CORNER_TR,     # Top-right corner ┐
    CORNER_BL,     # Bottom-left corner └
    CORNER_BR,     # Bottom-right corner ┘
    T_JUNCTION_T,  # T-junction top ┬
    T_JUNCTION_B,  # T-junction bottom ┴
    T_JUNCTION_L,  # T-junction left ├
    T_JUNCTION_R,  # T-junction right ┤
    CROSS,         # Cross junction ┼
    SOURCE,        # Power source
    TARGET         # Power target
}

# Connection directions
enum Direction {
    UP = 1,
    RIGHT = 2,
    DOWN = 4,
    LEFT = 8
}

var grid_tiles: Array[Array] = []
var grid_data: Array[Array] = []
var power_flow: Array[Array] = []
var source_pos: Vector2i = Vector2i(0, 2)  # Middle left
var target_pos: Vector2i = Vector2i(4, 2)  # Middle right
var is_complete: bool = false

# Inventory system
var available_pieces: Dictionary = {}  # PipeType -> count
var inventory_buttons: Dictionary = {}  # PipeType -> Button
var selected_piece_type: PipeType = PipeType.EMPTY
var dragging_piece: Control = null

# Pipe connection mapping
var pipe_connections: Dictionary = {
    PipeType.EMPTY: 0,
    PipeType.STRAIGHT_H: Direction.LEFT | Direction.RIGHT,
    PipeType.STRAIGHT_V: Direction.UP | Direction.DOWN,
    PipeType.CORNER_TL: Direction.DOWN | Direction.RIGHT,
    PipeType.CORNER_TR: Direction.DOWN | Direction.LEFT,
    PipeType.CORNER_BL: Direction.UP | Direction.RIGHT,
    PipeType.CORNER_BR: Direction.UP | Direction.LEFT,
    PipeType.T_JUNCTION_T: Direction.DOWN | Direction.LEFT | Direction.RIGHT,
    PipeType.T_JUNCTION_B: Direction.UP | Direction.LEFT | Direction.RIGHT,
    PipeType.T_JUNCTION_L: Direction.UP | Direction.DOWN | Direction.RIGHT,
    PipeType.T_JUNCTION_R: Direction.UP | Direction.DOWN | Direction.LEFT,
    PipeType.CROSS: Direction.UP | Direction.DOWN | Direction.LEFT | Direction.RIGHT,
    PipeType.SOURCE: Direction.RIGHT,
    PipeType.TARGET: Direction.LEFT
}

# Visual representations  
var pipe_chars: Dictionary = {
    PipeType.EMPTY: " ",
    PipeType.STRAIGHT_H: "━",
    PipeType.STRAIGHT_V: "┃",
    PipeType.CORNER_TL: "┏",
    PipeType.CORNER_TR: "┓",
    PipeType.CORNER_BL: "┗",
    PipeType.CORNER_BR: "┛",
    PipeType.T_JUNCTION_T: "┳",
    PipeType.T_JUNCTION_B: "┻",
    PipeType.T_JUNCTION_L: "┣",
    PipeType.T_JUNCTION_R: "┫",
    PipeType.CROSS: "╋",
    PipeType.SOURCE: "◉",
    PipeType.TARGET: "◎"
}

signal repair_completed()
signal repair_cancelled()

func _ready():
    _setup_grid()
    _generate_puzzle()
    
    # Register with UI manager
    var ui_manager = UIManager.get_instance()
    if ui_manager:
        ui_manager.register_ui_screen(self)
    
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    print("Power grid puzzle initialized. Drag and drop pieces to connect!")

func _setup_grid():
    var grid_container = $Panel/MarginContainer/VBoxContainer/GridContainer
    grid_container.columns = grid_size
    
    # Clear existing children
    for child in grid_container.get_children():
        child.queue_free()
    
    # Initialize arrays
    grid_tiles.clear()
    grid_data.clear()
    power_flow.clear()
    
    # Create grid
    for y in range(grid_size):
        var tile_row = []
        var data_row = []
        var flow_row = []
        
        for x in range(grid_size):
            var tile_panel = Panel.new()
            tile_panel.custom_minimum_size = Vector2(tile_size, tile_size)
            tile_panel.mouse_filter = Control.MOUSE_FILTER_PASS
            
            # Add a label for the pipe character
            var label = Label.new()
            label.add_theme_font_size_override("font_size", 32)
            label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            tile_panel.add_child(label)
            
            # Add drag and drop functionality
            tile_panel.gui_input.connect(_on_grid_tile_input.bind(Vector2i(x, y)))
            
            grid_container.add_child(tile_panel)
            tile_row.append(tile_panel)
            data_row.append(PipeType.EMPTY)
            flow_row.append(false)
        
        grid_tiles.append(tile_row)
        grid_data.append(data_row)
        power_flow.append(flow_row)


func _generate_puzzle():
    # Place source and target
    grid_data[source_pos.y][source_pos.x] = PipeType.SOURCE
    grid_data[target_pos.y][target_pos.x] = PipeType.TARGET
    
    # Simple puzzle with exact pieces needed
    available_pieces.clear()
    
    # Create different puzzles randomly
    var puzzle_type = randi() % 3
    
    match puzzle_type:
        0:  # Straight line
            available_pieces[PipeType.STRAIGHT_H] = 3
        1:  # Simple L-shape
            available_pieces[PipeType.STRAIGHT_H] = 3  # Combined straight pieces
            available_pieces[PipeType.CORNER_BL] = 1
            available_pieces[PipeType.CORNER_BR] = 1
        2:  # S-shape
            available_pieces[PipeType.STRAIGHT_H] = 3  # Combined straight pieces
            available_pieces[PipeType.CORNER_BR] = 1
            available_pieces[PipeType.CORNER_TL] = 1
    
    # Update inventory display
    _update_inventory_display()
    
    # Update grid display
    _update_display()

func _update_inventory_display():
    var inventory_container = $Panel/MarginContainer/VBoxContainer/InventoryContainer
    
    # Clear existing inventory items
    for child in inventory_container.get_children():
        child.queue_free()
    inventory_buttons.clear()
    
    # Add label
    var label = Label.new()
    label.text = "Pieces:"
    label.add_theme_font_size_override("font_size", 16)
    inventory_container.add_child(label)
    
    # Create buttons for each available piece
    for pipe_type in available_pieces:
        if available_pieces[pipe_type] > 0:
            var button = Button.new()
            button.custom_minimum_size = Vector2(60, 60)
            button.add_theme_font_size_override("font_size", 24)
            
            # Show piece and count
            var display_text = ""
            if pipe_type == PipeType.STRAIGHT_H:
                # Show generic straight piece that can be rotated
                display_text = "═"  # Double line to make it more visible
            else:
                display_text = pipe_chars[pipe_type]
            
            if available_pieces[pipe_type] > 1:
                display_text += "×" + str(available_pieces[pipe_type])
            
            button.text = display_text
            
            # Make button draggable
            button.gui_input.connect(_on_inventory_button_input.bind(pipe_type))
            
            inventory_container.add_child(button)
            inventory_buttons[pipe_type] = button

func _on_inventory_button_input(event: InputEvent, pipe_type: PipeType):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                # Start dragging
                _start_dragging(pipe_type)

func _start_dragging(pipe_type: PipeType):
    if available_pieces.get(pipe_type, 0) <= 0:
        return
    
    # Create a visual representation of the dragged piece
    dragging_piece = Label.new()
    if pipe_type == PipeType.STRAIGHT_H:
        dragging_piece.text = "═"  # Double line for visibility
    else:
        dragging_piece.text = pipe_chars[pipe_type]
    dragging_piece.add_theme_font_size_override("font_size", 28)
    dragging_piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dragging_piece.z_index = 10
    dragging_piece.modulate = Color(1, 1, 1, 0.8)
    
    add_child(dragging_piece)
    selected_piece_type = pipe_type

func _on_grid_tile_input(event: InputEvent, grid_pos: Vector2i):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                # Handle click on grid tile
                if dragging_piece and selected_piece_type != PipeType.EMPTY:
                    # Place the piece
                    _place_piece(grid_pos)
                elif grid_data[grid_pos.y][grid_pos.x] not in [PipeType.EMPTY, PipeType.SOURCE, PipeType.TARGET]:
                    # Rotate existing piece
                    _rotate_placed_piece(grid_pos)

func _place_piece(grid_pos: Vector2i):
    # Don't place on source or target
    if grid_pos == source_pos or grid_pos == target_pos:
        return
    
    # If there's already a piece here, return it to inventory
    var current_piece = grid_data[grid_pos.y][grid_pos.x]
    if current_piece != PipeType.EMPTY:
        # Convert STRAIGHT_V back to STRAIGHT_H for inventory
        if current_piece == PipeType.STRAIGHT_V:
            current_piece = PipeType.STRAIGHT_H
        available_pieces[current_piece] = available_pieces.get(current_piece, 0) + 1
    
    # Place the new piece
    grid_data[grid_pos.y][grid_pos.x] = selected_piece_type
    available_pieces[selected_piece_type] -= 1
    
    # Clean up dragging
    if dragging_piece:
        dragging_piece.queue_free()
        dragging_piece = null
    selected_piece_type = PipeType.EMPTY
    
    # Update displays
    _update_inventory_display()
    _update_display()
    _update_power_flow()
    _check_completion()

func _rotate_placed_piece(grid_pos: Vector2i):
    var current_type = grid_data[grid_pos.y][grid_pos.x]
    if current_type in [PipeType.EMPTY, PipeType.SOURCE, PipeType.TARGET]:
        return
    
    grid_data[grid_pos.y][grid_pos.x] = _rotate_pipe(current_type)
    
    _update_display()
    _update_power_flow()
    _check_completion()

func _rotate_pipe(pipe_type: PipeType) -> PipeType:
    match pipe_type:
        PipeType.STRAIGHT_H:
            return PipeType.STRAIGHT_V
        PipeType.STRAIGHT_V:
            return PipeType.STRAIGHT_H
        PipeType.CORNER_TL:
            return PipeType.CORNER_TR
        PipeType.CORNER_TR:
            return PipeType.CORNER_BR
        PipeType.CORNER_BR:
            return PipeType.CORNER_BL
        PipeType.CORNER_BL:
            return PipeType.CORNER_TL
        PipeType.T_JUNCTION_T:
            return PipeType.T_JUNCTION_R
        PipeType.T_JUNCTION_R:
            return PipeType.T_JUNCTION_B
        PipeType.T_JUNCTION_B:
            return PipeType.T_JUNCTION_L
        PipeType.T_JUNCTION_L:
            return PipeType.T_JUNCTION_T
        PipeType.CROSS:
            return PipeType.CROSS
    return pipe_type

func _update_display():
    for y in range(grid_size):
        for x in range(grid_size):
            var tile_panel = grid_tiles[y][x]
            var label = tile_panel.get_child(0) as Label
            var pipe_type = grid_data[y][x]
            
            # Set pipe character
            label.text = pipe_chars.get(pipe_type, " ")
            
            # Color based on position and power
            if Vector2i(x, y) == source_pos:
                label.modulate = Color(0, 1, 0)  # Green source
            elif Vector2i(x, y) == target_pos:
                label.modulate = Color(1, 0.5, 0) if not power_flow[y][x] else Color(0, 1, 0)  # Orange/Green target
            elif power_flow[y][x]:
                label.modulate = Color(0.5, 1, 0.5)  # Light green for powered
            else:
                label.modulate = Color(1, 1, 1)  # White for unpowered

func _update_power_flow():
    # Reset power flow
    for y in range(grid_size):
        for x in range(grid_size):
            power_flow[y][x] = false
    
    # Source is always powered
    power_flow[source_pos.y][source_pos.x] = true
    
    # Start tracing from source
    _trace_power_from(source_pos.x, source_pos.y)
    
    _update_display()

func _trace_power_from(x: int, y: int):
    var pipe_type = grid_data[y][x]
    var connections = pipe_connections.get(pipe_type, 0)
    
    # Check each direction
    if connections & Direction.UP:
        _try_power_neighbor(x, y, x, y - 1, Direction.DOWN)
    if connections & Direction.RIGHT:
        _try_power_neighbor(x, y, x + 1, y, Direction.LEFT)
    if connections & Direction.DOWN:
        _try_power_neighbor(x, y, x, y + 1, Direction.UP)
    if connections & Direction.LEFT:
        _try_power_neighbor(x, y, x - 1, y, Direction.RIGHT)

func _try_power_neighbor(from_x: int, from_y: int, to_x: int, to_y: int, required_dir: int):
    # Check bounds
    if to_x < 0 or to_x >= grid_size or to_y < 0 or to_y >= grid_size:
        return
    
    # Check if already powered
    if power_flow[to_y][to_x]:
        return
    
    # Check if neighbor can receive power from this direction
    var neighbor_type = grid_data[to_y][to_x]
    var neighbor_connections = pipe_connections.get(neighbor_type, 0)
    
    if neighbor_connections & required_dir:
        # Power flows!
        power_flow[to_y][to_x] = true
        # Continue tracing from the neighbor
        _trace_power_from(to_x, to_y)

func _check_completion():
    if power_flow[target_pos.y][target_pos.x] and not is_complete:
        is_complete = true
        print("Power grid puzzle completed!")
        _on_repair_success()

func _on_repair_success():
    var status_label = $Panel/MarginContainer/VBoxContainer/StatusLabel
    status_label.visible = true
    status_label.text = "Power Grid Restored!"
    status_label.modulate = Color(0, 1, 0)
    
    # Disable interaction
    set_process_input(false)
    
    # Wait a moment then close
    await get_tree().create_timer(1.5).timeout
    
    # Unregister from UI manager
    var ui_manager = UIManager.get_instance()
    if ui_manager:
        ui_manager.unregister_ui_screen(self)
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    repair_completed.emit()
    queue_free()

func _on_reset_pressed():
    # Return all placed pieces to inventory
    for y in range(grid_size):
        for x in range(grid_size):
            if Vector2i(x, y) != source_pos and Vector2i(x, y) != target_pos:
                var piece = grid_data[y][x]
                if piece != PipeType.EMPTY:
                    # Convert STRAIGHT_V back to STRAIGHT_H for inventory
                    if piece == PipeType.STRAIGHT_V:
                        piece = PipeType.STRAIGHT_H
                    available_pieces[piece] = available_pieces.get(piece, 0) + 1
                    grid_data[y][x] = PipeType.EMPTY
    
    # Reset completion state
    is_complete = false
    
    # Update displays
    _update_inventory_display()
    _update_display()
    _update_power_flow()
    
    print("Puzzle reset!")

func _on_cancel_pressed():
    # Return all placed pieces to inventory
    for y in range(grid_size):
        for x in range(grid_size):
            if Vector2i(x, y) != source_pos and Vector2i(x, y) != target_pos:
                var piece = grid_data[y][x]
                if piece != PipeType.EMPTY:
                    # Convert STRAIGHT_V back to STRAIGHT_H for inventory
                    if piece == PipeType.STRAIGHT_V:
                        piece = PipeType.STRAIGHT_H
                    available_pieces[piece] = available_pieces.get(piece, 0) + 1
    
    # Unregister from UI manager
    var ui_manager = UIManager.get_instance()
    if ui_manager:
        ui_manager.unregister_ui_screen(self)
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    repair_cancelled.emit()
    queue_free()

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        if dragging_piece:
            # Cancel dragging
            dragging_piece.queue_free()
            dragging_piece = null
            selected_piece_type = PipeType.EMPTY
        else:
            _on_cancel_pressed()
        get_viewport().set_input_as_handled()
    
    # Update dragged piece position
    if dragging_piece and event is InputEventMouseMotion:
        dragging_piece.global_position = event.global_position - Vector2(20, 20)
