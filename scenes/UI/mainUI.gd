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
	
	# Set up the debug toggle button
	var debug_button = get_node_or_null("TextureButton")
	var debug_text = get_node_or_null("RichTextLabel")
	
	if debug_button and debug_text:
		# Set the debug text to be hidden by default
		debug_text.visible = false
		debug_button.pressed.connect(_on_debug_button_pressed)
	
	# Enable process for updates
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
			var tile_pos = IsometricUtils.world_to_tile(player_pos, 32, 16)
			var z_index = player.z_index
			update_debug_text(player_pos, tile_pos, z_index)

# Update the debug text with player information
func update_debug_text(player_pos, tile_pos, z_index):
	# Find the debug text node
	var debug_text = get_node_or_null("RichTextLabel")
	
	if debug_text:
		var raw_text = "Debug Info\n"
		raw_text += "Position: (" + str(int(player_pos.x)) + ", " + str(int(player_pos.y)) + ")\n"
		raw_text += "Tile: (" + str(tile_pos.x) + ", " + str(tile_pos.y) + ")\n"
		raw_text += "Z-Index: " + str(z_index)
		
		# Count smells if possible
		var main = get_node_or_null("/root/Main")
		if main and main.has_method("count_smell_objects"):
			var counts = main.count_smell_objects()
			raw_text += "\n\nSmells:"
			raw_text += "\nFound: " + str(counts.detected) + "/" + str(counts.total)
			raw_text += "\nCollected: " + str(counts.collected) + "/" + str(counts.total)
			raw_text += "\n\nBy Type:"
			raw_text += "\n - Good: " + str(counts.good)
			raw_text += "\n - Bad: " + str(counts.bad)
			raw_text += "\n - Epic: " + str(counts.epic)
			if counts.neutral > 0:
				raw_text += "\n - Neutral: " + str(counts.neutral)
		
		# Split text into columns
		var column_width = 180 # Adjust this value based on your layout preferences
		var num_columns = 4 # Number of columns to display
		var lines = raw_text.split("\n")
		var lines_per_column = int(ceil(float(lines.size()) / num_columns))
		
		# Generate BBCode for multi-column layout
		var formatted_text = "[table=noborder]\n[cell]"
		
		for i in range(lines.size()):
			formatted_text += lines[i]
			
			# End of a column or last line
			if (i + 1) % lines_per_column == 0 and i < lines.size() - 1:
				formatted_text += "[/cell][cell]"
			elif i < lines.size() - 1:
				formatted_text += "\n"
				
		formatted_text += "[/cell]\n[/table]"
		
		# Set the BBCode text
		debug_text.bbcode_enabled = true
		debug_text.text = formatted_text

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
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 24)
	
	# Set the label to fill the entire parent and center the text
	message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	message_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Set text and color based on smell type
	message_label.text = text
	
	# Create a new StyleBoxFlat for the indicator
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.2) # Default
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_detail = 10
	
	match type:
		"good":
			message_label.add_theme_color_override("font_color", Color(0, 1, 0))
			style.bg_color = Color(0.2, 0.7, 0.2, 0.3)
		"bad":
			message_label.add_theme_color_override("font_color", Color(1, 0, 0))
			style.bg_color = Color(0.7, 0.2, 0.2, 0.3)
		"epic":
			message_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0))
			style.bg_color = Color(0.7, 0.4, 0.0, 0.3)
		_:
			message_label.add_theme_color_override("font_color", Color(1, 1, 1))
			style.bg_color = Color(0.2, 0.2, 0.2, 0.3)
	
	# Apply the style to the indicator
	indicator.add_theme_stylebox_override("panel", style)
	
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
			# Reset indicator style
			var default_style = StyleBoxFlat.new()
			default_style.bg_color = Color(0.2, 0.2, 0.2, 0.2)
			default_style.corner_radius_top_left = 16
			default_style.corner_radius_top_right = 16
			default_style.corner_radius_bottom_right = 16
			default_style.corner_radius_bottom_left = 16
			default_style.corner_detail = 16
			indicator.add_theme_stylebox_override("panel", default_style)
			
			# Show the indicator label again
			if indicator_label:
				indicator_label.visible = true
		)
		timer.queue_free()
	)
	timer.start()

# Test function to verify smell messages work
func test_smell_message():
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	add_child(timer)
	
	timer.timeout.connect(func():
		show_smell_message("TEST MESSAGE: This is a test smell!", "good")
		timer.queue_free()
	)
	
	timer.start()

# Toggle visibility of the debug text panel
func _on_debug_button_pressed():
	var debug_text = get_node_or_null("RichTextLabel")
	if debug_text:
		debug_text.visible = !debug_text.visible
