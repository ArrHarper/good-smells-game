extends Node

# This script handles the game scaling and applies it to all relevant nodes
# Now uses Godot's built-in stretch system with the ScaleHelper for compatibility

# Tracking variable to prevent double-scaling on restart
var has_scaled = false

func _ready():
	# Wait for one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Connect to the ScaleHelper's scale_changed signal
	var scale_helper = get_node_or_null("/root/ScaleHelper")
	if scale_helper:
		scale_helper.scale_changed.connect(_on_scale_changed)
	
	# Apply pixel-perfect texture filtering to all nodes
	# Even with stretch mode, we still want to ensure proper filtering
	apply_pixel_perfect_filter()
	
	# Connect to the node added signal to apply filtering to any dynamically created objects
	get_tree().node_added.connect(_on_node_added)

# Handler for scale changes (called when restarting)
func _on_scale_changed(new_scale):
	has_scaled = false
	
	# Re-apply pixel-perfect filtering
	apply_pixel_perfect_filter()

func apply_pixel_perfect_filter():
	# Find the IsometricMap node 
	var main_scene = get_parent()
	if main_scene.has_node("IsometricMap"):
		var map = main_scene.get_node("IsometricMap")
		
		# Apply nearest neighbor filtering to all tilemaps recursively
		ScaleHelper.find_and_fix_all_tilemaps(map)
	
	# Find all TileMapLayer nodes in the entire scene
	ScaleHelper.find_and_fix_all_tilemaps(get_tree().root)
	
	# Apply pixel-perfect filtering to all sprite nodes
	apply_filtering_to_sprites(get_tree().root)

func apply_filtering_to_sprites(node):
	# Apply nearest neighbor filtering to sprites
	if node is Sprite2D or node is AnimatedSprite2D:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Recursively apply to all children
	for child in node.get_children():
		apply_filtering_to_sprites(child)

func _on_node_added(node):
	# Apply pixel-perfect filtering to new nodes
	if node.has_method("set_texture_filter"):
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
