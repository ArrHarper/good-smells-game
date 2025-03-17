extends Area2D
class_name Collectible

# Collectible properties
@export var collectible_name: String = "Generic Collectible"
@export_enum("common", "rare", "epic", "special") var collectible_type: String = "common"
@export var collectible_message: String = "You found something..."
@export var points: int = 0
@export var collected: bool = false
@export var detected: bool = false

# Visual representation variables
@export var particles_color: Color = Color("#CCCCCCE5") # Default color that can be overridden in editor
signal animation_completed(collectible_data) # Signal to notify when animation is done
signal collectible_detected(collectible_info) # Signal to notify player to emit particles

# Indicator for when the player is in range
var indicator_node = null
var is_in_range = false
var is_closest = false
var pulse_tween = null # Store reference to pulse tween

# Isometric position adjustments - helps with correct positioning on isometric grid
@export var isometric_height_offset: float = 0.0 # Positive values will raise the collectible's visual position

# Animation timing
var animation_duration = 1.6 # Total animation time in seconds
var message_delay = 0.8 # Time to wait before showing the message

func _ready():
	# Add to collectible group
	add_to_group("collectible")
	
	# Set up collision shape if it doesn't exist
	if not get_node_or_null("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		
		# Apply scale to the collision radius
		var radius = 16.0
		shape.radius = radius
		collision.shape = shape
		add_child(collision)
	
	# Connect signal
	connect("body_entered", _on_body_entered)
	
	# Create visual indicator (hidden by default)
	setup_indicator()
	
	# Debug
	if Engine.is_editor_hint():
		# Force visibility in editor for easier placement
		modulate.a = 0.7
		
	# Schedule animations for after positioning
	call_deferred("setup_animations")

# Update values based on the current scale factor
func update_scaled_values():
	# Update collision shape if it exists
	if has_node("CollisionShape2D"):
		var collision = $CollisionShape2D
		if collision.shape is CircleShape2D:
			collision.shape.radius = 16.0 * Iso.get_scale_factor()
			
	# Update indicator scale without applying scale factor again
	if indicator_node:
		if is_closest:
			indicator_node.scale = Vector2(0.5, 0.5)
		else:
			indicator_node.scale = Vector2(0.4, 0.4)

# Set up the visual indicator
func setup_indicator():
	if not has_node("CollectibleIndicator"):
		# Create a new sprite for the indicator
		indicator_node = Sprite2D.new()
		indicator_node.name = "CollectibleIndicator"
		
		# Use our custom collectible indicator texture
		var texture = load("res://assets/images/ui/smell_indicator.svg")
		if texture:
			indicator_node.texture = texture
			
			# Scale the indicator without applying scale factor
			var scale_base = 0.4
			indicator_node.scale = Vector2(scale_base, scale_base)
			
			# Set the color based on collectible type
			indicator_node.modulate = get_collectible_color().lightened(0.3)
			
			# Position at the center of the collectible object (not offset)
			indicator_node.position = Vector2(0, 0)
			
			# Set opacity to 0 initially
			indicator_node.modulate.a = 0
			
			# Set fixed z-index of 10 to ensure visibility
			indicator_node.z_index = 10
			
			# Since we're using absolute z-index, we don't want it to be relative
			indicator_node.z_as_relative = false
			
			add_child(indicator_node)
		else:
			print("WARNING: Could not load smell_indicator.svg for collectible: " + collectible_name)

func _on_body_entered(body):
	if body is CharacterBody2D and not collected:
		# This function no longer immediately collects the collectible.
		# The player now needs to use their smell ability to detect it.
		print("Player entered collectible area: " + collectible_name)

# Handle when player is in range of this collectible
func in_range(is_closest_collectible):
	is_in_range = true
	is_closest = is_closest_collectible
	
	# Show the indicator with appropriate styling
	if indicator_node:
		# Stop any existing animations
		if pulse_tween and pulse_tween.is_valid():
			pulse_tween.kill()
			pulse_tween = null
		
		# Create a new animation
		var fade_tween = create_tween()
		
		# If this is the closest collectible, make the indicator more prominent
		if is_closest_collectible:
			indicator_node.modulate = get_collectible_color()
			
			# Larger size for the closest collectible
			var scale_base = 0.5
			indicator_node.scale = Vector2(scale_base, scale_base)
			fade_tween.tween_property(indicator_node, "modulate:a", 0.9, 0.3)
			
			# Add a subtle pulse effect for the closest collectible
			pulse_tween = create_tween()
			pulse_tween.set_loops()
			
			# Scale the pulse effect without applying scale factor again
			var pulse_scale_max = 0.6
			var pulse_scale_min = 0.5
			
			pulse_tween.tween_property(indicator_node, "scale", Vector2(pulse_scale_max, pulse_scale_max), 0.5)
			pulse_tween.tween_property(indicator_node, "scale", Vector2(pulse_scale_min, pulse_scale_min), 0.5)
		else:
			# Less prominent for collectibles that aren't the closest
			indicator_node.modulate = get_collectible_color().lightened(0.3)
			
			# Apply size without game scale
			var scale_base = 0.3
			indicator_node.scale = Vector2(scale_base, scale_base)
			fade_tween.tween_property(indicator_node, "modulate:a", 0.6, 0.3)

# Called when the player moves out of range or collectible is no longer in detector
func out_of_range():
	is_in_range = false
	is_closest = false
	
	# Hide the indicator
	if indicator_node:
		# Stop any existing pulse animation
		if pulse_tween and pulse_tween.is_valid():
			pulse_tween.kill()
			pulse_tween = null
		
		# Create a new animation to fade out
		var tween = create_tween()
		tween.tween_property(indicator_node, "modulate:a", 0, 0.3)
		tween.tween_callback(func():
			# Reset scale when hidden
			var scale_base = 0.4
			indicator_node.scale = Vector2(scale_base, scale_base)
		)

# Process per frame
func _process(delta):
	# Have the indicator gently float to add some visual interest
	if indicator_node and is_in_range and indicator_node.modulate.a > 0:
		# Keep the indicator at the collectible's center but add a gentle floating effect
		var float_amount = 3.0
		indicator_node.position.y = sin(Time.get_ticks_msec() * 0.001 * 2) * float_amount

# Public methods for the collectible object
func get_collectible_text():
	return collectible_message

func get_collectible_type():
	return collectible_type

# Get the color for this collectible type
func get_collectible_color():
	# Use custom color if set
	if particles_color != Color("#CCCCCCE5"):
		return particles_color
	
	# Otherwise use type-based color
	if collectible_type == "common":
		return Color("#33CC33E5") # Bright green with high alpha
	elif collectible_type == "rare":
		return Color("#3333CCE5") # Bright blue with high alpha
	elif collectible_type == "epic":
		return Color("#CC33CCE5") # Bright purple with high alpha
	else:
		return Color("#CCCCCCE5") # Light gray with high alpha

# Function to detect and animate the collectible when player uses interact ability
func detect():
	if not detected and not collected:
		detected = true
		print("Collectible detected: " + collectible_name)
		
		# Stop any pulse animation
		if pulse_tween and pulse_tween.is_valid():
			pulse_tween.kill()
			pulse_tween = null
		
		# Hide the indicator when detected
		if indicator_node:
			var tween = create_tween()
			tween.tween_property(indicator_node, "modulate:a", 0, 0.3)
		
		# Determine the message based on collectible type
		var display_message = collectible_message
		
		# Pass all collectible information to the player
		var collectible_info = {
			"name": collectible_name,
			"type": collectible_type,
			"message": "Found it!", # Override with a standard message
			"color": get_collectible_color()
		}
		
		# Emit signal for the player to handle particles
		emit_signal("collectible_detected", collectible_info)
		
		# Create a timer to delay the message
		var timer = Timer.new()
		timer.wait_time = message_delay
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func():
			# Emit the collectible signal after delay
			emit_signal("animation_completed", {"message": "Found it!", "type": collectible_type})
			timer.queue_free()
		)
		timer.start()
		
		# After animation completes, mark as collected
		var tween = create_tween()
		tween.tween_interval(animation_duration)
		tween.tween_callback(func():
			mark_collected()
		)

# Called when the collectible animation is complete
func mark_collected():
	if not collected:
		collected = true
		print("Collectible collected: " + collectible_name)
		
		# Ensure indicator is hidden
		if indicator_node:
			indicator_node.visible = false
		
		# Here we can add any additional logic needed when a collectible is collected
		# For example, update a score counter, play a sound, etc.

# Reset the collectible object's state
func reset():
	# Reset collection and detection flags
	collected = false
	detected = false
	
	print("Collectible reset: " + collectible_name)
	
	# If the indicator exists, ensure it can show again when player gets in range
	if indicator_node:
		indicator_node.modulate.a = 0
		indicator_node.visible = true
		
# Sets up animations for the collectible object
func setup_animations():
	# Start the idle animation if not already playing
	start_idle_animation()

# Start a subtle idle animation for the collectible
func start_idle_animation():
	# Set initial scale
	var scale_base = Vector2(1, 1)
	if Iso.get_scale_factor():
		scale_base *= Iso.get_scale_factor()
	scale = scale_base
	
	# Start the breathing animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05) * scale_base, 1.0)
	tween.tween_property(self, "scale", scale_base, 1.0)