extends Node2D

# UI scene for displaying messages
var ui_scene = preload("res://scenes/UI/UI.tscn")
var ui_instance

# Map boundaries - min values hardcoded, max values from project settings
const MIN_TILE_X = 0
const MIN_TILE_Y = 0

# Debug mode - set to true for testing scene
@export var debug_mode = true

# Reference to the isometric grid
var isometric_grid

func _ready():
	# Set window title to indicate testing mode
	DisplayServer.window_set_title("Good Smells - TESTING MODE")
	
	# Configure TileSet error handling
	if Engine.has_singleton("ErrorHandler"):
		var error_handler = Engine.get_singleton("ErrorHandler")
		error_handler.register_tilemaps(self)
		error_handler.suppress_tileset_errors()
	
	# Create UI instance
	ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	
	# Get reference to isometric grid
	isometric_grid = $IsometricGrid
	
	# Set initial button text based on grid visibility
	update_grid_button_text()
	
	# Connect to smell animation completed signals
	connect_smell_signals()
		
	# Position smells on the isometric map if needed
	position_smells_isometrically()
	
	# Setup additional testing specific functionality
	setup_testing_environment()
	
	if debug_mode:
		print("TESTING scene ready with isometric map")
		print("Map boundaries: ", get_map_boundaries())
		print("Available smell objects:", count_smell_objects())
		print("Press G to toggle the isometric grid visibility")

# Setup additional testing environment features
func setup_testing_environment():
	# Add testing label to indicate this is a testing scene
	if has_node("TitleLabel"):
		$TitleLabel.text = "TESTING SCENE"
		$TitleLabel.modulate = Color(1, 0.5, 0.5, 1) # Reddish tint for testing
	
	# Log message to help differentiate from main scene in console
	print("=== TESTING SCENE INITIALIZED ===")
	print("This is a testing environment for game mechanics.")
	print("Any changes made here won't affect the main game.")

# Connect to all smell objects' animation_completed signals
func connect_smell_signals():
	var smell_nodes = get_tree().get_nodes_in_group("smell")
	
	for smell in smell_nodes:
		# Connect to animation_completed signal
		if smell.has_signal("animation_completed") and not smell.is_connected("animation_completed", _on_smell_animation_completed):
			smell.connect("animation_completed", _on_smell_animation_completed)
			
			if debug_mode:
				print("Connected to smell animation signal: " + smell.smell_name)
		
		# No need to connect to smell_detected signal here as it's handled by the player now

# Function to get map boundaries - can be called by child nodes
func get_map_boundaries():
	# Default map boundaries for 21x21 map, anchored at top
	var bounds = {
		"min_x": - 5,
		"max_x": 4,
		"min_y": - 5,
		"max_y": 4
	}
	
	# If we have a reference to the IsometricMap and its FloorMap, try to get the actual boundaries
	if has_node("IsometricMap") and $IsometricMap.has_node("FloorMap"):
		var floor_map = $IsometricMap.get_node("FloorMap")
		if floor_map and floor_map.has_method("get_used_rect"):
			var rect = floor_map.get_used_rect()
			bounds = {
				"min_x": rect.position.x,
				"max_x": rect.position.x + rect.size.x - 1,
				"min_y": rect.position.y,
				"max_y": rect.position.y + rect.size.y - 1
			}
	
	return bounds

# Function to position all smell objects on the isometric map properly
func position_smells_isometrically():
	# Get all smell objects in the scene
	var smell_nodes = get_tree().get_nodes_in_group("smell")
	
	if smell_nodes.is_empty():
		# If no smell nodes were found in the group, try to find them by type
		# This handles cases where smell objects might not be in the correct group yet
		var all_nodes = get_tree().get_nodes_in_group("smell")
		for node in all_nodes:
			if node is Smell:
				smell_nodes.append(node)
		
		# Also find any child smell nodes in this scene
		for child in get_children():
			if child is Smell:
				smell_nodes.append(child)
	
	if debug_mode:
		print("Found ", smell_nodes.size(), " smell objects to position")
	
	# No longer setting z-index dynamically. Smells will use their scene-defined z-index values
	if debug_mode:
		for smell in smell_nodes:
			print("Smell: ", smell.name, " with z-index ", smell.z_index)

# Handle smell detection from player - This is now unused as messages appear above player
func _on_smell_detected(smell_text, smell_type):
	if debug_mode:
		print("SMELL SIGNAL: Main received smell_detected signal from player")
		print("SMELL SIGNAL: - Message: '" + smell_text + "'")
		print("SMELL SIGNAL: - Type: '" + smell_type + "'")
	
	# We no longer show the message in the UI as it appears above the player

# Handle smell animation completed signal - This is now unused as messages appear above player
func _on_smell_animation_completed(smell_data):
	if debug_mode:
		print("SMELL SIGNAL: Smell animation_completed signal received")
		print("SMELL SIGNAL: - Data received: " + str(smell_data))
	
	# We no longer show the message in the UI as it appears above the player

