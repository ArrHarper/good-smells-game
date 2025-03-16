extends CharacterBody2D
class_name Player

# Movement constants
const MOVE_SPEED = 300
# Isometric tile dimensions - these will use the scaled values at runtime
const TILE_WIDTH = 32
const TILE_HEIGHT = 16

# Player movement properties
var base_speed = 150
var current_speed = base_speed
var is_moving = false

# Reference to the game scale singleton for scaling values
var game_scale

# Smell detection
var is_smelling = false
var smell_duration = 2.0 # Duration of the smell action in seconds
var pending_smells = [] # List of smell objects to process
signal smell_detected(smell_text, smell_type) # Signal when a smell is detected

# Collectible detection (will reuse the smelling action)
var pending_collectibles = [] # List of collectible objects to process

# Particle system properties
var smell_particles = null
var default_particle_color = Color(0.9, 0.9, 1.0, 0.8)
var current_particle_color = default_particle_color
var smell_message_label = null # Label to display smell message above player's head

# Animation properties
var floating_time = 0
var wiggle_time = 0
var float_speed = 1.5
var float_height = 3
var wiggle_speed = 12
var wiggle_width = 4
var idle_time = 0
var move_time = 0
var original_y = 0
var base_position_y = 0 # Store the base Y position without animation offset
var facing_right = true
var smell_timer = 0
var float_animation_active = true # Control whether player sprite floats
var wiggle_intensity = 2.5 # How intense the wiggle is

# Debug
@export var debug_mode = false # Set to true to show detailed logs
var last_reported_tile_pos = Vector2i(-999, -999)
var position_report_timer = 0
var position_report_interval = 0.5 # Report position at most every half second

# Called when the node enters the scene tree for the first time
func _ready():
	# Get reference to the game scale singleton if available
	if Engine.has_singleton("GameScale"):
		game_scale = Engine.get_singleton("GameScale")
		
		# Connect to scale changed signal if available
		if game_scale.has_signal("scale_changed"):
			game_scale.connect("scale_changed", _on_scale_changed)
			
	original_y = position.y
	base_position_y = position.y # Initialize base position
	
	# Set up smell action timer
	setup_smell_timer()
	
	# Set up smell detector
	setup_smell_detector()
	
	# Create smell particles
	setup_smell_particles()
	
	# Start playing the default animation
	if has_node("IsoNoseSprite"):
		$IsoNoseSprite.play("noseFacingSouthEast")
	
	# Print initial position for debugging
	if debug_mode:
		print("Initial position: ", position)
		var initial_tile = IsometricUtils.world_to_tile(position)
		print("Initial tile: ", initial_tile)
	
	# Set up a timer to check for smells in range periodically
	var range_check_timer = Timer.new()
	range_check_timer.name = "RangeCheckTimer"
	range_check_timer.wait_time = 0.2 # Check 5 times per second
	range_check_timer.one_shot = false
	range_check_timer.connect("timeout", _on_range_check_timer_timeout)
	add_child(range_check_timer)
	range_check_timer.start()

# Handler for scale changes
func _on_scale_changed(new_scale):
	# Update any values that need to be adjusted when scale changes
	if debug_mode:
		print("Scale changed to: ", new_scale)
		
	# Recalculate any scaled values
	update_scaled_values()

# Update scaled values based on current scale
func update_scaled_values():
	if not game_scale:
		return
		
	# Get scaled size for smell detector
	if has_node("SmellDetector"):
		var smell_detector = $SmellDetector
		if smell_detector.get_child_count() > 0:
			var collision_shape = smell_detector.get_child(0)
			if collision_shape is CollisionShape2D and collision_shape.shape is CircleShape2D:
				# Base radius is 32, multiply by scale
				collision_shape.shape.radius = 32 * game_scale.SCALE_FACTOR
	
	# Update any other scale-dependent values
	float_height = 3 * game_scale.SCALE_FACTOR
	wiggle_width = 4 * game_scale.SCALE_FACTOR
	wiggle_intensity = 2.5 * game_scale.SCALE_FACTOR

