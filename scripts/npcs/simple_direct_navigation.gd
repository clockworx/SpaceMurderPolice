extends Node
class_name SimpleDirectNavigation

# Ultra-simple navigation that just moves between positions

signal navigation_completed()
signal waypoint_reached(waypoint_name: String)

var character: CharacterBody3D
var current_path: Array = []
var current_index: int = 0
var is_active: bool = false

var movement_speed: float = 3.5
var reach_distance: float = 1.0

func _init(body: CharacterBody3D):
    character = body
    set_physics_process(false)

func navigate_to_room(room_name: String) -> bool:
    print("\n[SIMPLE NAV] Navigating to ", room_name)
    
    # Clear any existing navigation
    stop_navigation()
    
    # Build simple direct paths
    current_path.clear()
    var start_pos = character.global_position
    
    # Define key positions for each room (adjust these based on your level)
    match room_name:
        "FullTour":
            print("  Building full station tour...")
            current_path = [
                # Start in lab
                Vector3(-1.3, 0, 8.8),      # Lab center
                Vector3(3.5, 0, 8.0),       # Near lab door
                Vector3(5.6, 0, 7.8),       # Lab exit
                
                # To Medical Bay
                Vector3(10, 0, 4),          # Hallway
                Vector3(20, 0, 4),          # Hallway
                Vector3(30, 0, 4),          # Hallway
                Vector3(37.9, 0, 4.0),      # Medical door
                Vector3(37.9, 0, 0.0),      # Inside medical
                Vector3(42.6, 0, -2.5),     # Medical center
                
                # Exit Medical Bay - same path reversed
                Vector3(37.9, 0, 0.0),      # Back to door
                Vector3(37.9, 0, 4.0),      # Outside door
                
                # To Security
                Vector3(30, 0, 4),          # Hallway
                Vector3(20, 0, 4),          # Hallway
                Vector3(10, 0, 4),          # Hallway
                Vector3(0, 0, 4),           # Central
                Vector3(-10, 0, 4),         # West hallway
                Vector3(-13.0, 0, 4.1),     # Security door
                Vector3(-13.0, 0, 8.0),     # Inside security
                Vector3(-13.9, 0, 9.9),     # Security center
                
                # To Engineering (same room as security)
                Vector3(-30, 0, 8),         # Move west in room
                Vector3(-45.3, 0, 11.2),    # Engineering center
                
                # Exit back through Security door
                Vector3(-30, 0, 8),         # Back east
                Vector3(-13.0, 0, 8.0),     # To door
                Vector3(-13.0, 0, 4.1),     # Outside door
                
                # To Crew Quarters
                Vector3(0, 0, 4),           # Central
                Vector3(4.2, 0, -0.6),      # South turn
                Vector3(5.5, 0, -2.8),      # South hallway
                Vector3(5.9, 0, -10),       # Mid hallway
                Vector3(5.9, 0, -20),       # Near crew
                Vector3(5.9, 0, -24.0),     # Crew door
                Vector3(1.9, 0, -24.0),     # Inside crew
                Vector3(-5.4, 0, -28.5),    # Crew center
                
                # Exit Crew Quarters
                Vector3(1.9, 0, -24.0),     # Back to door
                Vector3(5.9, 0, -24.0),     # Outside door
                
                # To Cafeteria
                Vector3(5.9, 0, -20),       # Hallway
                Vector3(5.9, 0, -10),       # Hallway
                Vector3(5.5, 0, -2.8),      # Hallway
                Vector3(4.2, 0, -0.6),      # Turn
                Vector3(0, 0, 4),           # Central
                Vector3(5.6, 0, 7.8),       # Lab area
                Vector3(6.0, 0, 10),        # Cafeteria approach
                Vector3(6.0, 0, 16.4),      # Cafeteria door
                Vector3(6.0, 0, 12.4),      # Inside cafeteria
                Vector3(6.0, 0, 3.7),       # Cafeteria center
                
                # Exit Cafeteria
                Vector3(6.0, 0, 12.4),      # Back to door
                Vector3(6.0, 0, 16.4),      # Outside door
                
                # Return to Lab
                Vector3(6.0, 0, 10),        # Approach
                Vector3(5.6, 0, 7.8),       # Lab door
                Vector3(3.5, 0, 8.0),       # Inside lab
                Vector3(-1.3, 0, 8.8)       # Lab center
            ]
            
        "MedicalBay_Waypoint":
            current_path = [
                Vector3(3.5, 0, 8.0),
                Vector3(5.6, 0, 7.8),
                Vector3(15, 0, 4),
                Vector3(30, 0, 4),
                Vector3(37.9, 0, 4.0),
                Vector3(37.9, 0, 0.0),
                Vector3(42.6, 0, -2.5)
            ]
            
        "Security_Waypoint":
            current_path = [
                Vector3(3.5, 0, 8.0),
                Vector3(5.6, 0, 7.8),
                Vector3(0, 0, 4),
                Vector3(-10, 0, 4),
                Vector3(-13.0, 0, 4.1),
                Vector3(-13.0, 0, 8.0),
                Vector3(-13.9, 0, 9.9)
            ]
            
        "Engineering_Waypoint":
            current_path = [
                Vector3(3.5, 0, 8.0),
                Vector3(5.6, 0, 7.8),
                Vector3(0, 0, 4),
                Vector3(-10, 0, 4),
                Vector3(-13.0, 0, 4.1),
                Vector3(-13.0, 0, 8.0),
                Vector3(-30, 0, 8),
                Vector3(-45.3, 0, 11.2)
            ]
            
        _:
            print("  Unknown destination: ", room_name)
            return false
    
    print("  Path has ", current_path.size(), " waypoints")
    
    # Start navigation
    current_index = 0
    is_active = true
    set_physics_process(true)
    
    return true

func stop_navigation():
    is_active = false
    set_physics_process(false)
    character.velocity = Vector3.ZERO

func _physics_process(delta: float):
    if not is_active or not character:
        return
    
    # Check if we completed the path
    if current_index >= current_path.size():
        print("[SIMPLE NAV] Navigation complete!")
        stop_navigation()
        navigation_completed.emit()
        return
    
    # Get current target
    var current_target = current_path[current_index]
    var distance = character.global_position.distance_to(current_target)
    
    # Check if reached waypoint
    if distance <= reach_distance:
        print("  [", current_index + 1, "/", current_path.size(), "] Reached waypoint")
        current_index += 1
        return
    
    # Move towards target
    var direction = (current_target - character.global_position).normalized()
    direction.y = 0
    
    character.velocity = direction * movement_speed
    if not character.is_on_floor():
        character.velocity.y -= 9.8 * delta
    
    character.move_and_slide()
    
    # Rotate to face movement
    if direction.length() > 0.1:
        character.look_at(character.global_position + direction, Vector3.UP)
        character.rotation.x = 0

func is_navigating_active() -> bool:
    return is_active