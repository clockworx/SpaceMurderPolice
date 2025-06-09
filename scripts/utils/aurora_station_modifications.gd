# Aurora Station Scene Modifications
# This file contains all the modifications needed to update aurora_station.tscn
# Copy these values into the scene file or use the Godot editor to apply them

extends Resource

# ROOM SIZE MODIFICATIONS
# Apply these to each room's CSGBox3D nodes

const ROOM_MODIFICATIONS = {
    "Laboratory3": {
        "Floor": {"size": Vector3(14, 0.2, 14)},
        "Ceiling": {"size": Vector3(14, 0.2, 14), "position": Vector3(0, 4, 0)},
        "LeftWall": {"size": Vector3(0.2, 4, 14), "position": Vector3(-7, 2, 0)},
        "BackWall": {"size": Vector3(14, 4, 0.2), "position": Vector3(0, 2, -7)},
        "FrontWall": {"size": Vector3(14, 4, 0.2), "position": Vector3(0, 2, 7)},
        "RightWallLeft": {"size": Vector3(0.2, 4, 6), "position": Vector3(7, 2, -4)},
        "RightWallRight": {"size": Vector3(0.2, 4, 6), "position": Vector3(7, 2, 4)},
        "RightWallTop": {"size": Vector3(0.2, 1, 2), "position": Vector3(7, 3.5, 0)},
        "DoorCutout": {"position": Vector3(7, 1.5, 0)},
        # Update furniture
        "LabBench": {"position": Vector3(-2, 0.4, -2)},
        "CrimeSceneBody": {"position": Vector3(0, 0.1, -4)},
        "BloodDecal": {"position": Vector3(0, 0.01, -4)}
    },
    
    "MedicalBay": {
        "Floor": {"size": Vector3(12, 0.2, 12)},
        "Ceiling": {"size": Vector3(12, 0.2, 12), "position": Vector3(0, 4, 0)},
        "RightWall": {"size": Vector3(0.2, 4, 12), "position": Vector3(6, 2, 0)},
        "BackWall": {"size": Vector3(12, 4, 0.2), "position": Vector3(0, 2, -6)},
        "FrontWall": {"size": Vector3(12, 4, 0.2), "position": Vector3(0, 2, 6)},
        "LeftWallFront": {"size": Vector3(0.2, 4, 5), "position": Vector3(-6, 2, 3.5)},
        "LeftWallBack": {"size": Vector3(0.2, 4, 5), "position": Vector3(-6, 2, -3.5)},
        "LeftWallTop": {"size": Vector3(0.2, 1, 2), "position": Vector3(-6, 3.5, 0)},
        "DoorCutout": {"position": Vector3(-6, 1.5, 0)},
        "ExamTable": {"position": Vector3(2, 0.5, 0)}
    },
    
    "SecurityOffice": {
        "Floor": {"size": Vector3(12, 0.2, 12)},
        "Ceiling": {"size": Vector3(12, 0.2, 12), "position": Vector3(0, 4, 0)},
        "LeftWall": {"size": Vector3(0.2, 4, 12), "position": Vector3(-6, 2, 0)},
        "BackWall": {"size": Vector3(12, 4, 0.2), "position": Vector3(0, 2, -6)},
        "FrontWall": {"size": Vector3(12, 4, 0.2), "position": Vector3(0, 2, 6)},
        "RightWallFront": {"size": Vector3(0.2, 4, 5), "position": Vector3(6, 2, 3.5)},
        "RightWallBack": {"size": Vector3(0.2, 4, 5), "position": Vector3(6, 2, -3.5)},
        "RightWallTop": {"size": Vector3(0.2, 1, 2), "position": Vector3(6, 3.5, 0)},
        "DoorCutout": {"position": Vector3(6, 1.5, 0)},
        "Desk": {"position": Vector3(-2, 0.4, -2)}
    },
    
    "Engineering": {
        "Floor": {"size": Vector3(14, 0.2, 14)},
        "Ceiling": {"size": Vector3(14, 0.2, 14), "position": Vector3(0, 4, 0)},
        "RightWall": {"size": Vector3(0.2, 4, 14), "position": Vector3(7, 2, 0)},
        "BackWall": {"size": Vector3(14, 4, 0.2), "position": Vector3(0, 2, -7)},
        "FrontWall": {"size": Vector3(14, 4, 0.2), "position": Vector3(0, 2, 7)},
        "LeftWallFront": {"size": Vector3(0.2, 4, 6), "position": Vector3(-7, 2, 4)},
        "LeftWallBack": {"size": Vector3(0.2, 4, 6), "position": Vector3(-7, 2, -4)},
        "LeftWallTop": {"size": Vector3(0.2, 1, 2), "position": Vector3(-7, 3.5, 0)},
        "DoorCutout": {"position": Vector3(-7, 1.5, 0)},
        "Console": {"position": Vector3(0, 0.5, -3), "size": Vector3(4, 1, 2)}
    },
    
    "CrewQuarters": {
        "Floor": {"size": Vector3(14, 0.2, 12)},
        "Ceiling": {"size": Vector3(14, 0.2, 12), "position": Vector3(0, 4, 0)},
        "LeftWall": {"size": Vector3(0.2, 4, 12), "position": Vector3(-7, 2, 0)},
        "BackWall": {"size": Vector3(14, 4, 0.2), "position": Vector3(0, 2, -6)},
        "FrontWall": {"size": Vector3(14, 4, 0.2), "position": Vector3(0, 2, 6)},
        "RightWallFront": {"size": Vector3(0.2, 4, 5), "position": Vector3(7, 2, 3.5)},
        "RightWallBack": {"size": Vector3(0.2, 4, 5), "position": Vector3(7, 2, -3.5)},
        "RightWallTop": {"size": Vector3(0.2, 1, 2), "position": Vector3(7, 3.5, 0)},
        "DoorCutout": {"position": Vector3(7, 1.5, 0)},
        "Bed1": {"position": Vector3(-4, 0.3, -3)},
        "Bed2": {"position": Vector3(4, 0.3, -3)}
    },
    
    "Cafeteria": {
        "Floor": {"size": Vector3(16, 0.2, 14)},
        "Ceiling": {"size": Vector3(16, 0.2, 14), "position": Vector3(0, 4, 0)},
        "RightWall": {"size": Vector3(0.2, 4, 14), "position": Vector3(8, 2, 0)},
        "BackWall": {"size": Vector3(16, 4, 0.2), "position": Vector3(0, 2, -7)},
        "FrontWall": {"size": Vector3(16, 4, 0.2), "position": Vector3(0, 2, 7)},
        "LeftWallFront": {"size": Vector3(0.2, 4, 6), "position": Vector3(-8, 2, 4)},
        "LeftWallBack": {"size": Vector3(0.2, 4, 6), "position": Vector3(-8, 2, -4)},
        "LeftWallTop": {"size": Vector3(0.2, 1, 2), "position": Vector3(-8, 3.5, 0)},
        "DoorCutout": {"position": Vector3(-8, 1.5, 0)},
        "Table1": {"position": Vector3(-4, 0.4, -3)},
        "Table2": {"position": Vector3(4, 0.4, 3)}
    }
}

