# Toggling Custom Scaling in Good Smells Game

This document explains how to toggle the custom scaling system in the Good Smells Game.

## How to Toggle Custom Scaling

A toggle has been added to easily enable or disable the custom scaling scripts without removing them from the project. This allows for testing native Godot scaling while preserving the ability to revert to the custom scaling system if needed.

### Steps to Toggle Scaling

1. Open the file: `scripts/globals/scale_helper.gd`
2. Locate the constant at the top of the file:
   ```gdscript
   # Toggle to enable/disable scaling functionality (set to false to use native Godot scaling only)
   const SCALING_ENABLED = true
   ```
3. Set the value to `false` to disable custom scaling:
   ```gdscript
   const SCALING_ENABLED = false
   ```
4. Set it back to `true` to re-enable custom scaling.

## What This Toggle Controls

When `SCALING_ENABLED` is set to `false`:

1. All scale value calculations return original values instead of scaled values
2. The custom game scaling system is bypassed, allowing Godot's native scaling to take over
3. Pixel-perfect texture filtering is still applied to ensure proper display of pixel art
4. No nodes are manually scaled by the custom scaling system

## Advantages of Using the Toggle

1. Easy to test different scaling approaches without modifying multiple files
2. Can quickly revert to the original system if native scaling causes issues
3. No need to remove or comment out code in multiple locations
4. Preserves the existing structure for future development

## Notes for Developers

- When toggling between modes, you might need to restart the scene to ensure all scaling is applied correctly
- The toggle affects all scale-related functions in both `ScaleHelper` and `GameScale`
- UI elements will behave the same in both modes since they were already excluded from custom scaling
- The toggle does not affect Godot's project settings for viewport scaling
