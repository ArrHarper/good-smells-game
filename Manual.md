# Good Smells - Game Manual

## Game Overview

Good Smells is an isometric game built in Godot 4.4 that focuses on smell-based mechanics. The game utilizes a custom isometric system for movement and object sorting.

## Technical Architecture

### Project Structure

```
good-smells/
├── scenes/           # Game scenes and prefabs
│   ├── UI/          # User interface elements
│   ├── main/        # Main game scenes
│   ├── player/      # Player-related scenes
│   └── smells/      # Smell mechanic related scenes
├── scripts/         # Game logic and utilities
│   ├── globals/     # Global script singletons
│   ├── isometric_sorter.gd    # Handles isometric depth sorting
│   └── isometric_utils.gd     # Isometric utility functions
└── assets/          # Game assets (textures, sounds, etc.)
```

### Core Systems

#### 1. Isometric System

The game uses a custom isometric system implemented through two main scripts:

- `isometric_utils.gd`: A singleton (autoloaded as "Iso") that provides utility functions for isometric calculations
- `isometric_sorter.gd`: Handles depth sorting for isometric objects

**Isometric Configuration**

- Default Tile Dimensions:
  - Width: 64 pixels
  - Height: 32 pixels

**Key Isometric Functions**

1. Coordinate Conversions:

   - `world_to_tile(world_pos)`: Converts world position to isometric tile coordinates
   - `tile_to_world(tile_coords)`: Converts isometric tile coordinates to world position
   - `iso_to_cart(iso_pos)`: Converts isometric to cartesian coordinates
   - `cart_to_iso(cart_pos)`: Converts cartesian to isometric coordinates

2. Movement and Direction:

   - `get_isometric_direction(input_vector)`: Converts screen input to isometric direction
   - `get_z_index_for_position(pos)`: Calculates proper Z-index for object overlapping

3. Boundary Management:

   - `is_within_boundaries(pos, ...)`: Checks if a position is within isometric boundaries
   - `get_valid_position(pos, ...)`: Gets closest valid position within boundaries

4. Tile Operations:
   - `get_tile_neighbors(tile_coords)`: Returns array of neighboring tile coordinates
   - `get_isometric_distance(tile_a, tile_b)`: Calculates Manhattan distance between tiles

#### 2. Input System

The game uses the following input mappings:

- Movement: Arrow keys or gamepad
- Smell Action: Spacebar

#### 3. Smell System

The game features a sophisticated smell detection and collection system:

**Smell Properties**

- Types: good, bad, epic, neutral
- Configurable Properties:
  - `smell_name`: Name of the smell
  - `smell_type`: Category of smell
  - `smell_message`: Message displayed when detected
  - `points`: Points awarded for collection
  - `isometric_height_offset`: Vertical offset in isometric space

**Particle System**

- Each smell has a unique particle effect system
- Particle properties vary by smell type:
  - Good: Green particles (0.2, 0.8, 0.2, 0.8)
  - Bad: Red particles (0.8, 0.2, 0.2, 0.8)
  - Epic: Purple particles (0.8, 0.2, 0.8, 0.8)
  - Neutral: Light gray particles (0.8, 0.8, 0.8, 0.8)

**Detection Mechanics**

1. Initial State:

   - Smells start hidden
   - Player must enter detection range
   - Use smell ability to detect (Spacebar)

2. Animation Sequence:
   - Duration: 1.6 seconds total
   - Message Delay: 0.8 seconds
   - Particles rise and fade
   - Collection marked after animation

**Implementation Details**

- Smells are implemented as `Area2D` nodes
- Default collision radius: 16 pixels
- Particle system configuration:
  - Emission radius: 15.0
  - Spread: 60.0 degrees
  - Upward gravity: -30
  - 24 particles per emission
  - 2.5 second particle lifetime

### Game Configuration

#### Display Settings

- Window Size: 800x600 pixels
- Resizable: False
- Rendering: Forward Plus

## Developer Guide

### Modifying Game Properties

1. **Input Settings**

   - Input mappings can be modified in Project Settings > Input Map
   - Current mappings include: ui_left, ui_right, ui_up, ui_down, and smell

2. **Isometric Settings**
   - Modify isometric calculations in `isometric_utils.gd`
   - Adjust sorting behavior in `isometric_sorter.gd`

### Best Practices

1. **Scene Organization**

   - Keep related scenes grouped in their respective directories
   - Use PascalCase for scene names
   - Maintain scene hierarchy for better organization

2. **Scripting Guidelines**

   - Follow GDScript style guide
   - Use autoloads sparingly and only for truly global functionality
   - Implement proper signal connections for inter-scene communication

3. **Performance Considerations**

   - Use the built-in isometric sorting system for consistent depth handling
   - Optimize smell detection calculations
   - Consider using object pooling for frequently spawned objects

4. **Isometric Considerations**
   - Always use the provided isometric utility functions for coordinate conversions
   - Consider Z-indexing for proper object layering
   - Use tile-based calculations for game logic when possible
   - Maintain consistent tile dimensions across scenes

### Common Tasks

1. **Adding New Smell Types**

   - Create new smell scene in `scenes/smells/`
   - Inherit from base `smell.tscn`
   - Configure properties:
     ```gdscript
     smell_name = "New Smell"
     smell_type = "good"  # or "bad", "epic", "neutral"
     smell_message = "Custom message..."
     points = 10
     isometric_height_offset = 0.0
     ```
   - Customize particle effects if needed
   - Add to smell management system

2. **Modifying Player Behavior**

   - Player-related logic is in the `scenes/player/` directory
   - Adjust movement speed and interaction ranges in player scripts

3. **UI Modifications**
   - UI elements are stored in `scenes/UI/`
   - Follow Godot's Control node system for UI layout

### Godot-Specific Considerations

1. **Node Structure**

   - Use appropriate node types for different functionalities
   - Maintain clean scene trees
   - Utilize groups for easy node management

2. **Resource Management**

   - Preload frequently used resources
   - Use load() for dynamically loaded content
   - Implement proper resource cleanup

3. **Signal Usage**
   - Connect signals through the editor when possible
   - Use custom signals for complex interactions
   - Maintain clear signal naming conventions

## Troubleshooting

Common issues and their solutions:

1. **Depth Sorting Issues**

   - Ensure objects have proper Y-sort enabled
   - Check isometric_sorter.gd configuration
   - Verify object pivot points

2. **Performance Optimization**
   - Use the built-in profiler to identify bottlenecks
   - Consider using object pooling for particle effects
   - Implement proper culling for off-screen objects

## Version Control

The project uses Git for version control. Important considerations:

- `.gitignore` is configured for Godot projects
- Binary files are tracked using Git LFS
- Follow conventional commit messages

## Future Development

When extending the game, consider:

1. **Modularity**

   - Keep systems loosely coupled
   - Use dependency injection where appropriate
   - Maintain clear interfaces between systems

2. **Scalability**

   - Plan for additional content
   - Keep performance in mind
   - Document new systems thoroughly

3. **Testing**
   - Implement unit tests for critical systems
   - Use Godot's built-in testing framework
   - Maintain test coverage for core functionality
