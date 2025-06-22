# Fix Godot Cache Error

If you're seeing errors like:
```
ERROR: Attempt to open script 'res://scripts/test/test_all_waypoint_paths.gd' resulted in error 'File not found'.
```

This is because Godot has cached references to the deleted test files. To fix:

## Option 1: Clear Godot's Cache (Recommended)
1. Close Godot completely
2. Delete the `.godot` folder in your project directory
3. Reopen the project in Godot
4. Let it reimport all assets

## Option 2: Restart Godot
Sometimes simply closing and reopening Godot will clear these references.

## Option 3: Check for Scene References
If the error persists:
1. In Godot, go to Project → Project Settings → Autoload
2. Check if any test scripts are listed there and remove them
3. Check your main scenes to ensure no test nodes were added

The error should disappear once Godot's cache is refreshed.