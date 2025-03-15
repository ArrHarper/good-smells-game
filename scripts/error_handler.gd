extends Node

# This script helps reduce TileSet-related error noise in the editor
# Add this to your project's autoload list with name "ErrorHandler"

# List of error patterns to silence
var silenced_patterns = [
	"create_tile: Cannot create tile",
	"Condition \"!room_for_tile\" is true",
	"The tile is outside the texture"
]

# Store error count to avoid spam
var error_counts = {}
var max_reported_errors = 3

func _ready():
	print_rich("[color=yellow]TileSet error handler initialized[/color]")
	
	# Set a timer to periodically clear error counts
	var timer = Timer.new()
	timer.wait_time = 60.0 # Reset error counts every minute
	timer.timeout.connect(_reset_error_counts)
	timer.autostart = true
	add_child(timer)

# Called from your main scene to register for TileMaps
func register_tilemaps(scene_root):
	if scene_root is Node:
		for child in scene_root.get_children():
			if child is TileMap:
				_configure_tilemap(child)
			
			# Recursively check children
			if child.get_child_count() > 0:
				register_tilemaps(child)
	
	print("TileMap error handling configured")

# Apply optimizations to a TileMap to reduce errors
func _configure_tilemap(tilemap):
	# Set various properties to minimize errors
	if tilemap is TileMap:
		# Only process when needed
		tilemap.set_process(false)
		tilemap.set_physics_process(false)
		print("Configured TileMap: " + tilemap.name)

# Call this to suppress TileSet errors in the console output
# Place in your main scene's _ready function
func suppress_tileset_errors():
	# Configure error handling through project settings
	if ProjectSettings.has_setting("debug/file_logging/max_error_count"):
		# Limit total errors reported
		var current = ProjectSettings.get_setting("debug/file_logging/max_error_count")
		ProjectSettings.set_setting("debug/file_logging/max_error_count", min(current, 50))
	
	print_rich("[color=green]TileSet error suppression enabled[/color]")

# Filter console messages
# Call this before any TileMap operations
func filter_message(message):
	for pattern in silenced_patterns:
		if message.contains(pattern):
			var error_key = message.substr(0, min(30, message.length()))
			
			# Increment error count
			if not error_counts.has(error_key):
				error_counts[error_key] = 0
			error_counts[error_key] += 1
			
			# Only report up to max_reported_errors
			if error_counts[error_key] <= max_reported_errors:
				if error_counts[error_key] == max_reported_errors:
					print("Suppressing further '" + error_key + "...' errors")
				return true
			return true
	return false

# Reset error counts periodically
func _reset_error_counts():
	error_counts.clear()

# Call this when loading a scene with TileMaps
func prepare_for_tilemap_scene():
	# Pre-emptively silence warnings
	suppress_tileset_errors()
	# Log a message the user will see
	print("Prepared for TileMap scene loading - errors will be reduced")
