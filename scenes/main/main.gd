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
		"min_x": -20,
		"max_x": 20,
		"min_y": -20,
		"max_y": 20
	}
	
	# If we have a reference to the tilemap, try to get the actual boundaries
	if has_node("IsometricMap") and $IsometricMap.has_method("get_used_rect"):
		var map_rect = $IsometricMap.get_used_rect()
		if map_rect:
			# Use the tilemap's actual size
			bounds.min_x = map_rect.position.x
			bounds.min_y = map_rect.position.y
			bounds.max_x = map_rect.position.x + map_rect.size.x - 1
			bounds.max_y = map_rect.position.y + map_rect.size.y - 1
			
			if debug_mode:
				print("Map boundaries from tilemap: ", bounds)
	
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
		var tile_pos = Iso.world_to_tile(current_position, TILE_WIDTH, TILE_HEIGHT)
		var iso_pos = Iso.tile_to_world(tile_pos, TILE_WIDTH, TILE_HEIGHT)
		
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