# Tracks which smells were in range last time we checked
var previous_smells_in_range = []

# Periodically check for smells in range to update their indicators
func _on_range_check_timer_timeout():
	if is_smelling:
		return # Don't update during smell action
		
	var smell_detector = get_node_or_null("SmellDetector")
	if smell_detector:
		var overlapping_areas = smell_detector.get_overlapping_areas()
		var current_smells_in_range = []
		var current_collectibles_in_range = []
		
		# Find all smells and collectibles currently in range
		for area in overlapping_areas:
			# Check for smells
			if area is Smell or (area.get_parent() is Smell):
				var smell = area if area is Smell else area.get_parent()
				current_smells_in_range.append(smell)
			# Check for collectibles
			elif area is Collectible or (area.get_parent() is Collectible):
				var collectible = area if area is Collectible else area.get_parent()
				current_collectibles_in_range.append(collectible)
		
		# Sort smells by distance
		if current_smells_in_range.size() > 1:
			current_smells_in_range.sort_custom(func(a, b):
				var dist_a = global_position.distance_to(a.global_position)
				var dist_b = global_position.distance_to(b.global_position)
				return dist_a < dist_b
			)
		
		# Sort collectibles by distance
		if current_collectibles_in_range.size() > 1:
			current_collectibles_in_range.sort_custom(func(a, b):
				var dist_a = global_position.distance_to(a.global_position)
				var dist_b = global_position.distance_to(b.global_position)
				return dist_a < dist_b
			)
		
		# Update each smell's status
		for i in range(current_smells_in_range.size()):
			var smell = current_smells_in_range[i]
			if smell.has_method("in_range") and not smell.collected:
				smell.in_range(i == 0) # Pass true if it's the closest smell
		
		# Update each collectible's status
		for i in range(current_collectibles_in_range.size()):
			var collectible = current_collectibles_in_range[i]
			if collectible.has_method("in_range") and not collectible.collected:
				collectible.in_range(i == 0) # Pass true if it's the closest collectible
		
		# Call out_of_range for smells that are no longer in range
		for smell in previous_smells_in_range:
			if is_instance_valid(smell) and not current_smells_in_range.has(smell):
				if smell.has_method("out_of_range") and not smell.collected:
					smell.out_of_range()
		
		# Update the tracking list
		previous_smells_in_range = current_smells_in_range

# Setup the smell timer
func setup_smell_timer():
	var timer = Timer.new()
	timer.name = "SmellTimer"
	timer.wait_time = smell_duration
	timer.one_shot = true
	timer.connect("timeout", _on_smell_timer_timeout)
	add_child(timer)

# Setup the smell detector area
func setup_smell_detector():
	if not has_node("SmellDetector"):
		var smell_detector = Area2D.new()
		smell_detector.name = "SmellDetector"
		
		# Create a circle shape with scaled radius for smell detection
		var collision_shape = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		
		# Base radius is 32, apply scale if available
		var radius = 32.0
		if game_scale:
			radius *= game_scale.SCALE_FACTOR
			
		shape.radius = radius
		collision_shape.shape = shape
		smell_detector.add_child(collision_shape)
		
		add_child(smell_detector)

# Setup smell particles
func setup_smell_particles():
	if not has_node("SmellParticles"):
		var particles = GPUParticles2D.new()
		particles.name = "SmellParticles"
		
		# Configure particles
		var material = ParticleProcessMaterial.new()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 15.0
		material.direction = Vector3(0, -1, 0)
		material.spread = 60.0
		material.gravity = Vector3(0, -30, 0)
		material.initial_velocity_min = 20.0
		material.initial_velocity_max = 40.0
		material.color = default_particle_color
		
		# Add enhanced properties for better visual effect
		material.scale_min = 1.5
		material.scale_max = 3.0
		material.turbulence_enabled = true
		material.turbulence_noise_strength = 1.2
		material.turbulence_noise_scale = 1.5
		
		particles.process_material = material
		particles.amount = 28
		particles.lifetime = 3.0
		particles.explosiveness = 0.2
		particles.z_index = 1000
		particles.z_as_relative = false
		particles.emitting = false
		
		# Position the particles slightly above the character's head
		# Scale this offset if game scale is available
		var y_offset = -20.0
		if game_scale:
			y_offset *= game_scale.SCALE_FACTOR
			
		particles.position = Vector2(0, y_offset)
		
		add_child(particles)
		smell_particles = particles
	else:
		smell_particles = $SmellParticles

