extends Resource
class_name RoomNavigationConfig

# Room navigation configuration
# Makes it easy to add new rooms without modifying navigation code

static func get_room_config() -> Dictionary:
    return {
        "Security_Waypoint": {
            "exit_door": "Laboratory 3",
            "exit_target": Vector3(6.0, 0, 4.0),
            "exit_fallback": [Vector3(2.0, 0, 9.0), Vector3(5.5, 0, 8.1)],
            "hallway_path": [
                Vector3(6.0, 0, 4.0),     # Hallway position
                Vector3(0.0, 0, 4.0),     # Center hallway
                Vector3(-10.0, 0, 4.0),   # Near security
            ],
            "enter_door": "Security Office",
            "approach_from": Vector3(-10.0, 0, 4.0),
            "room_center": Vector3(-12.3, 0, 8.0),
            "enter_fallback": [Vector3(-12.95, 0, 5.9), Vector3(-12.95, 0, 7.9)]
        },
        
        "MedicalBay_Waypoint": {
            "exit_door": "Laboratory 3",
            "exit_target": Vector3(6.0, 0, 4.0),
            "exit_fallback": [Vector3(2.0, 0, 9.0), Vector3(5.5, 0, 8.1)],
            "hallway_path": [
                Vector3(6.0, 0, 4.0),     # Hallway position
                Vector3(10.0, 0, 4.0),    # Move east
                Vector3(15.0, 0, 4.0),    # East hallway
                Vector3(25.0, 0, 4.0),    # Stay in center
                Vector3(30.0, 0, 4.0),    # Continue center
                Vector3(35.0, 0, 3.5),    # Start gentle turn
            ],
            "enter_door": "Medical Bay",
            "approach_from": Vector3(35.0, 0, 3.5),
            "room_center": Vector3(40.2, 0, -2.3),
            "enter_fallback": [Vector3(38.0, 0, 1.96), Vector3(38.0, 0, -0.04)]
        },
        
        "Engineering_Waypoint": {
            "exit_door": "Laboratory 3",
            "exit_target": Vector3(6.0, 0, 4.0),
            "exit_fallback": [Vector3(2.0, 0, 9.0), Vector3(5.5, 0, 8.1)],
            "hallway_path": [
                Vector3(6.0, 0, 4.0),     # Hallway position
                Vector3(0.0, 0, 4.0),     # Center hallway
                Vector3(-12.0, 0, 4.0),   # Near engineering
            ],
            "enter_door": "Engineering",
            "approach_from": Vector3(-12.0, 0, 4.0),
            "room_center": Vector3(-13.0, 0, 10.0),
            "enter_fallback": [Vector3(-12.95, 0, 5.89), Vector3(-12.95, 0, 7.9)]
        },
        
        "CrewQuarters_Waypoint": {
            "exit_door": "Laboratory 3",
            "exit_target": Vector3(6.0, 0, 4.0),
            "exit_fallback": [Vector3(2.0, 0, 9.0), Vector3(5.5, 0, 8.1)],
            "hallway_path": [
                Vector3(6.0, 0, 4.0),     # Hallway position
                Vector3(0.0, 0, 4.0),     # Center hallway
                Vector3(0.0, 0, 0.0),     # Move south to avoid pillar
                Vector3(0.0, 0, -4.0),    # Continue south
                Vector3(3.87, 0, -4.0),   # Move east
                Vector3(3.87, 0, -10.0),  # Move south
                Vector3(3.87, 0, -20.0),  # Continue south
            ],
            "enter_door": "Crew Quarters",
            "approach_from": Vector3(3.87, 0, -20.0),
            "room_center": Vector3(4.0, 0, -28.0),
            "enter_fallback": [Vector3(3.87, 0, -24.0), Vector3(3.87, 0, -26.0)]
        },
        
        "Cafeteria_Waypoint": {
            "exit_door": "Laboratory 3",
            "exit_target": Vector3(6.0, 0, 4.0),
            "exit_fallback": [Vector3(2.0, 0, 9.0), Vector3(5.5, 0, 8.1)],
            "hallway_path": [
                Vector3(6.0, 0, 4.0),     # Hallway position
                Vector3(6.0, 0, 8.0),     # Move north
                Vector3(6.0, 0, 10.0),    # Continue north
            ],
            "enter_door": "Cafeteria",
            "approach_from": Vector3(6.0, 0, 10.0),
            "room_center": Vector3(6.0, 0, 18.0),
            "enter_fallback": [Vector3(6.02, 0, 14.4), Vector3(6.02, 0, 16.4)]
        },
        
        "Laboratory_Waypoint": {
            # Special case - no doors needed
            "room_center": Vector3(0.0, 0, 10.0)
        }
    }

static func get_door_naming_patterns() -> Array:
    # Add new naming patterns here as needed
    return [
        {"entry": "Door_%sEntry", "exit": "Door_%sExit"},
        {"entry": "Door_%s_Entry", "exit": "Door_%s_Exit"},
        {"entry": "%s_Entry", "exit": "%s_Exit"},
        {"entry": "%sDoorEntry", "exit": "%sDoorExit"},
        {"entry": "%s_Door_Entry", "exit": "%s_Door_Exit"},
        {"entry": "%s_Enter", "exit": "%s_Exit"},
        {"entry": "%s_In", "exit": "%s_Out"}
    ]