# DOOR POSITIONS
# Update the transform for each door in the Doors node
const DOOR_TRANSFORMS = {
    "Laboratory3Door": "transform = Transform3D(-4.37114e-08, 0, 1, 0, 1, 0, -1, 0, -4.37114e-08, -3, 0.1, 10)",
    "MedicalDoor": "transform = Transform3D(-4.37114e-08, 0, -1, 0, 1, 0, 1, 0, -4.37114e-08, 3, 0.1, 5)",
    "SecurityDoor": "transform = Transform3D(-4.37114e-08, 0, 1, 0, 1, 0, -1, 0, -4.37114e-08, -3, 0.1, -5)",
    "EngineeringDoor": "transform = Transform3D(-4.37114e-08, 0, -1, 0, 1, 0, 1, 0, -4.37114e-08, 3, 0.1, -10)",
    "CrewQuartersDoor": "transform = Transform3D(-4.37114e-08, 0, 1, 0, 1, 0, -1, 0, -4.37114e-08, -3, 0.1, -15)",
    "CafeteriaDoor": "transform = Transform3D(-4.37114e-08, 0, -1, 0, 1, 0, 1, 0, -4.37114e-08, 3, 0.1, -20)"
}

# NPC POSITIONS
# Update these in the NPCs node
const NPC_POSITIONS = {
    "ChiefScientistNPC": Vector3(-12, 0.1, 10),
    "MedicalOfficerNPC": Vector3(12, 0.1, 5),
    "SecurityChiefNPC": Vector3(-10, 0.1, -5),
    "EngineerNPC": Vector3(10, 0.1, -10),
    "SecurityNPC": Vector3(-10, 0.1, -15),
    "AISpecialistNPC": Vector3(12, 0.1, -20),
    "ScientistNPC": Vector3(-11, 0.1, 8)
}