# Count the number of smell objects in the scene
func count_smell_objects():
	var counts = {
		"total": 0,
		"good": 0,
		"bad": 0,
		"epic": 0,
		"neutral": 0,
		"detected": 0, # Smells that have been found/detected
		"collected": 0 # Smells that have been fully collected
	}
	
	var smell_nodes = get_tree().get_nodes_in_group("smell")
	counts["total"] = smell_nodes.size()
	
	for smell in smell_nodes:
		if smell is Smell:
			var type = smell.smell_type
			if type in counts:
				counts[type] += 1
				
			# Count detected and collected smells
			if "detected" in smell and smell.detected:
				counts["detected"] += 1
				
			if "collected" in smell and smell.collected:
				counts["collected"] += 1
	
	return counts

# Count the number of collectible objects in the scene
func count_collectible_objects():
	var counts = {
		"total": 0,
		"common": 0,
		"rare": 0,
		"epic": 0,
		"special": 0,
		"detected": 0, # Collectibles that have been found/detected
		"collected": 0 # Collectibles that have been fully collected
	}
	
	var collectible_nodes = get_tree().get_nodes_in_group("collectible")
	counts["total"] = collectible_nodes.size()
	
	for collectible in collectible_nodes:
		if collectible is Collectible:
			var type = collectible.collectible_type
			if type in counts:
				counts[type] += 1
				
			# Count detected and collected collectibles
			if "detected" in collectible and collectible.detected:
				counts["detected"] += 1
				
			if "collected" in collectible and collectible.collected:
				counts["collected"] += 1
	
	return counts

# Get the floor tile at a specific world position
# Returns the tile coordinates or null if no tile exists
func get_floor_tile_at_position(world_pos: Vector2) -> Vector2i:
	if has_node("IsometricMap") and $IsometricMap.has_node("FloorMap"):
		var floor_map = $IsometricMap.get_node("FloorMap")
		if floor_map:
			# Activate error filtering if available
			if Engine.has_singleton("ErrorHandler"):
				var error_handler = Engine.get_singleton("ErrorHandler")
				error_handler.filter_message("Checking floor tiles")
			
			# Convert world position to tile coordinates
			var tile_pos = IsometricUtils.world_to_tile(world_pos)
			
			# Validate within map boundaries
			tile_pos.x = clampi(tile_pos.x, MIN_TILE_X, ProjectSettings.get_setting("game_settings/grid/size_x", 21))
			tile_pos.y = clampi(tile_pos.y, MIN_TILE_Y, ProjectSettings.get_setting("game_settings/grid/size_y", 21))
			
			if debug_mode:
				print("Checking for floor tile at: ", tile_pos, " (from world pos: ", world_pos, ")")
				print("FloorMap class: ", floor_map.get_class())
				print("Available methods: has_cell:", floor_map.has_method("has_cell"),
					", get_cell_source_id:", floor_map.has_method("get_cell_source_id"),
					", get_cell:", floor_map.has_method("get_cell"))
			
			# Try different methods to check for a tile
			var found_tile = false
			
			# First try: check if TileMapLayer has has_cell method (more reliable)
			if floor_map.has_method("has_cell"):
				# Safely call method
				if floor_map.has_cell(tile_pos):
					found_tile = true
					if debug_mode:
						print("Found floor tile using has_cell at: ", tile_pos)
					return tile_pos
			
			# Second try: use get_cell_source_id method
			if not found_tile and floor_map.has_method("get_cell_source_id"):
				var source_id = -1
				# Use call to safely handle API differences
				source_id = floor_map.call("get_cell_source_id", tile_pos)
				
				if source_id != -1: # -1 means no tile
					found_tile = true
					if debug_mode:
						print("Found floor tile using get_cell_source_id at: ", tile_pos)
					return tile_pos
	
	return Vector2i(-1, -1) # Return invalid coordinates if no tile found

# Handle input for scene switching and grid toggling
func _input(event):
	# Scene switching
	if event.is_action_pressed("switch_scene"):
		print("Cycling through scenes")
		get_node("/root/SceneSwitcher").cycle_scenes()
	
	# Toggle isometric grid visibility with the G key
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			isometric_grid.toggle_grid()
			update_grid_button_text()

# Called when the grid toggle button is pressed
func _on_grid_toggle_button_pressed():
	isometric_grid.toggle_grid()
	update_grid_button_text()

# Updates the grid button text to match the current grid visibility state
func update_grid_button_text():
	var button = $CanvasLayer/GridToggleButton
	if button:
		button.text = "Grid: " + ("ON" if isometric_grid.show_grid else "OFF")

func get_tile_pos_from_world(world_pos: Vector2) -> Vector2i:
	# Use the IsometricUtils singleton to handle the conversion with centralized values
	var tile_pos = IsometricUtils.world_to_tile(world_pos)
	
	# Validate within map boundaries
	tile_pos.x = clampi(tile_pos.x, MIN_TILE_X, ProjectSettings.get_setting("game_settings/grid/size_x", 21))
	tile_pos.y = clampi(tile_pos.y, MIN_TILE_Y, ProjectSettings.get_setting("game_settings/grid/size_y", 21))
	
	return tile_pos