# Called every frame
func _process(delta):
	# Get input vector
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Only allow movement if not currently smelling
	if not is_smelling:
		# Convert input to isometric movement direction using the utility class
		var isometric_direction = IsometricUtils.get_isometric_direction(input_vector)
		
		# Apply movement
		velocity = isometric_direction * MOVE_SPEED if input_vector != Vector2.ZERO else Vector2.ZERO
		move_and_slide()
		
		# Update base Y position when we move vertically
		if abs(input_vector.y) > 0:
			base_position_y = global_position.y
	else:
		# No movement during smelling action
		velocity = Vector2.ZERO
	
	# Handle animations
	handle_animations(delta, input_vector)
	
	# Update z-index manually for better control
	update_z_index()
	
	# Log player position when moving
	if debug_mode and velocity.length() > 0:
		position_report_timer += delta
		if position_report_timer >= position_report_interval:
			position_report_timer = 0
			var current_tile_pos = IsometricUtils.world_to_tile(global_position)
			
			# Only report if position changed
			if current_tile_pos != last_reported_tile_pos:
				# Disabled position logging - now handled by UI debug display
				# print("Player tile position: ", current_tile_pos, " | World position: ", global_position)
				last_reported_tile_pos = current_tile_pos
		
	# Smell ability - Space key for now, can be updated in project settings
	if Input.is_action_just_pressed("smell") and not is_smelling:
		# Disabled regular log
		# print("Space pressed - Starting smell action")
		start_smelling()
		
	# Handle wiggle animation during sniffing
	if is_smelling and has_node("IsoNoseSprite"):
		wiggle_time += delta
		
		# Create a natural wiggle motion for the nose
		var wiggle_offset_x = sin(wiggle_time * wiggle_speed) * wiggle_intensity
		var wiggle_offset_y = cos(wiggle_time * wiggle_speed * 1.5) * (wiggle_intensity * 0.7)
		
		# Apply the wiggle animation
		$IsoNoseSprite.position.x = wiggle_offset_x
		$IsoNoseSprite.position.y += wiggle_offset_y * 0.1 # Add to the existing float animation

# Handle sprite animations
func handle_animations(delta, input_vector):
	# Update IsoNoseSprite animation based on direction
	if has_node("IsoNoseSprite"):
		if input_vector.length() > 0 and not is_smelling:
			# Map the 4 cardinal input directions to our animations
			# Right key → Southeast
			# Left key → Northwest
			# Down key → Southwest
			# Up key → Northeast
			# Determine dominant direction from input
			if abs(input_vector.x) > abs(input_vector.y):
				if input_vector.x > 0:
					# Right key pressed
					$IsoNoseSprite.play("noseFacingSouthEast")
					facing_right = true
				else:
					# Left key pressed
					$IsoNoseSprite.play("noseFacingNorthWest")
					facing_right = false
			else:
				if input_vector.y > 0:
					# Down key pressed
					$IsoNoseSprite.play("noseFacingSouthWest")
				else:
					# Up key pressed
					$IsoNoseSprite.play("noseFacingNorthEast")
		
		# Handle sprite animation - applied only to the sprite, not the entire node
		# Don't apply float animation during smelling (wiggle handles that)
		if float_animation_active and not is_smelling:
			var y_offset = 0
			if input_vector.length() > 0:
				move_time += delta
				# Bouncing animation during movement
				y_offset = - sin(move_time * 10) * 3
			else:
				# Idle bobbing animation
				idle_time += delta
				y_offset = - sin(idle_time * 2) * 2
			
			# Apply animation to sprite's offset only, not affecting the actual body position
			$IsoNoseSprite.position.y = y_offset
		elif not is_smelling:
			# Reset sprite position if animation is disabled and not smelling
			$IsoNoseSprite.position.y = 0

