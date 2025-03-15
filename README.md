# Good Smells Game

## Project Overview

"Good Smells Game" is an isometric clicker/puzzle game with RPG-lite elements built using the Godot game engine. In this whimsical adventure, players control a giant floating nose that traverses various environments in search of pleasant aromas.

## Core Concept

Players navigate a floating nose through different map environments, sniffing around to discover various scents. Each scent has a value that affects the player's score - positive for good smells, negative for bad ones. The primary objective is to collect all the good smells in each level to progress.

## Technology Stack

This game is built using the Godot engine (version 4.4). We have fully implemented a custom isometric system with proper depth sorting and movement controls.

## Project Structure

The project follows Godot best practices with a clear organization:

```
/project.godot           - Main project configuration
/scenes/                 - All game scenes organized by component
  /player/               - Player character scenes and scripts
  /main/                 - Main game scenes and level scripts
  /UI/                   - User interface components
  /smells/               - Smell object definitions
/assets/                 - Game assets
  /images/               - Sprites and textures
  /fonts/                - Typography
  /project-files/        - Source files for assets
/scripts/                - Shared utility scripts
  /globals/             - Global scripts and autoloads
```

## Key Game Elements

### Player Character

- A giant floating nose with smooth isometric movement
- Implemented animation system with proper direction facing
- "Sniffing" action that detects nearby smell objects
- Float animation for visual appeal

### Smell System

- Extensible base smell class with customizable properties
- Four smell types: good, bad, epic, and neutral
- Each smell has its own visual particle system
- Collision-based detection system with custom messaging

### Isometric System

- Custom isometric utilities for coordinate conversion and world positioning
- Z-index based depth sorting system for proper object overlapping
- Efficient boundary management for map navigation
- Proper tile-based isometric movement

### Game Mechanics

- **Smell Detection**: Implemented collision and proximity-based detection
- **UI Feedback**: Visual and text feedback for smell detection
- **Isometric Navigation**: Smooth movement across the isometric tilemap
- **Visual Effects**: Particle systems for smell visualization

## Current Progress

- Fully functional isometric engine with proper sorting and movement
- Complete player character with animation and smell detection
- Extensible smell object system with different types and visual effects
- Flatmap implementation with tile-based navigation
- Core game loop with smell detection and collection
- Basic UI system for player feedback
- Title screen with game flow management

## Next Development Steps

- Implementing level completion conditions
- Adding more varied smell types and their unique effects
- Creating additional levels with increasing complexity
- Implementing a score and progress tracking system
- Adding sound effects and music
- Enhancing visual effects and animations

## Controls

- **Arrow Keys**: Move the nose character in isometric space
- **Space**: Activate smell detection action

## Development

To contribute to this project:

1. Clone the repository
2. Open the project in Godot 4.x
3. Follow the established project structure for new features
4. Keep scripts with their associated scenes
5. Use the smell base class for creating new smell types

## Technical Implementation Notes

### Isometric System

We've implemented a custom isometric system with the following components:

- `isometric_utils.gd`: Utility class for coordinate conversions and calculations
- `isometric_sorter.gd`: Handles proper rendering order of objects in isometric space

### Player Movement

The player movement system handles:

- Direction-based animation
- Boundary checking
- Proper isometric conversion for intuitive controls
- Smooth movement with proper depth sorting

### Smell Objects

Smell objects feature:

- Customizable particle effects
- Type-based behaviors and point values
- Detection radius and interaction system
- Animation for collection effects
