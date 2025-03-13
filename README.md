# Good Smells Game

## Project Overview

"Good Smells Game" is an isometric clicker/puzzle game with RPG-lite elements built using the Godot game engine. In this whimsical adventure, players control a giant floating nose that traverses various environments in search of pleasant aromas.

## Core Concept

Players navigate a floating nose through different map environments, sniffing around to discover various scents. Each scent has a value that affects the player's score - positive for good smells, negative for bad ones. The primary objective is to collect all the good smells in each level to progress.

## Technology Stack

We are currently building this game using the Godot engine (version 4.4). A previous prototype was built in the Defold engine, but we have since switched to Godot.

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
  /project files/        - Source files for assets
/scripts/                - Shared utility scripts
  /globals/              - Global scripts and autoloads
```

## Key Game Elements

### Player Character

- A giant floating nose that serves as the main character
- Movement controls allow navigation across the isometric map
- "Sniffing" action to detect and collect nearby smells

### Smell System

- **Good Smells**: Positive point values, required to complete levels
- **Bad Smells**: Negative point values, to be avoided
- **Epic Smells**: Special collectibles that add to a collection and provide unique benefits

### Environments

- Various isometric map layouts with different themes
- Each environment features unique sets of smells and challenges
- Progressive difficulty as players advance through environments

### Game Mechanics

- **Smell Detection**: Nose detects scents within a certain radius
- **Collection System**: Collect good smells while avoiding bad ones
- **Score System**: Track points based on collected smells
- **Win Condition**: Collect all good smells in an environment to complete the level

### Progression Elements

- Unlock new environments by completing previous levels
- Discover and collect epic smells to gain special abilities
- Possible upgrades for the nose (extended sniff range, faster movement)

## Technical Implementation

### Current Progress

- Basic isometric tileset implemented
- Player character with movement and smell detection
- Smell object system with different types (good, bad, epic)
- UI feedback for smell detection

## Controls

- **Arrow Keys**: Move the nose character
- **Space**: Activate smell detection

## Art Direction

The game features a colorful, lighthearted aesthetic with charming visual representations of different smells. Particle effects are used to visualize scent trails and collection moments.

## Target Audience

Casual gamers of all ages who enjoy relaxed puzzle experiences with collection mechanics. The quirky premise and accessible gameplay make it suitable for short play sessions.

## Development

To contribute to this project:

1. Clone the repository
2. Open the project in Godot 4.x
3. Follow the established project structure for new features
4. Keep scripts with their associated scenes
5. Use the smell base class for creating new smell types
