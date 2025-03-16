# Resolution Scaling in Good Smells Game

This document explains the resolution and scaling system used in the Good Smells Game.

## Approach

We use Godot's built-in viewport scaling system to ensure pixel-perfect rendering while supporting various screen sizes. This approach:

1. Uses a base resolution of 800x600
2. Scales the viewport by a factor of 2.0
3. Preserves pixel-perfect rendering using integer scaling
4. Maintains proper aspect ratio

## Configuration

The scaling is configured in the `project.godot` file with the following settings:

```gdscript
[display]
window/size/viewport_width=800
window/size/viewport_height=600
window/size/resizable=true
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/stretch/scale=2.0
window/stretch/scale_mode="integer"
```

### Settings Explained

- **viewport_width/height**: The base resolution that you design your game in
- **resizable**: Allows the window to be resized
- **stretch/mode="viewport"**: The entire viewport is scaled
- **stretch/aspect="keep"**: Maintains aspect ratio, adding black bars if needed
- **stretch/scale=2.0**: Scales the content by 2x
- **stretch/scale_mode="integer"**: Ensures pixel-perfect scaling by only using integer scales

## Benefits

1. **Pixel-Perfect Rendering**: Game assets remain crisp without blurring
2. **Position Consistency**: Editor positions match runtime positions
3. **Simplified Code**: Less custom scaling logic needed
4. **Automatic Scaling**: Handles different screen sizes properly

## Working with the System

When working with this system:

1. Position nodes in the editor as they should appear in the game
2. No position conversion is needed between editor and runtime
3. Use `ScaleHelper.apply_nearest_neighbor_filter()` for any dynamically created sprites

## Notes for Developers

- All textures are set to use nearest-neighbor filtering for pixel art crispness
- UI elements should use anchors and containers to handle different aspect ratios
- The editor preview shows the unscsaled version, but at runtime everything is scaled by 2x
