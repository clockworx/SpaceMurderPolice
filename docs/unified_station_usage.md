# Unified Station Usage Guide

## Making the Station Visible in Editor

The unified station uses a `@tool` script to generate geometry. To see and manipulate the station in the editor:

### Method 1: Using the Rebuild Button
1. Open `unified_station.tscn` in the Godot editor
2. Select the `StationBuilder` node in the scene tree
3. In the Inspector, look for "Editor Tools" section
4. Check the `Rebuild Station` checkbox
5. The station will be generated and visible in the editor

### Method 2: Initial Setup
1. Open `unified_station.tscn`
2. Select the `StationBuilder` node
3. Make sure `Build In Editor` is checked (it should be by default)
4. Save the scene and reopen it - the geometry should appear

### Clearing the Station
- To remove all generated geometry, check the `Clear Station` checkbox in the Inspector

## Editing the Station

Once the station is visible:
- All geometry is created using CSG nodes which can be edited
- The station is organized into:
  - `UnifiedStation` (root)
    - `CentralCore` - Vertical shaft connecting all levels
    - `UpperLevel` - Command and control areas
    - `MainLevel` - Living and research areas  
    - `LowerLevel` - Engineering and support
    - `VerticalConnections` - Elevators and stairs
    - `MaintenanceNetwork` - Alternative routes
    - `StationLighting` - Lighting system
    - `NavigationAids` - Level indicators

## Modifying Rooms

To change room layouts:
1. Edit the `unified_station_builder.gd` script
2. Modify room positions, sizes, or door configurations in the build functions
3. Use the `Rebuild Station` checkbox to regenerate with changes

## Performance Note

The station contains 25+ rooms across 3 levels with full CSG geometry. Initial generation may take a few seconds. Once generated, the geometry is static and performs well.