extends Node

# This is a helper class for working with scaled values in the game
# It provides utility functions to convert between editor and runtime values

# Get the current scale factor
static func get_scale_factor() -> float:
	if Engine.has_singleton("GameScale"):
		return Engine.get_singleton("GameScale").SCALE_FACTOR
	return 1.0

# Scale a single value
static func scale_value(value: float) -> float:
	return value * get_scale_factor()

# Scale a Vector2 position
static func scale_position(position: Vector2) -> Vector2:
	return position * get_scale_factor()

# Scale a size/dimension
static func scale_size(size: Vector2) -> Vector2:
	return size * get_scale_factor()

# Convert an editor position to runtime position
static func editor_to_runtime(position: Vector2) -> Vector2:
	return position * get_scale_factor()

# Convert a runtime position back to editor position
static func runtime_to_editor(position: Vector2) -> Vector2:
	return position / get_scale_factor()

# Determine if a value has already been scaled
static func is_scaled(node: Node2D) -> bool:
	if node == null:
		return false
		
	# If the node's scale matches the game scale, it's already scaled
	var scale_factor = get_scale_factor()
	return is_equal_approx(node.scale.x, scale_factor) and is_equal_approx(node.scale.y, scale_factor)

# Adjust a sprite's animation values for correct scaling
static func adjust_sprite_animation(sprite: Sprite2D) -> void:
	if sprite == null:
		return
		
	# Make sure the sprite is using nearest-neighbor filtering
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# Adjust a collision shape for the current scale
static func adjust_collision_shape(shape: CollisionShape2D) -> void:
	if shape == null:
		return
		
	var scale_factor = get_scale_factor()
	
	# Adjust different shape types appropriately
	if shape.shape is CircleShape2D:
		# For circle shapes, scale the radius
		shape.shape.radius *= scale_factor
	elif shape.shape is RectangleShape2D:
		# For rectangle shapes, scale the extents
		shape.shape.size *= scale_factor
	# Add more shape types as needed 
