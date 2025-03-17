extends Node

# Scale factor for game elements - should match window/stretch/scale in project settings
const SCALE_FACTOR = 2.0

# Nodes that should be excluded from scaling (UI elements)
static var exclude_scaling = ["CanvasLayer", "TitleLabel", "Camera2D"]

# Signals for scale changes
signal scale_changed(new_scale)

# Default scale tracker
var is_scaled_applied = false

# Called when the node enters the scene tree for the first time
func _ready():
	# Verify that our scale factor matches the project settings
	var settings_scale = ProjectSettings.get_setting("display/window/stretch/scale", 1.0)
	if settings_scale != SCALE_FACTOR:
		push_warning("ScaleHelper SCALE_FACTOR (%s) doesn't match project settings stretch scale (%s)" % [SCALE_FACTOR, settings_scale])

# Get the current scale factor
static func get_scale_factor() -> float:
	return SCALE_FACTOR

# Reset scale state - called when restarting the level
func reset_scale():
	is_scaled_applied = false
	emit_signal("scale_changed", SCALE_FACTOR)

# Scale a single value
static func scale_value(value: float) -> float:
	return value * SCALE_FACTOR

# Scale a Vector2 position
static func scale_position(position: Vector2) -> Vector2:
	return position * SCALE_FACTOR

# Scale a size/dimension
static func scale_size(size: Vector2) -> Vector2:
	return size * SCALE_FACTOR

# Convert an editor position to runtime position
static func editor_to_runtime(position: Vector2) -> Vector2:
	# No conversion needed with built-in stretch system - viewport coordinates remain the same
	return position

# Convert a runtime position back to editor position
static func runtime_to_editor(position: Vector2) -> Vector2:
	# No conversion needed with built-in stretch system - viewport coordinates remain the same
	return position

# Determine if a value has already been scaled
static func is_scaled(node: Node2D) -> bool:
	if node == null:
		return false
		
	# With built-in scaling, we don't manually scale nodes anymore
	# This function is kept for compatibility
	return true

# Convert a node's editor position to the correct runtime position
static func convert_editor_to_runtime_position(node: Node2D) -> void:
	if node == null:
		return
		
	# Skip nodes that should be excluded
	for exclude_name in exclude_scaling:
		if exclude_name in node.name:
			return
	
	# Check if it's a CanvasLayer or derived from it
	if node.get_class() == "CanvasLayer" or "CanvasLayer" in node.get_class():
		return
			
	# With the new built-in stretch system, we don't need to manually
	# scale node positions. This function is kept for compatibility.
	# 
	# If you're positioning nodes in the editor, they'll appear at
	# the same position in the game.
	pass

# Apply nearest neighbor filtering to a node and its children
static func apply_nearest_neighbor_filter(node) -> void:
	# With viewport stretch mode, we don't need to manually set texture filtering
	# However, we'll keep this for compatibility or custom cases
	# Check if this node is a sprite
	if node is Sprite2D or node is AnimatedSprite2D:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# For TileMap and TileMapLayer nodes
	if node is TileMap:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Some Godot 4 projects use TileMapLayer
	if "TileMapLayer" in node.get_class() or "TileMap" in node.name or "FloorMap" in node.name:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Recursively apply to all children
	for child in node.get_children():
		apply_nearest_neighbor_filter(child)

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
		
	# With built-in stretch mode, Godot handles scaling collision shapes automatically
	# This function is kept for compatibility with any custom cases
	pass

# Find and apply nearest neighbor filtering to all tilemaps in a node and its children
static func find_and_fix_all_tilemaps(node) -> void:
	# Check if this is a TileMap or TileMapLayer
	if node is TileMap or "TileMapLayer" in node.get_class() or "FloorMap" in node.name:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Recursively process all children
	for child in node.get_children():
		find_and_fix_all_tilemaps(child)

# Check if a node should be excluded from scaling
static func should_exclude_from_scaling(node: Node) -> bool:
	if node == null:
		return true
		
	# Check against exclude list
	for exclude_name in exclude_scaling:
		if exclude_name in node.name:
			return true
			
	# Check if it's a CanvasLayer
	if node is CanvasLayer or node.get_class() == "CanvasLayer" or "CanvasLayer" in node.get_class():
		return true
			
	return false
