extends Node2D

# UI scene for displaying messages
var ui_scene = preload("res://scenes/UI/UI.tscn")
var ui_instance

# Isometric map constants - match these with the player script
const TILE_WIDTH = 32
const TILE_HEIGHT = 16
const MIN_TILE_X = 0
const MAX_TILE_X = 21
const MIN_TILE_Y = 0
const MAX_TILE_Y = 21

# Debug mode - set to false when finished testing
var debug_mode = true

func _ready():
	# Create UI instance
	ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	
	# Connect player's smell detection signal to UI
	if has_node("nose"):
		$nose.connect("smell_detected", _on_smell_detected)
		if debug_mode:
			print("Connected player smell detection signal to UI")
	else:
		if debug_mode:
			print("Error: Player node 'nose' not found")
	
	# Connect to smell animation completed signals
	connect_smell_signals()
		
	# Position smells on the isometric map if needed
	position_smells_isometrically()
	
	# Initialize isometric sorter
	initialize_isometric_sorting()
	
	if debug_mode:
		print("Main scene ready with isometric map")
		print("Map boundaries: ", get_map_boundaries())
		print("Available smell objects:", count_smell_objects())

# Connect to all smell objects' animation_completed signals
func connect_smell_signals():
	var smell_nodes = get_tree().get_nodes_in_group("smell")
	
	for smell in smell_nodes:
		if smell.has_signal("animation_completed") and not smell.is_connected("animation_completed", _on_smell_animation_completed):
			smell.connect("animation_completed", _on_smell_animation_completed)
			
			if debug_mode:
				print("Connected to smell animation signal: " + smell.smell_name)

# Function to get map boundaries - can be called by child nodes
func get_map_boundaries():
	# Default map boundaries for 21x21 map, anchored at top
	var bounds = {
		"min_x": -5,
		"max_x": 4,
		"min_y": -5,
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
	
	# Adjust z-index for each smell based on its isometric position
	for smell in smell_nodes:
		# Set proper z-index based on y position
		smell.z_index = int(smell.position.y)
		
		if debug_mode:
			print("Positioned smell: ", smell.name, " at z-index ", smell.z_index)

# Function to initialize the isometric sorting system
func initialize_isometric_sorting():
	if has_node("IsometricSorter"):
		var sorter = $IsometricSorter
		
		# Add all objects that should be sorted (player, smells, etc.)
		if has_node("nose"):
			sorter.add_sorted_object($nose)
			
		# Add smell objects
		var smell_nodes = get_tree().get_nodes_in_group("smell")
		for smell in smell_nodes:
			sorter.add_sorted_object(smell)
		
		if debug_mode:
			print("Initialized isometric sorting with objects")

# Handle smell detection from player
func _on_smell_detected(smell_text, smell_type):
	# Debug output with more details - always show regardless of debug_mode
	print("SMELL SIGNAL: Main received smell_detected signal from player")
	print("SMELL SIGNAL: - Message: '" + smell_text + "'")
	print("SMELL SIGNAL: - Type: '" + smell_type + "'")
	print("SMELL SIGNAL: - UI instance exists: " + str(is_instance_valid(ui_instance)))
	
	# We don't immediately show the message as the smell animation will emit its
	# own signal when it's ready to show the message

# Handle smell animation completed signal
func _on_smell_animation_completed(smell_data):
	# Debug output with more details - always show regardless of debug_mode
	print("SMELL SIGNAL: Smell animation_completed signal received")
	print("SMELL SIGNAL: - Data received: " + str(smell_data))
	
	# Validate smell data
	if not smell_data is Dictionary:
		print("SMELL SIGNAL ERROR: smell_data is not a Dictionary: " + str(smell_data))
		return
		
	if not smell_data.has("message") or not smell_data.has("type"):
		print("SMELL SIGNAL ERROR: smell_data missing required fields: " + str(smell_data))
		return
	
	print("SMELL SIGNAL: - Message: '" + smell_data.message + "'")
	print("SMELL SIGNAL: - Type: '" + smell_data.type + "'")
	print("SMELL SIGNAL: - UI instance exists: " + str(is_instance_valid(ui_instance)))
	
	# Now show the UI message
	if ui_instance:
		print("SMELL SIGNAL: Calling ui_instance.show_smell_message()")
		ui_instance.show_smell_message(smell_data.message, smell_data.type)
	else:
		print("SMELL SIGNAL ERROR: UI instance not found, can't display smell message")

# Count the number of smell objects in the scene
func count_smell_objects():
	var counts = {
		"total": 0,
		"good": 0,
		"bad": 0,
		"epic": 0,
		"neutral": 0,
		"detected": 0,  # Smells that have been found/detected
		"collected": 0  # Smells that have been fully collected
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

# Get the floor tile at a specific world position
# Returns the tile coordinates or null if no tile exists
func get_floor_tile_at_position(world_pos: Vector2) -> Vector2i:
	if has_node("IsometricMap") and $IsometricMap.has_node("FloorMap"):
		var floor_map = $IsometricMap.get_node("FloorMap")
		if floor_map:
			# Convert world position to tile coordinates
			var tile_pos = IsometricUtils.world_to_tile(world_pos, TILE_WIDTH, TILE_HEIGHT)
			
			if debug_mode:
				print("Checking for floor tile at: ", tile_pos, " (from world pos: ", world_pos, ")")
				print("FloorMap class: ", floor_map.get_class())
				print("Available methods: has_cell:", floor_map.has_method("has_cell"), 
					", get_cell_source_id:", floor_map.has_method("get_cell_source_id"),
					", get_cell:", floor_map.has_method("get_cell"))
			
			# First try: check if TileMapLayer has has_cell method (more reliable)
			if floor_map.has_method("has_cell"):
				if floor_map.has_cell(tile_pos):
					if debug_mode:
						print("Found floor tile at position using has_cell: ", tile_pos)
					return tile_pos
			# Second try: use get_cell_source_id method
			elif floor_map.has_method("get_cell_source_id"):
				# TileMapLayer's get_cell_source_id only expects one argument (the tile position)
				var source_id = -1
				# Wrap in try/catch in case the API has changed
				if OS.is_debug_build():
					source_id = floor_map.get_cell_source_id(tile_pos)
				else:
					# In production, use try/catch to avoid crashes
					source_id = floor_map.call("get_cell_source_id", tile_pos)
				
				if source_id != -1:  # -1 means no tile
					if debug_mode:
						print("Found floor tile at position using get_cell_source_id: ", tile_pos)
					return tile_pos
			# Last resort: Try get_cell method
			elif floor_map.has_method("get_cell"):
				var cell_value = floor_map.get_cell(tile_pos)
				if cell_value != -1:  # -1 usually means empty
					if debug_mode:
						print("Found floor tile at position using get_cell: ", tile_pos)
					return tile_pos
			
			if debug_mode:
				print("No floor tile found at position: ", tile_pos)
	else:
		if debug_mode:
			if not has_node("IsometricMap"):
				print("IsometricMap node not found!")
			elif not $IsometricMap.has_node("FloorMap"):
				print("FloorMap node not found in IsometricMap!")
	
	# Return an invalid position if no tile found
	return Vector2i(-1, -1) 
