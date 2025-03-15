extends Node

# Scale factor for game elements
const SCALE_FACTOR = 2.0

# Nodes that should be excluded from scaling (UI elements)
var exclude_scaling = ["CanvasLayer", "TitleLabel", "Camera2D"]

func _ready():
	# Wait for one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Apply scale to the game world
	scale_game_elements()
	
	# Adjust positions of UI elements to account for scaling
	adjust_ui_positions()
	
	# Apply pixel-perfect texture filtering
	apply_pixel_perfect_filter()
	
	# Connect to the node added signal to scale any dynamically created objects
	get_tree().node_added.connect(_on_node_added)

func _process(_delta):
	# This runs every frame to ensure texture filtering is correctly applied
	# This is needed because some nodes might adjust their filtering during gameplay
	enforce_texture_filter_on_tilemaps()

func scale_game_elements():
	# Get the main scene (assumed to be the parent)
	var main_scene = get_parent()
	
	# Scale the map
	if main_scene.has_node("IsometricMap"):
		var map = main_scene.get_node("IsometricMap")
		map.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
		apply_nearest_neighbor_filter(map)
	
	# Scale the player
	if main_scene.has_node("nose"):
		var player = main_scene.get_node("nose")
		player.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
		apply_nearest_neighbor_filter(player)
	
	# Scale all smell objects and other elements
	for child in main_scene.get_children():
		scale_node_if_needed(child)

func scale_all_smells(parent_node):
	# Find and scale all smell objects
	for child in parent_node.get_children():
		scale_node_if_needed(child)
		
		# Recursively check children
		if child.get_child_count() > 0 and not (child is CanvasLayer):
			scale_all_smells(child)

func scale_node_if_needed(node):
	# Skip nodes that should not be scaled
	for exclude_name in exclude_scaling:
		if exclude_name in node.name or node is CanvasLayer:
			return
	
	# Scale smell objects
	if "Smell" in node.name:
		node.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
		apply_nearest_neighbor_filter(node)
	
	# Scale map objects
	elif "Map" in node.name:
		node.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
		apply_nearest_neighbor_filter(node)
	
	# Scale player object
	elif node.name == "nose":
		node.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
		apply_nearest_neighbor_filter(node)

# Apply nearest neighbor filtering to a node and its children
func apply_nearest_neighbor_filter(node):
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

# Apply pixel-perfect filtering to all nodes in the scene
func apply_pixel_perfect_filter():
	# Find the IsometricMap node 
	var main_scene = get_parent()
	if main_scene.has_node("IsometricMap"):
		var map = main_scene.get_node("IsometricMap")
		
		# Directly set texture filter on all children
		for child in map.get_children():
			# Check for different types of tilemap nodes
			if "TileMapLayer" in child.get_class() or "FloorMap" in child.name:
				child.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			
			# Apply to all children of this node as well
			for subchild in child.get_children():
				if subchild.has_method("set_texture_filter"):
					subchild.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Find all TileMapLayer nodes in the entire scene
	find_and_fix_all_tilemaps(get_tree().root)

# Recursively find and fix all TileMapLayer nodes in the scene
func find_and_fix_all_tilemaps(node):
	# Check if this is a TileMap or TileMapLayer
	if node is TileMap or "TileMapLayer" in node.get_class() or "FloorMap" in node.name:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Recursively process all children
	for child in node.get_children():
		find_and_fix_all_tilemaps(child)

# This function runs every frame to ensure tilemap filtering is always correct
func enforce_texture_filter_on_tilemaps():
	var main_scene = get_parent()
	if main_scene.has_node("IsometricMap"):
		var map = main_scene.get_node("IsometricMap")
		
		# Force nearest neighbor filtering on all TileMapLayer nodes
		for child in map.get_children():
			if "TileMapLayer" in child.get_class() or "FloorMap" in child.name:
				child.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func adjust_ui_positions():
	# Adjust title label position to account for scaling
	var main_scene = get_parent()
	if main_scene.has_node("TitleLabel"):
		var title_label = main_scene.get_node("TitleLabel")
		# Move the title label upward to avoid overlap with scaled game elements
		title_label.position.y -= 50

func _on_node_added(node):
	# Scale any new nodes that are added dynamically
	if node.get_parent() == get_parent():
		scale_node_if_needed(node)
		
	# Apply pixel-perfect filtering to new nodes
	if node.has_method("set_texture_filter"):
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
