extends Node

# This script handles the game scaling and applies it to all relevant nodes
# Now uses the consolidated ScaleHelper class

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

# We no longer need to run this every frame - remove _process
# Instead we'll ensure textures are set correctly in the initial setup

func scale_game_elements():
	# Get the main scene (assumed to be the parent)
	var main_scene = get_parent()
	
	# Scale the map
	if main_scene.has_node("IsometricMap"):
		var map = main_scene.get_node("IsometricMap")
		map.scale = Vector2(ScaleHelper.SCALE_FACTOR, ScaleHelper.SCALE_FACTOR)
		ScaleHelper.apply_nearest_neighbor_filter(map)
	
	# Scale the player
	if main_scene.has_node("nose"):
		var player = main_scene.get_node("nose")
		ScaleHelper.convert_editor_to_runtime_position(player)
		ScaleHelper.apply_nearest_neighbor_filter(player)
	
	# Scale all smell objects and other elements
	for child in main_scene.get_children():
		scale_node_if_needed(child)
	
	# Emit signal that scaling has been applied
	ScaleHelper.scale_changed.emit(ScaleHelper.SCALE_FACTOR)

func scale_all_smells(parent_node):
	# Find and scale all smell objects
	for child in parent_node.get_children():
		scale_node_if_needed(child)
		
		# Recursively check children
		if child.get_child_count() > 0 and not (child is CanvasLayer):
			scale_all_smells(child)

func scale_node_if_needed(node):
	# Skip nodes that should be excluded
	if ScaleHelper.should_exclude_from_scaling(node):
		return
	
	# Scale smell objects
	if "Smell" in node.name:
		ScaleHelper.convert_editor_to_runtime_position(node)
		ScaleHelper.apply_nearest_neighbor_filter(node)
		
	# Scale MapObjects node and its children
	elif node.name == "MapObjects":
		ScaleHelper.convert_editor_to_runtime_position(node)
		ScaleHelper.apply_nearest_neighbor_filter(node)
		
		# Only apply texture filtering to children, not additional scaling
		for child in node.get_children():
			if child is Sprite2D:
				ScaleHelper.apply_nearest_neighbor_filter(child)
	
	# Scale player object
	elif node.name == "nose":
		ScaleHelper.convert_editor_to_runtime_position(node)
		ScaleHelper.apply_nearest_neighbor_filter(node)

func apply_pixel_perfect_filter():
	# Find the IsometricMap node 
	var main_scene = get_parent()
	if main_scene.has_node("IsometricMap"):
		var map = main_scene.get_node("IsometricMap")
		
		# Apply nearest neighbor filtering to all tilemaps recursively
		ScaleHelper.find_and_fix_all_tilemaps(map)
	
	# Find all TileMapLayer nodes in the entire scene
	ScaleHelper.find_and_fix_all_tilemaps(get_tree().root)

func adjust_ui_positions():
	# Adjust title label position to account for scaling
	var main_scene = get_parent()
	if main_scene.has_node("TitleLabel"):
		var title_label = main_scene.get_node("TitleLabel")
		# Move the title label upward to avoid overlap with scaled game elements
		title_label.position.y -= ScaleHelper.scale_value(50)

func _on_node_added(node):
	# Scale any new nodes that are added dynamically
	if node.get_parent() == get_parent() and node is Node2D:
		ScaleHelper.convert_editor_to_runtime_position(node)
		
	# Apply pixel-perfect filtering to new nodes
	if node.has_method("set_texture_filter"):
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