func start_smelling():
	is_smelling = true
	wiggle_time = 0 # Reset wiggle animation timer
	
	# Clear any pending smells and collectibles
	pending_smells = []
	pending_collectibles = []
	
	# Debug print
	if debug_mode:
		print("Started smelling action with 2-second wiggle")
	
	# Get current facing direction - we'll keep using the same sprite during wiggle
	# but we won't change to a smell-specific sprite to avoid disappearing
	
	# Start the smell timer for 2 seconds
	if has_node("SmellTimer"):
		$SmellTimer.start()
		if debug_mode:
			print("Started smell timer for " + str(smell_duration) + " seconds")
	
	# Find smells and collectibles nearby but don't process them yet
	find_pending_smells()

func _on_smell_timer_timeout():
	is_smelling = false
	
	# Debug print
	if debug_mode:
		print("Smell timer timeout - ending wiggle animation, processing detected smells and collectibles")
	
	# Reset wiggle animation
	if has_node("IsoNoseSprite"):
		$IsoNoseSprite.position.x = 0
		
		# Let the Y position be handled by normal floating
		# It will be calculated on the next frame
	
	# Now that the animation is complete, process any pending smells and collectibles
	process_pending_smells()

# Find smells nearby but don't process them yet
func find_pending_smells():
	# Debug print
	if debug_mode:
		print("Finding nearby smells and collectibles (will only process the closest one after animation)")
	
	# Get all overlapping areas
	var smell_detector = get_node_or_null("SmellDetector")
	if smell_detector:
		var overlapping_areas = smell_detector.get_overlapping_areas()
		
		if debug_mode:
			if overlapping_areas.size() > 1:
				print("Found " + str(overlapping_areas.size()) + " overlapping areas, will sort by distance")
			else:
				print("Found " + str(overlapping_areas.size()) + " overlapping areas")
		
		# Clear any previous pending items
		pending_smells = []
		pending_collectibles = []
		
		for area in overlapping_areas:
			# Check if this is a Smell object
			if area is Smell or (area.get_parent() is Smell):
				# Get the actual smell object
				var smell = area if area is Smell else area.get_parent()
				
				if debug_mode:
					print("Found smell object to process later: " + smell.smell_name)
				
				# Add to pending smells list to process after animation
				pending_smells.append(smell)
			# Check if this is a Collectible object
			elif area is Collectible or (area.get_parent() is Collectible):
				# Get the actual collectible object
				var collectible = area if area is Collectible else area.get_parent()
				
				if debug_mode:
					print("Found collectible object to process later: " + collectible.collectible_name)
				
				# Add to pending collectibles list to process after animation
				pending_collectibles.append(collectible)
		
		# Handle cases where we found items
		var found_items = false
		
		# Check if we found any smells
		if not pending_smells.is_empty():
			found_items = true
			if pending_smells.size() > 1:
				# Sort the pending smells by distance to player
				pending_smells.sort_custom(func(a, b):
					var dist_a = global_position.distance_to(a.global_position)
					var dist_b = global_position.distance_to(b.global_position)
					return dist_a < dist_b
				)
				
				if debug_mode:
					print("Sorted " + str(pending_smells.size()) + " smells by distance, closest is " + pending_smells[0].smell_name)
		
		# Check if we found any collectibles
		if not pending_collectibles.is_empty():
			found_items = true
			if pending_collectibles.size() > 1:
				# Sort the pending collectibles by distance to player
				pending_collectibles.sort_custom(func(a, b):
					var dist_a = global_position.distance_to(a.global_position)
					var dist_b = global_position.distance_to(b.global_position)
					return dist_a < dist_b
				)
				
				if debug_mode:
					print("Sorted " + str(pending_collectibles.size()) + " collectibles by distance, closest is " + pending_collectibles[0].collectible_name)
		
		if not found_items and debug_mode:
			print("No smells or collectibles found in range to process later")

