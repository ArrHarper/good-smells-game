extends CanvasLayer

# Animation properties
var message_animation_time = 0.0
var message_float_speed = 2.0
var message_float_height = 5.0

# Debug properties
var debug_update_timer = 0.0
var debug_update_interval = 0.1  # Update debug text 10 times per second

func _ready():
	# Hide smell message initially
	$SmellLabel.visible = false
	
	# Initialize debug text if it exists
	update_debug_text(Vector2.ZERO, Vector2i.ZERO, 0)
	
	# Enable process for animations
	set_process(true)

func _process(delta):
	# Animate the smell message if visible
	if $SmellLabel.visible:
		message_animation_time += delta
		
		# Create a gentle floating animation
		var y_offset = -sin(message_animation_time * message_float_speed) * message_float_height
		$SmellLabel.position.y = -250 + y_offset  # Base position is -250
	
	# Update debug information
	debug_update_timer += delta
	if debug_update_timer >= debug_update_interval:
		debug_update_timer = 0
		
		# Try to get player information
		var player = get_node_or_null("/root/Main/nose")
		if player:
			var player_pos = player.global_position
			var tile_pos = IsometricUtils.world_to_tile(player_pos, 32, 16)  # Using constants from player
			var z_index = player.z_index
			update_debug_text(player_pos, tile_pos, z_index)

# Update the debug text with player information
func update_debug_text(player_pos, tile_pos, z_index):
	# Find the debug text node - try both paths to handle renaming
	var debug_text = get_node_or_null("TextureButton/RichTextLabel")
	if not debug_text:
		debug_text = get_node_or_null("DebugButton/DebugText")
	
	if debug_text:
		var text = "Debug Info\n"
		text += "Position: (" + str(int(player_pos.x)) + ", " + str(int(player_pos.y)) + ")\n"
		text += "Tile: (" + str(tile_pos.x) + ", " + str(tile_pos.y) + ")\n"
		text += "Z-Index: " + str(z_index)
		
		# Count smells if possible
		var main = get_node_or_null("/root/Main")
		if main and main.has_method("count_smell_objects"):
			var counts = main.count_smell_objects()
			text += "\n\nSmells:"
			text += "\nFound: " + str(counts.detected) + "/" + str(counts.total)
			text += "\nCollected: " + str(counts.collected) + "/" + str(counts.total)
			text += "\n\nBy Type:"
			text += "\n - Good: " + str(counts.good)
			text += "\n - Bad: " + str(counts.bad)
			text += "\n - Epic: " + str(counts.epic)
			if counts.neutral > 0:
				text += "\n - Neutral: " + str(counts.neutral)
		
		debug_text.text = text

func show_smell_message(text, type):
	# Debug logging
	print("UI received smell message: '" + text + "' of type '" + type + "'")
	
	# Reset animation
	message_animation_time = 0.0

	# Set the message text
	$SmellLabel.text = text
	$SmellLabel.visible = true
	print("SmellLabel is now visible with text: '" + text + "'")
	
	# Make the text appear with a slight scaling effect
	var tween = create_tween()
	$SmellLabel.scale = Vector2(0.8, 0.8)
	tween.tween_property($SmellLabel, "scale", Vector2(1.0, 1.0), 0.3)
	print("Started SmellLabel animation tween")
	
	# Change color based on type
	match type:
		"good":
			$SmellLabel.add_theme_color_override("font_color", Color(0, 1, 0))
			print("Set SmellLabel color to green (good)")
		"bad":
			$SmellLabel.add_theme_color_override("font_color", Color(1, 0, 0))
			print("Set SmellLabel color to red (bad)")
		"epic":
			$SmellLabel.add_theme_color_override("font_color", Color(0.8, 0.4, 0))
			print("Set SmellLabel color to orange (epic)")
		_:
			$SmellLabel.add_theme_color_override("font_color", Color(1, 1, 1))
			print("Set SmellLabel color to white (neutral)")
	
	# Hide message after a delay
	$MessageTimer.start()
	print("Started MessageTimer for " + str($MessageTimer.wait_time) + " seconds")

func _on_message_timer_timeout():
	# Fade out the message
	var tween = create_tween()
	tween.tween_property($SmellLabel, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		$SmellLabel.visible = false
		$SmellLabel.modulate = Color(1, 1, 1, 1)  # Reset for next time
	)
