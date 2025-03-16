extends Node
class_name IsometricUtils

# Utility static class for handling isometric calculations
# This is a singleton that can be loaded as an autoload in project settings

# Default tile dimensions - these should match the actual tile size used in the game
const DEFAULT_TILE_WIDTH = 32
const DEFAULT_TILE_HEIGHT = 16

# Get the appropriate scaled tile dimensions
static func get_scaled_tile_width() -> float:
	return DEFAULT_TILE_WIDTH * ScaleHelper.SCALE_FACTOR

static func get_scaled_tile_height() -> float:
	return DEFAULT_TILE_HEIGHT * ScaleHelper.SCALE_FACTOR

# Convert world position to isometric tile coordinates
static func world_to_tile(world_pos: Vector2, tile_width: float = -1, tile_height: float = -1) -> Vector2i:
	# If no specific dimensions provided, use the scaled defaults
	if tile_width <= 0:
		tile_width = get_scaled_tile_width()
	if tile_height <= 0:
		tile_height = get_scaled_tile_height()
		
	var screen_x = world_pos.x
	var screen_y = world_pos.y
	
	# Convert screen coordinates to isometric tile coordinates
	var tile_x = (screen_x / tile_width + screen_y / tile_height) / 2
	var tile_y = (screen_y / tile_height - screen_x / tile_width) / 2
	
	return Vector2i(int(floor(tile_x)), int(floor(tile_y)))

# Convert isometric tile coordinates to world position
static func tile_to_world(tile_coords: Vector2i, tile_width: float = -1, tile_height: float = -1) -> Vector2:
	# If no specific dimensions provided, use the scaled defaults
	if tile_width <= 0:
		tile_width = get_scaled_tile_width()
	if tile_height <= 0:
		tile_height = get_scaled_tile_height()
		
	var iso_x = (tile_coords.x - tile_coords.y) * tile_width
	var iso_y = (tile_coords.x + tile_coords.y) * tile_height / 2
	
	return Vector2(iso_x, iso_y)

# Convert screen to isometric direction 
static func get_isometric_direction(input_vector: Vector2) -> Vector2:
	# Convert input direction to isometric direction
	return Vector2(
		input_vector.x - input_vector.y,
		(input_vector.x + input_vector.y) * 0.5
	).normalized()

# Get Z-index for a position (for proper object overlapping)
static func get_z_index_for_position(pos: Vector2) -> int:
	# In isometric, objects with higher Y values should be drawn on top
	return int(pos.y)

# Check if a position is within isometric boundaries
static func is_within_boundaries(
	pos: Vector2,
	min_x: int, max_x: int,
	min_y: int, max_y: int,
	tile_width: float = -1,
	tile_height: float = -1
) -> bool:
	# If no specific dimensions provided, use the scaled defaults
	if tile_width <= 0:
		tile_width = get_scaled_tile_width()
	if tile_height <= 0:
		tile_height = get_scaled_tile_height()
		
	var tile_pos = world_to_tile(pos, tile_width, tile_height)
	return (
		tile_pos.x >= min_x and
		tile_pos.x <= max_x and
		tile_pos.y >= min_y and
		tile_pos.y <= max_y
	)

# Get closest valid position within boundaries
static func get_valid_position(
	pos: Vector2,
	min_x: int, max_x: int,
	min_y: int, max_y: int,
	tile_width: float = -1,
	tile_height: float = -1
) -> Vector2:
	# If no specific dimensions provided, use the scaled defaults
	if tile_width <= 0:
		tile_width = get_scaled_tile_width()
	if tile_height <= 0:
		tile_height = get_scaled_tile_height()
		
	var tile_pos = world_to_tile(pos, tile_width, tile_height)
	
	# Clamp values to boundaries
	tile_pos.x = clampi(tile_pos.x, min_x, max_x)
	tile_pos.y = clampi(tile_pos.y, min_y, max_y)
	
	# Convert back to world coordinates
	return tile_to_world(tile_pos, tile_width, tile_height)

# Convert between isometric and cartesian coordinates
static func iso_to_cart(iso_pos: Vector2, tile_width: float = -1, tile_height: float = -1) -> Vector2:
	# If no specific dimensions provided, use the scaled defaults
	if tile_width <= 0:
		tile_width = get_scaled_tile_width()
	if tile_height <= 0:
		tile_height = get_scaled_tile_height()
		
	var cart_x = (iso_pos.x / tile_width + iso_pos.y / (tile_height / 2)) / 2
	var cart_y = (iso_pos.y / (tile_height / 2) - iso_pos.x / tile_width) / 2
	return Vector2(cart_x, cart_y)

static func cart_to_iso(cart_pos: Vector2, tile_width: float = -1, tile_height: float = -1) -> Vector2:
	# If no specific dimensions provided, use the scaled defaults
	if tile_width <= 0:
		tile_width = get_scaled_tile_width()
	if tile_height <= 0:
		tile_height = get_scaled_tile_height()
		
	var iso_x = (cart_pos.x - cart_pos.y) * tile_width
	var iso_y = (cart_pos.x + cart_pos.y) * tile_height / 2
	return Vector2(iso_x, iso_y)

# Helper for getting isometric neighbors of a tile
static func get_tile_neighbors(tile_coords: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	neighbors.append(Vector2i(tile_coords.x + 1, tile_coords.y)) # East
	neighbors.append(Vector2i(tile_coords.x - 1, tile_coords.y)) # West
	neighbors.append(Vector2i(tile_coords.x, tile_coords.y + 1)) # South
	neighbors.append(Vector2i(tile_coords.x, tile_coords.y - 1)) # North
	return neighbors

# Get the isometric distance between two tiles (Manhattan distance)
static func get_isometric_distance(tile_a: Vector2i, tile_b: Vector2i) -> int:
	return abs(tile_a.x - tile_b.x) + abs(tile_a.y - tile_b.y)
