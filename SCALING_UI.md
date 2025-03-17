# UI Scaling in Good Smells Game

This document explains how UI scaling is handled in the Good Smells Game.

## Approach

We use Godot's `canvas_items` stretch mode to ensure:

1. Game elements are upscaled by a factor of 2.0 for pixel-perfect rendering
2. UI elements remain at native resolution for crisp text and controls
3. Proper aspect ratio is maintained

## Configuration

The UI scaling is configured in the `project.godot` file with the following settings:

```gdscript
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/stretch/scale=2.0
window/stretch/scale_mode="integer"
```

### Settings Explained

- **viewport_width/height**: The base resolution that you design your game in
- **resizable**: Allows the window to be resized
- **stretch/mode="canvas_items"**: Game content (sprites, tilemaps, etc.) is scaled, but UI remains at native resolution
- **stretch/aspect="keep"**: Maintains aspect ratio, adding black bars if needed
- **stretch/scale=2.0**: Scales the game content by 2x
- **stretch/scale_mode="integer"**: Ensures pixel-perfect scaling by only using integer scales

## Benefits

1. **Crisp UI Text**: UI text and controls remain sharp regardless of scaling
2. **Pixel-Perfect Game Rendering**: Game assets remain crisp without blurring
3. **Simplified UI Development**: UI can be designed at native resolution without worrying about scaling issues
4. **Automatic Scaling**: Handles different screen sizes properly

## Working with the System

When working with this system:

1. Design UI elements normally in the editor without worrying about scaling
2. All UI elements should be placed in CanvasLayers or as Control nodes
3. Game elements will be automatically scaled up by the stretch mode
4. Use `ScaleHelper.apply_nearest_neighbor_filter()` for any dynamically created game sprites

## Notes for Developers

- All game textures are set to use nearest-neighbor filtering for pixel art crispness
- UI elements should use anchors and containers to handle different aspect ratios
- Control nodes are automatically excluded from manual filtering to keep text crisp
