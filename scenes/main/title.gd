extends Label

# Store original transform properties
var original_position: Vector2
var original_rotation: float
var original_scale: Vector2
var time_offset: float = 0.0

# Character nodes for wave effect
var label_chars = []
var char_original_positions = []

# Animation settings - adjust these to tweak effects
var bob_amplitude: float = 5.0
var bob_frequency: float = 1.0
var breath_amount: float = 0.05
var breath_frequency: float = 1.5
var wave_amplitude: float = 5.0
var wave_frequency: float = 2.0
var rotation_amplitude: float = 2.0
var rotation_frequency: float = 1.0
var color_pulse_frequency: float = 2.0
var parallax_factor: float = 0.05

# Reference to player for parallax effect
var player_node = null
var map_center_pos: Vector2

# Which effect is active - change the number to test different effects
# 1: Bobbing, 2: Breathing, 3: Wave effect, 4: Rotation sway
# 5: Color pulsing, 6: Parallax, 7: Combined effects
var active_effect: int = 4

func _ready():
	# Store original transform
	original_position = position
	original_rotation = rotation_degrees
	original_scale = scale
	
	# Add some randomness to time offset
	time_offset = randf() * 10.0
	
	# Try to find player node for parallax effect
	player_node = get_tree().get_nodes_in_group("player")
	if player_node.size() > 0:
		player_node = player_node[0]
	else:
		# If no player group, try finding by class
		var player_nodes = get_tree().get_nodes_in_group("CharacterBody2D")
		for node in player_nodes:
			if node.name.to_lower().contains("player"):
				player_node = node
				break
	
	# Store map center position for parallax
	var parent = get_parent()
	if parent:
		map_center_pos = parent.position
	
	# Setup for wave effect if needed
	if active_effect == 3:
		setup_wave_effect()

func _process(delta):
	# Get time for animations
	var time = Time.get_ticks_msec() * 0.001 + time_offset
	
	# Reset transform before applying effect
	position = original_position
	rotation_degrees = original_rotation
	scale = original_scale
	modulate = Color(1, 1, 1, 1)
	
	# Apply the active effect
	match active_effect:
		1: bobbing_effect(time)
		2: breathing_effect(time)
		3: wave_effect(time)
		4: rotation_sway_effect(time)
		5: color_pulse_effect(time)
		6: parallax_effect()
		7: combined_effects(time)

# EFFECT 1: Gentle bobbing animation
func bobbing_effect(time: float):
	position.y = original_position.y + sin(time * bob_frequency) * bob_amplitude

# EFFECT 2: Breathing effect (scaling)
func breathing_effect(time: float):
	var scale_factor = 1.0 + sin(time * breath_frequency) * breath_amount
	scale = original_scale * scale_factor

# EFFECT 3: Wave effect setup - creates individual labels for each character
func setup_wave_effect():
	# Clear any previous setup
	for child in label_chars:
		if is_instance_valid(child):
			child.queue_free()
	
	label_chars.clear()
	char_original_positions.clear()
	
	# Hide original label
	visible = false
	
	# Create parent node for characters
	var char_parent = Node2D.new()
	char_parent.name = "CharacterContainer"
	get_parent().add_child(char_parent)
	
	# Calculate total width for centering
	var total_width = 0
	var font_size = get_theme_font_size("font_size")
	var font = get_theme_font("font")
	
	for i in range(text.length()):
		total_width += font.get_char_size(text.unicode_at(i), font_size).x
	
	# Create labels for each character
	var current_x = -total_width / 2
	for i in range(text.length()):
		var char_label = Label.new()
		char_label.text = text.substr(i, 1)
		char_label.add_theme_font_override("font", font)
		char_label.add_theme_font_size_override("font_size", font_size)
		char_label.add_theme_color_override("font_color", get_theme_color("font_color"))
		
		var char_width = font.get_char_size(text.unicode_at(i), font_size).x
		
		char_label.position.x = current_x + char_width / 2
		current_x += char_width
		
		char_parent.add_child(char_label)
		label_chars.append(char_label)
		char_original_positions.append(char_label.position)

# EFFECT 3: Wave effect animation
func wave_effect(time: float):
	if label_chars.size() == 0:
		# Skip if not set up
		return
		
	for i in range(label_chars.size()):
		if label_chars[i]:
			var label = label_chars[i]
			label.position.y = char_original_positions[i].y + sin(time * wave_frequency + i * 0.5) * wave_amplitude

# EFFECT 4: Rotation sway
func rotation_sway_effect(time: float):
	rotation_degrees = original_rotation + sin(time * rotation_frequency) * rotation_amplitude

# EFFECT 5: Color pulsing
func color_pulse_effect(time: float):
	var pulse = (sin(time * color_pulse_frequency) + 1) * 0.5  # 0 to 1 value
	
	# Option 1: Opacity pulsing
	modulate = Color(1, 1, 1, 0.7 + pulse * 0.3)
	
	# Option 2: Color pulsing (commented out by default)
	# modulate = Color(1.0, 0.7 + pulse * 0.3, 0.7 + pulse * 0.3, 1.0)  # Pulse between white and light red

# EFFECT 6: Parallax effect
func parallax_effect():
	if player_node:
		position.x = original_position.x - (player_node.position.x - map_center_pos.x) * parallax_factor
		position.y = original_position.y - (player_node.position.y - map_center_pos.y) * parallax_factor

# EFFECT 7: Combined effects
func combined_effects(time: float):
	# Bobbing
	position.y = original_position.y + sin(time) * (bob_amplitude * 0.8)
	
	# Slight rotation
	rotation_degrees = original_rotation + sin(time * 0.7) * (rotation_amplitude * 0.75)
	
	# Subtle color pulse
	var pulse = (sin(time * 1.2) + 1) * 0.5
	modulate = Color(1, 1, 1 - pulse * 0.2, 1)  # Pulse between white and slight blue

# BONUS EFFECT: Letter-by-letter appearance animation
# Call this function to trigger the animation
func animate_letter_by_letter():
	visible_characters = 0
	var tween = create_tween()
	tween.tween_property(self, "visible_characters", text.length(), 1.5)
	tween.tween_callback(func(): active_effect = 1)  # Start bobbing after text appears 