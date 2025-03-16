extends Control

# Import the Smell class for type checking
const Smell = preload("res://scenes/smells/smell.gd")

# Called when the node enters the scene tree for the first time
func _ready():
	# Hide the menu initially
	visible = false
	
	# Connect the resume button to the close_menu function
	$Panel/VBoxContainer/ResumeButton.pressed.connect(close_menu)
	
	# Connect the restart button to the restart_game function
	$Panel/VBoxContainer/RestartButton.pressed.connect(restart_game)
	
	# Connect the quit button to the quit_game function
	$Panel/VBoxContainer/QuitButton.pressed.connect(quit_game)

# Process input when the menu is visible
func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

# Show the escape menu and pause the game
func open_menu():
	visible = true
	get_tree().paused = true

# Hide the escape menu and resume the game
func close_menu():
	visible = false
	get_tree().paused = false
	
# Restart the game by reloading the current scene
func restart_game():
	# Unpause before resetting
	get_tree().paused = false
	
	# Get the current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		# Find all smell objects in the scene
		var smell_nodes = get_tree().get_nodes_in_group("smell")
		
		if smell_nodes.size() > 0:
			# Reset all smell objects
			for smell in smell_nodes:
				if smell is Smell:
					# Reset detection and collection flags
					smell.detected = false
					smell.collected = false
					
					# Show indicator if it exists and smell has in_range method
					if smell.has_method("out_of_range"):
						smell.out_of_range()
						
					# If the smell object has a specific reset method, call it too
					if smell.has_method("reset"):
						smell.reset()
			
			# Optionally show a message to inform the player
			# Find the appropriate UI layer to add the notification to
			var ui_layer = null
			if current_scene.has_node("UI"):
				ui_layer = current_scene.get_node("UI")
			elif current_scene.has_node("CanvasLayer"):
				ui_layer = current_scene.get_node("CanvasLayer")

			if ui_layer:
				# Create a temporary label to show a message
				var temp_label = Label.new()
				temp_label.text = "Smells have been reset! Start searching again."
				
				# Set up proper centering
				temp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				temp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				temp_label.anchors_preset = Control.PRESET_CENTER
				
				# Sizing and margins
				temp_label.custom_minimum_size = Vector2(400, 80)
				temp_label.position = Vector2(-200, -40) # Half the size to center it
				
				# Styling
				temp_label.add_theme_color_override("font_color", Color(1, 1, 0)) # Yellow text
				temp_label.add_theme_font_size_override("font_size", 24)
				
				# Add shadow
				temp_label.add_theme_constant_override("shadow_offset_x", 2)
				temp_label.add_theme_constant_override("shadow_offset_y", 2)
				temp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
				
				# Add to the UI layer
				ui_layer.add_child(temp_label)
				
				# Remove after a few seconds
				var timer = Timer.new()
				timer.wait_time = 3.0
				timer.one_shot = true
				ui_layer.add_child(timer)
				timer.timeout.connect(func():
					temp_label.queue_free()
					timer.queue_free()
				)
				timer.start()

# Quit the game
func quit_game():
	get_tree().quit()
