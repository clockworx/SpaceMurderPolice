# Smooth Rotation Guide for Waypoint NPCs

## Overview
NPCs now have smooth rotation when moving between waypoints, making their movement more natural and realistic.

## Settings
In the Inspector under "Rotation Settings":
- **smooth_rotation**: Toggle between smooth and instant rotation
- **rotation_speed**: How fast NPCs turn (default: 5.0 radians/second)

## Features

### 1. Smooth Turning While Moving
- NPCs gradually rotate to face their movement direction
- Uses quaternion slerp for smooth interpolation
- Maintains upright posture (no tilting)

### 2. Idle Animation While Paused
- NPCs slowly look around when paused at waypoints
- Creates a more lifelike appearance
- Subtle head movement using sine wave

## Tuning Tips

### Rotation Speed Values:
- **1.0-2.0**: Very slow, cinematic turns
- **3.0-5.0**: Natural human-like rotation (default)
- **7.0-10.0**: Quick, responsive turns
- **15.0+**: Nearly instant rotation

### Best Practices:
1. Use lower rotation speeds for larger NPCs or robots
2. Use higher speeds for agile characters
3. Disable smooth rotation for mechanical/robotic NPCs if desired
4. Adjust based on walk speed - faster NPCs may need faster rotation

## Technical Details
The system uses:
- Quaternion slerp for smooth interpolation
- Delta time for frame-rate independent rotation
- Automatic correction to keep NPCs upright
- Direction vector normalization for consistent speed