@tool
extends Node2D

# Isometric grid constants (match with testing.gd)
const TILE_WIDTH = 32
const TILE_HEIGHT = 16
const GRID_SIZE = 21 # Matching the MAX_TILE values in testing.gd

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
	# Draw horizontal grid lines - from 0 to GRID_SIZE to avoid doubling
	for y in range(0, GRID_SIZE + 1):
		var start = Vector2(-y * TILE_WIDTH / 2, y * TILE_HEIGHT / 2) + grid_offset
		var end = Vector2((GRID_SIZE - y) * TILE_WIDTH / 2, (GRID_SIZE + y) * TILE_HEIGHT / 2) + grid_offset
		draw_line(start, end, grid_color, grid_thickness)
	
	# Draw vertical grid lines - from 0 to GRID_SIZE to avoid doubling
	for x in range(0, GRID_SIZE + 1):
		var start = Vector2(x * TILE_WIDTH / 2, x * TILE_HEIGHT / 2) + grid_offset
		var end = Vector2((x - GRID_SIZE) * TILE_WIDTH / 2, (x + GRID_SIZE) * TILE_HEIGHT / 2) + grid_offset
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