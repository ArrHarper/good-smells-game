@tool
extends Node2D

# Grid drawing properties
var grid_color = Color(0.3, 0.7, 1.0, 0.7) # Increased alpha for better visibility
var grid_thickness = 1.0
var show_grid = true
var grid_offset = Vector2.ZERO # Can be adjusted if grid positioning needs tweaking

func _ready():
	# Set this to process drawing
	set_process(true)

func _process(_delta):
	# Force redraw when processing
	queue_redraw()

func _draw():
	if not show_grid:
		return
		
	# Draw the isometric grid
	draw_isometric_grid()

func draw_isometric_grid():
	# Get centralized values
	var tile_width = ProjectSettings.get_setting("game_settings/tile/width", 32)
	var tile_height = ProjectSettings.get_setting("game_settings/tile/height", 16)
	var grid_size = ProjectSettings.get_setting("game_settings/grid/size_x", 21)
	
	# Draw horizontal grid lines - from 0 to grid_size to avoid doubling
	for y in range(0, grid_size + 1):
		var start = Vector2(-y * tile_width / 2, y * tile_height / 2) + grid_offset
		var end = Vector2((grid_size - y) * tile_width / 2, (grid_size + y) * tile_height / 2) + grid_offset
		draw_line(start, end, grid_color, grid_thickness)
	
	# Draw vertical grid lines - from 0 to grid_size to avoid doubling
	for x in range(0, grid_size + 1):
		var start = Vector2(x * tile_width / 2, x * tile_height / 2) + grid_offset
		var end = Vector2((x - grid_size) * tile_width / 2, (x + grid_size) * tile_height / 2) + grid_offset
		draw_line(start, end, grid_color, grid_thickness)

# Toggle grid visibility
func toggle_grid():
	show_grid = !show_grid
	queue_redraw()
	
	# Print visibility state to help debugging
	if show_grid:
		print("Grid visibility turned ON")
	else:
		print("Grid visibility turned OFF")