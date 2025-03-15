extends CanvasLayer

# Debug properties
var debug_update_timer = 0.0
var debug_update_interval = 0.1 # Update debug text 10 times per second

func _ready():
	# Make sure the window indicator is visible
	if has_node("SmellWindowIndicator"):
		$SmellWindowIndicator.visible = true
	
	# Initialize debug text if it exists
	update_debug_text(Vector2.ZERO, Vector2i.ZERO, 0)
	
	# Enable process for animations
	set_process(true)

func _process(delta):
	# Update debug information
	debug_update_timer += delta
	if debug_update_timer >= debug_update_interval:
		debug_update_timer = 0
		
		# Try to get player information
		var player = get_node_or_null("/root/Main/nose")
		if player:
			var player_pos = player.global_position
			var tile_pos = IsometricUtils.world_to_tile(player_pos, 32, 16) # Using correct tile dimensions
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
	# Remove any existing DebugLabel if it exists
	var existing_debug = get_node_or_null("DebugLabel")
	if existing_debug:
		existing_debug.queue_free()
	
	# Get the SmellWindowIndicator
	var indicator = get_node_or_null("SmellWindowIndicator")
	if not indicator:
		print("ERROR: SmellWindowIndicator not found")
		return
	
	# Create a new label for the smell message
	var message_label = Label.new()
	message_label.name = "SmellMessageLabel"
	message_label.size = Vector2(400, 135) # Match SmellWindowIndicator size
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 24)
	
	# Set text and color based on smell type
	message_label.text = text
	match type:
		"good":
			message_label.add_theme_color_override("font_color", Color(0, 1, 0))
			indicator.color = Color(0.2, 0.7, 0.2, 0.3)
		"bad":
			message_label.add_theme_color_override("font_color", Color(1, 0, 0))
			indicator.color = Color(0.7, 0.2, 0.2, 0.3)
		"epic":
			message_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0))
			indicator.color = Color(0.7, 0.4, 0.0, 0.3)
		_:
			message_label.add_theme_color_override("font_color", Color(1, 1, 1))
			indicator.color = Color(0.2, 0.2, 0.2, 0.3)
	
	# Add shadow and outline effects for better visibility
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	message_label.add_theme_constant_override("outline_size", 3)
	message_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	
	# Add the label to the SmellWindowIndicator
	indicator.add_child(message_label)
	
	# Hide the default indicator label if it exists
	var indicator_label = indicator.get_node_or_null("IndicatorLabel")
	if indicator_label:
		indicator_label.visible = false
	
	# Create a timer to hide the message
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func():
		# Fade out the message
		var tween = create_tween()
		tween.tween_property(message_label, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(func():
			message_label.queue_free()
			# Reset indicator color
			indicator.color = Color(0.2, 0.2, 0.2, 0.2)
			# Show the indicator label again
			if indicator_label:
				indicator_label.visible = true
		)
		timer.queue_free()
	)
	timer.start()
	
	print("Displayed smell message in SmellWindowIndicator: " + text)

# Test function to verify smell messages work
func test_smell_message():
	# Create a timer to wait 1 second before showing test message
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	add_child(timer)
	
	# Connect timeout to show a test message
	timer.timeout.connect(func():
		print("TEST: Showing test smell message")
		show_smell_message("TEST MESSAGE: This is a test smell!", "good")
		timer.queue_free()
	)
	
	# Start the timer
	timer.start()
