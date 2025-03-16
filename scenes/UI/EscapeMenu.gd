extends Control

# Import the Smell class for type checking
const Smell = preload("res://scenes/smells/smell.gd")

# Customizable colors for the pause menu
# @export var background_overlay_color: Color = Color("50e112")
@export var panel_background_color: Color = Color("430067")
@export var panel_border_color: Color = Color("fff1e8")
@export var panel_shadow_color: Color = Color(0, 0, 0, 0.3)

# Button colors
@export var button_normal_color: Color = Color("#94216a")
@export var button_hover_color: Color = Color(0.35, 0.35, 0.35, 1.0)
@export var button_pressed_color: Color = Color(0.15, 0.15, 0.15, 1.0)
@export var button_text_color: Color = Color("50e112")

# Title label color
@export var title_color: Color = Color("50e112")

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
	
	# Apply the custom colors
	apply_menu_colors()

# Apply custom colors to the pause menu
func apply_menu_colors():
	# # Set background overlay color
	# if has_node("ColorRect"):
	# 	$ColorRect.color = background_overlay_color
	# Set panel colors
	if has_node("Panel"):
		var panel_style = $Panel.get_theme_stylebox("panel").duplicate()
		if panel_style is StyleBoxFlat:
			panel_style.bg_color = panel_background_color
			panel_style.border_color = panel_border_color
			panel_style.shadow_color = panel_shadow_color
			$Panel.add_theme_stylebox_override("panel", panel_style)
	
	# Set button colors
	apply_button_colors()
	
	# Set title color
	apply_title_color()

# Apply custom colors to buttons
func apply_button_colors():
	var buttons = [
		$Panel/VBoxContainer/ResumeButton,
		$Panel/VBoxContainer/RestartButton,
		$Panel/VBoxContainer/QuitButton
	]
	
	for button in buttons:
		if button:
			# Normal state
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = button_normal_color
			normal_style.corner_radius_top_left = 5
			normal_style.corner_radius_top_right = 5
			normal_style.corner_radius_bottom_left = 5
			normal_style.corner_radius_bottom_right = 5
			button.add_theme_stylebox_override("normal", normal_style)
			
			# Hover state
			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = button_hover_color
			hover_style.corner_radius_top_left = 5
			hover_style.corner_radius_top_right = 5
			hover_style.corner_radius_bottom_left = 5
			hover_style.corner_radius_bottom_right = 5
			button.add_theme_stylebox_override("hover", hover_style)
			
			# Pressed state
			var pressed_style = StyleBoxFlat.new()
			pressed_style.bg_color = button_pressed_color
			pressed_style.corner_radius_top_left = 5
			pressed_style.corner_radius_top_right = 5
			pressed_style.corner_radius_bottom_left = 5
			pressed_style.corner_radius_bottom_right = 5
			button.add_theme_stylebox_override("pressed", pressed_style)
			
			# Text color
			button.add_theme_color_override("font_color", button_text_color)
			button.add_theme_color_override("font_hover_color", button_text_color)
			button.add_theme_color_override("font_pressed_color", button_text_color)

# Public method to change menu colors dynamically
func set_menu_colors(new_bg_color: Color, new_panel_color: Color, new_border_color: Color, new_shadow_color: Color = Color(0, 0, 0, 0.3)):
	# Update the color properties
	# background_overlay_color = new_bg_color
	panel_background_color = new_panel_color
	panel_border_color = new_border_color
	panel_shadow_color = new_shadow_color
	
	# Apply the updated colors
	apply_menu_colors()

# Public method to change button colors dynamically
func set_button_colors(normal: Color, hover: Color, pressed: Color, text: Color):
	button_normal_color = normal
	button_hover_color = hover
	button_pressed_color = pressed
	button_text_color = text
	
	# Apply the button colors
	apply_button_colors()

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

# Apply custom color to the title label
func apply_title_color():
	if has_node("Panel/VBoxContainer/TitleLabel"):
		$Panel/VBoxContainer/TitleLabel.add_theme_color_override("font_color", title_color)

# Public method to set the title label color
func set_title_color(color: Color):
	title_color = color
	apply_title_color()

# Example method to set a theme with complementary colors
func set_theme_colors(primary_color: Color):
	# Create complementary colors based on the primary color
	var secondary_color = primary_color.darkened(0.3)
	var accent_color = primary_color.lightened(0.3)
	var text_color = Color(1, 1, 1) if primary_color.v < 0.6 else Color(0.1, 0.1, 0.1)
	
	# Set background with alpha
	var bg_color = Color(primary_color.r, primary_color.g, primary_color.b, 0.4)
	
	# Set panel with slight transparency
	var panel_color = Color(secondary_color.r, secondary_color.g, secondary_color.b, 0.9)
	
	# Set all colors at once
	# background_overlay_color = bg_color
	panel_background_color = panel_color
	panel_border_color = accent_color
	panel_shadow_color = Color(0, 0, 0, 0.3)
	
	# Set button colors
	button_normal_color = secondary_color
	button_hover_color = accent_color
	button_pressed_color = secondary_color.darkened(0.2)
	button_text_color = text_color
	
	# Set title color
	title_color = accent_color
	
	# Apply all changes
	apply_menu_colors()