# Process all pending smells and collectibles after the animation completes
func process_pending_smells():
	var processed_item = false
	
	# First try to process smells if any are pending
	if not pending_smells.is_empty():
		if debug_mode:
			print("Processing " + str(pending_smells.size()) + " pending smells, but will only detect the first one")
		
		# Only process the closest/first smell in the list
		var smell = pending_smells[0]
		
		if is_instance_valid(smell) and not smell.collected:
			if debug_mode:
				print("Processing smell: " + smell.smell_name)
			
			# Connect to the smell's signals
			if not smell.is_connected("animation_completed", _on_smell_animation_completed):
				smell.connect("animation_completed", _on_smell_animation_completed)
				
			# Connect to the smell's smell_detected signal
			if not smell.is_connected("smell_detected", _on_smell_detected):
				smell.connect("smell_detected", _on_smell_detected)
			
			# Call detect method on the smell
			if smell.has_method("detect"):
				smell.detect()
				
				# Set detected flag
				if "detected" in smell:
					smell.detected = true
				
				processed_item = true
				
				if debug_mode:
					print("Detected smell: ", smell.smell_name, " (", smell.smell_type, ")")
			else:
				if debug_mode:
					print("Smell object doesn't have detect method!")
	
	# If no smell was processed, try to process a collectible
	if not processed_item and not pending_collectibles.is_empty():
		if debug_mode:
			print("Processing " + str(pending_collectibles.size()) + " pending collectibles, but will only detect the first one")
		
		# Only process the closest/first collectible in the list
		var collectible = pending_collectibles[0]
		
		if is_instance_valid(collectible) and not collectible.collected:
			if debug_mode:
				print("Processing collectible: " + collectible.collectible_name)
			
			# Connect to the collectible's signals
			if not collectible.is_connected("animation_completed", _on_collectible_animation_completed):
				collectible.connect("animation_completed", _on_collectible_animation_completed)
				
			# Connect to the collectible's collectible_detected signal
			if not collectible.is_connected("collectible_detected", _on_collectible_detected):
				collectible.connect("collectible_detected", _on_collectible_detected)
			
			# Call detect method on the collectible
			if collectible.has_method("detect"):
				collectible.detect()
				
				# Set detected flag
				if "detected" in collectible:
					collectible.detected = true
				
				if debug_mode:
					print("Detected collectible: ", collectible.collectible_name, " (", collectible.collectible_type, ")")
			else:
				if debug_mode:
					print("Collectible object doesn't have detect method!")
	
	# Clear the pending lists
	pending_smells = []
	pending_collectibles = []

# Handle the smell_detected signal from smells
func _on_smell_detected(smell_info):
	if debug_mode:
		print("SMELL SIGNAL: Player received smell_detected with data: ", smell_info)
	
	# Get the color from the smell info
	var smell_color = smell_info.color if "color" in smell_info else default_particle_color
	
	# Emit particles from the player
	emit_particles(smell_color)

# Handle the collectible_detected signal from collectibles
func _on_collectible_detected(collectible_info):
	if debug_mode:
		print("COLLECTIBLE SIGNAL: Player received collectible_detected with data: ", collectible_info)
	
	# Get the color from the collectible info
	var collectible_color = collectible_info.color if "color" in collectible_info else default_particle_color
	
	# Emit particles from the player
	emit_particles(collectible_color)

# Emit particles with the specified color
func emit_particles(color):
	if smell_particles:
		# Update particle color
		var material = smell_particles.process_material
		material.color = color
		
		# Start emitting particles
		smell_particles.emitting = true
		
		# Create a timer to stop particles after a duration
		var timer = Timer.new()
		timer.wait_time = 2.0 # Particle emission duration
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func():
			if smell_particles:
				smell_particles.emitting = false
			timer.queue_free()
		)
		timer.start()

