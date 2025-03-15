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
	if $nose:
		$nose.connect("smell_detected", _on_smell_detected)
		
	# Position smells on the isometric map if needed
	position_smells_isometrically()
	
	# Initialize isometric sorter
	initialize_isometric_sorting()
	
	if debug_mode:
		print("Main scene ready with isometric map")
		print("Map boundaries: ", get_map_boundaries())

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
			var map_rect = floor_map.get_used_rect()
			if map_rect:
				# Use the tilemap's actual size
				bounds.min_x = map_rect.position.x
				bounds.min_y = map_rect.position.y
				bounds.max_x = map_rect.position.x + map_rect.size.x - 1
				bounds.max_y = map_rect.position.y + map_rect.size.y - 1
				
				if debug_mode:
					print("Map boundaries from FloorMap: ", bounds)
	
	return bounds

# Initialize the isometric sorter for proper Z-index sorting
func initialize_isometric_sorting():
	if has_node("IsometricSorter"):
		var sorter = $IsometricSorter
		
		# Register the player node
		if has_node("nose"):
			sorter.register_node($nose)
		
		# Register all smell nodes
		for smell in get_tree().get_nodes_in_group("smells"):
			if smell is Node2D:
				sorter.register_node(smell)
		
		if debug_mode:
			print("Isometric sorter initialized")

# Position smells on the isometric grid when game starts
func position_smells_isometrically():
	# Find all smell nodes in the scene
	var smells = get_tree().get_nodes_in_group("smells")
	if smells.size() == 0:
		# If no smells are in a group, find them by class
		for child in get_children():
			if child is Smell:
				smells.append(child)
				# Add to group for future reference
				child.add_to_group("smells")
	
	# Adjust smell positions for isometric grid if needed
	for smell in smells:
		# Enable Y-sorting for proper isometric depth
		smell.y_sort_enabled = true
		
		# Convert from orthogonal to isometric coordinates if needed
		var current_position = smell.global_position
		var tile_pos = IsometricUtils.world_to_tile(current_position, TILE_WIDTH, TILE_HEIGHT)
		var iso_pos = IsometricUtils.tile_to_world(tile_pos, TILE_WIDTH, TILE_HEIGHT)
		
		# Only update if there's a significant difference
		if (current_position - iso_pos).length() > 5:
			smell.global_position = iso_pos
			if debug_mode:
				print("Repositioned smell from ", current_position, " to ", iso_pos)
		
		# Log positions for debugging
		if debug_mode:
			print("Smell positioned at: ", smell.global_position)

# Called when the player detects a smell
func _on_smell_detected(smell_text, smell_type):
	# Pass the smell message to the UI
	ui_instance.show_smell_message(smell_text, smell_type) 

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