# WAYPOINT PLACEMENTS
# Add these waypoint nodes to each room
const WAYPOINT_CONFIGS = {
    "Laboratory3": [
        {"name": "Waypoint1", "position": Vector3(-5, 0.1, 5), "type": "research", "room": "laboratory"},
        {"name": "Waypoint2", "position": Vector3(5, 0.1, 5), "type": "equipment", "room": "laboratory"},
        {"name": "Waypoint3", "position": Vector3(-5, 0.1, -5), "type": "workstation", "room": "laboratory"},
        {"name": "Waypoint4", "position": Vector3(5, 0.1, -5), "type": "wander", "room": "laboratory"},
        {"name": "Waypoint5", "position": Vector3(0, 0.1, 0), "type": "wander", "room": "laboratory"}
    ],
    "MedicalBay": [
        {"name": "Waypoint1", "position": Vector3(-4, 0.1, 4), "type": "examination", "room": "medical"},
        {"name": "Waypoint2", "position": Vector3(4, 0.1, 4), "type": "supplies", "room": "medical"},
        {"name": "Waypoint3", "position": Vector3(-4, 0.1, -4), "type": "desk", "room": "medical"},
        {"name": "Waypoint4", "position": Vector3(4, 0.1, -4), "type": "wander", "room": "medical"}
    ],
    "SecurityOffice": [
        {"name": "Waypoint1", "position": Vector3(-4, 0.1, 4), "type": "monitors", "room": "security"},
        {"name": "Waypoint2", "position": Vector3(4, 0.1, 4), "type": "weapons", "room": "security"},
        {"name": "Waypoint3", "position": Vector3(-4, 0.1, -4), "type": "desk", "room": "security"},
        {"name": "Waypoint4", "position": Vector3(4, 0.1, -4), "type": "wander", "room": "security"}
    ],
    "Engineering": [
        {"name": "Waypoint1", "position": Vector3(-5, 0.1, 5), "type": "console", "room": "engineering"},
        {"name": "Waypoint2", "position": Vector3(5, 0.1, 5), "type": "repairs", "room": "engineering"},
        {"name": "Waypoint3", "position": Vector3(-5, 0.1, -5), "type": "storage", "room": "engineering"},
        {"name": "Waypoint4", "position": Vector3(5, 0.1, -5), "type": "wander", "room": "engineering"},
        {"name": "Waypoint5", "position": Vector3(0, 0.1, 2), "type": "wander", "room": "engineering"}
    ],
    "CrewQuarters": [
        {"name": "Waypoint1", "position": Vector3(-5, 0.1, 3), "type": "wander", "room": "quarters"},
        {"name": "Waypoint2", "position": Vector3(5, 0.1, 3), "type": "wander", "room": "quarters"},
        {"name": "Waypoint3", "position": Vector3(0, 0.1, -2), "type": "wander", "room": "quarters"}
    ],
    "Cafeteria": [
        {"name": "Waypoint1", "position": Vector3(-6, 0.1, 5), "type": "kitchen", "room": "cafeteria"},
        {"name": "Waypoint2", "position": Vector3(6, 0.1, 5), "type": "tables", "room": "cafeteria"},
        {"name": "Waypoint3", "position": Vector3(-6, 0.1, -5), "type": "storage", "room": "cafeteria"},
        {"name": "Waypoint4", "position": Vector3(6, 0.1, -5), "type": "wander", "room": "cafeteria"},
        {"name": "Waypoint5", "position": Vector3(0, 0.1, 0), "type": "tables", "room": "cafeteria"}
    ]
}

# Instructions for applying changes:
# 1. Open aurora_station.tscn in Godot
# 2. For each room in ROOM_MODIFICATIONS:
#    - Select the room node (e.g., Rooms/Laboratory3)
#    - Update each CSGBox3D child with the size and position values
# 3. Update door positions using DOOR_TRANSFORMS
# 4. Update NPC starting positions using NPC_POSITIONS
# 5. Add waypoint scenes to each room using WAYPOINT_CONFIGS
#    - Create a "Waypoints" node under each room
#    - Instance waypoint.tscn for each waypoint
#    - Set position, waypoint_type, and room_name properties