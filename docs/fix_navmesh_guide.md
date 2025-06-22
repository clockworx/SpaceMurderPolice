# Fixing Navigation Mesh Issues

## Common Problems and Solutions

### 1. Missing Bits / Gaps in NavMesh

**Causes:**
- Cell size too large
- Agent radius too large
- Incorrect collision layers
- Missing collision shapes on floors

**Solutions:**

1. **Adjust Cell Size** (most important):
   - Select NavigationRegion3D
   - In NavigationMesh resource:
   - Set `Cell Size` to 0.1 (smaller = more detail)
   - Set `Cell Height` to 0.05

2. **Reduce Agent Radius**:
   - Set `Agent Radius` to 0.3 (allows fitting through doors)
   - Original might be 0.5 which is too large

3. **Check Collision Setup**:
   - Floors MUST have StaticBody3D + CollisionShape3D
   - Set collision layer to 1 (environment)
   - Walls should also have collisions

### 2. NavMesh Not Connecting Between Rooms

**Solutions:**

1. **Adjust Region Settings**:
   - `Region Min Size`: 2.0 (captures small areas)
   - `Region Merge Size`: 10.0 (helps connect rooms)

2. **Use NavigationLink3D** (already added to doors):
   - These manually connect separate regions
   - Make sure they're enabled and positioned correctly

3. **Door Handling**:
   - Option A: Exclude doors from navigation mesh (remove collision during baking)
   - Option B: Make door collision very thin
   - Option C: Raise navigation mesh slightly above door threshold

### 3. Quick Fix Process

1. **Run the Setup Tool**:
   - Open `scripts/tools/navigation_mesh_setup.gd`
   - Click File → Run
   - This applies optimal settings

2. **Manual Adjustments**:
   - Select NavigationRegion3D in scene
   - NavigationMesh resource → Adjust:
     ```
     Cell Size: 0.1
     Cell Height: 0.05
     Agent Radius: 0.3
     Agent Height: 1.8
     Agent Max Climb: 0.3
     Region Min Size: 2.0
     ```

3. **Rebake**:
   - Click "Bake NavigationMesh"
   - Check preview - should see blue mesh covering all walkable areas

### 4. Advanced Settings

**For Better Door Navigation**:
- `Edge Max Length`: 5.0 (shorter edges)
- `Edge Max Error`: 0.5 (more precision)

**For Complex Geometry**:
- `Vertices Per Polygon`: 6 (default)
- `Detail Sample Distance`: 3.0
- `Detail Sample Max Error`: 0.5

**Geometry Source**:
- Use `Static Colliders` (recommended)
- Set `Collision Mask` to 1 (environment only)

### 5. Testing After Rebake

1. Look for continuous blue mesh across floors
2. Check doorways have navigation coverage
3. Yellow NavigationLink3D lines should connect gaps
4. Run scene and test with keyboard controls (1-6)

### 6. If Still Having Issues

**Missing Floor Areas**:
- Add CollisionShape3D to floor meshes
- Ensure collision layer = 1
- Try `Mesh Instances` instead of `Static Colliders` for geometry source

**Too Many Gaps**:
- Reduce Cell Size to 0.05
- Increase Edge Max Length to 10.0
- Check floor is truly flat (no tiny gaps)

**Performance Issues**:
- Increase Cell Size slightly (0.15)
- Reduce Detail Sample Distance
- Limit navigation to necessary areas only