# New function to handle the animation_completed signal from smells
func _on_smell_animation_completed(smell_data):
	# Extract smell information from the data
	var smell_text = smell_data.message if "message" in smell_data else "Something smells..."
	var smell_type = smell_data.type if "type" in smell_data else "neutral"
	
	# Map the smell message to the new shorter texts
	if smell_type == "good":
		smell_text = "YUM"
	elif smell_type == "bad":
		smell_text = "Eeaughh..."
	elif smell_type == "epic":
		smell_text = "OooOoooh!"
	
	if debug_mode:
		print("SMELL SIGNAL: Player received smell_animation_completed with data: ", smell_data)
		print("SMELL SIGNAL: Player displaying smell message: ", smell_text)
	
	# Display the message above the player's head
	display_smell_message(smell_text, smell_type)

# New function to handle the animation_completed signal from collectibles
func _on_collectible_animation_completed(collectible_data):
	# Extract collectible information from the data
	var collectible_text = collectible_data.message if "message" in collectible_data else "Found something!"
	var collectible_type = collectible_data.type if "type" in collectible_data else "common"
	
	if debug_mode:
		print("COLLECTIBLE SIGNAL: Player received collectible_animation_completed with data: ", collectible_data)
		print("COLLECTIBLE SIGNAL: Player displaying collectible message: ", collectible_text)
	
	# Display the message above the player's head
	display_smell_message(collectible_text, collectible_type)

# Function to display smell message above the player's head
func display_smell_message(text, type):
	# Remove any existing message label
	if smell_message_label != null:
		smell_message_label.queue_free()
	
	# Create a new label
	smell_message_label = Label.new()
	smell_message_label.name = "SmellMessageLabel"
	smell_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	smell_message_label.text = text
	
	# Set font size and style
	smell_message_label.add_theme_font_size_override("font_size", 12)
	
	# Set text color based on smell type
	match type:
		"good":
			smell_message_label.add_theme_color_override("font_color", Color("ff004d")) # Green
		"bad":
			smell_message_label.add_theme_color_override("font_color", Color("ab5236")) # Red
		"epic":
			smell_message_label.add_theme_color_override("font_color", Color("00ffcc"))
		_:
			smell_message_label.add_theme_color_override("font_color", Color(1, 1, 1)) # White
	
	# Add shadow and outline for better visibility
	smell_message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	smell_message_label.add_theme_constant_override("shadow_offset_x", 1)
	smell_message_label.add_theme_constant_override("shadow_offset_y", 1)
	smell_message_label.add_theme_constant_override("outline_size", 0)
	smell_message_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	
	# Position the label above the particles
	var y_offset = -40.0
	if game_scale:
		y_offset *= game_scale.SCALE_FACTOR
	
	smell_message_label.position = Vector2(-50, y_offset)
	smell_message_label.size = Vector2(100, 30)
	
	# Make sure it's visible above everything
	smell_message_label.z_index = 1001
	
	# Add the label to the player
	add_child(smell_message_label)
	
	# Animation for the label
	var tween = create_tween()
	tween.tween_property(smell_message_label, "modulate", Color(1, 1, 1, 1), 0.3) # Fade in
	tween.tween_interval(1.4) # Show for a moment
	tween.tween_property(smell_message_label, "modulate", Color(1, 1, 1, 0), 0.3) # Fade out
	tween.tween_callback(func():
		if smell_message_label:
			smell_message_label.queue_free()
			smell_message_label = null
	)

# Alias for backwards compatibility
func check_for_smells():
	find_pending_smells()

# Update the z-index based on player's position
func update_z_index():
	# Use a fixed z-index value for the player to ensure it's always visible above map tiles
	z_index = 10
	
	# Debugging - disabled, now shown in UI debug display
	# if debug_mode and velocity.length() > 0 and position_report_timer == 0:
	# 	print("Player z-index fixed at: ", z_index)
