extends CharacterBody2D
class_name Player

# Movement constants
const MOVE_SPEED = 300
# Isometric tile dimensions
const TILE_WIDTH = 32
const TILE_HEIGHT = 16

# Player movement properties
var base_speed = 150
var current_speed = base_speed
var is_moving = false

# Smell detection
var is_smelling = false
var smell_duration = 2.0 # Duration of the smell action in seconds
var pending_smells = [] # List of smell objects to process
signal smell_detected(smell_text, smell_type) # Signal when a smell is detected

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
		var initial_tile = IsometricUtils.world_to_tile(position, TILE_WIDTH, TILE_HEIGHT)
		print("Initial tile: ", initial_tile)

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
		
		# Create a circle shape with 64px radius for smell detection
		var collision_shape = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 64 # Match with visual smell radius
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
		material.color = Color(0.9, 0.9, 1.0, 0.8)
		
		particles.process_material = material
		particles.amount = 24
		particles.lifetime = 1.0
		particles.emitting = false
		
		add_child(particles)

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
			var current_tile_pos = IsometricUtils.world_to_tile(global_position, TILE_WIDTH, TILE_HEIGHT)
			
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
	
	# Clear any pending smells
	pending_smells = []
	
	# Debug print
	if debug_mode:
		print("Started smelling action with 2-second wiggle")
	
	# Get current facing direction - we'll keep using the same sprite during wiggle
	# but we won't change to a smell-specific sprite to avoid disappearing
	
	# Activate the smell particles
	if has_node("SmellParticles"):
		$SmellParticles.emitting = true
		if debug_mode:
			print("Activated smell particles")
	
	# Start the smell timer for 2 seconds
	if has_node("SmellTimer"):
		$SmellTimer.start()
		if debug_mode:
			print("Started smell timer for " + str(smell_duration) + " seconds")
	
	# Find smells in the area but don't process them yet, store them for later
	find_pending_smells()

func _on_smell_timer_timeout():
	is_smelling = false
	
	# Debug print
	if debug_mode:
		print("Smell timer timeout - ending wiggle animation, processing detected smells")
	
	# Reset wiggle animation
	if has_node("IsoNoseSprite"):
		$IsoNoseSprite.position.x = 0
		
		# Let the Y position be handled by normal floating
		# It will be calculated on the next frame
	
	# Stop the smell particles
	if has_node("SmellParticles"):
		$SmellParticles.emitting = false
	
	# Now that the animation is complete, process any pending smells
	process_pending_smells()

# Find smells nearby but don't process them yet
func find_pending_smells():
	# Debug print
	if debug_mode:
		print("Finding nearby smells (to be processed after animation)")
	
	# Get all overlapping areas
	var smell_detector = get_node_or_null("SmellDetector")
	if smell_detector:
		var overlapping_areas = smell_detector.get_overlapping_areas()
		
		if debug_mode:
			print("Found " + str(overlapping_areas.size()) + " overlapping areas")
		
		# Clear any previous pending smells
		pending_smells = []
		
		for area in overlapping_areas:
			# Check if this is a Smell object
			if area is Smell or (area.get_parent() is Smell):
				# Get the actual smell object
				var smell = area if area is Smell else area.get_parent()
				
				if debug_mode:
					print("Found smell object to process later: " + smell.smell_name)
				
				# Add to pending smells list to process after animation
				pending_smells.append(smell)
		
		if pending_smells.is_empty() and debug_mode:
			print("No smell objects found in range to process later")

# Process all pending smells after the animation completes
func process_pending_smells():
	if pending_smells.is_empty():
		if debug_mode:
			print("No pending smells to process")
		return
	
	if debug_mode:
		print("Processing " + str(pending_smells.size()) + " pending smells")
	
	for smell in pending_smells:
		if is_instance_valid(smell) and not smell.collected:
			if debug_mode:
				print("Processing smell: " + smell.smell_name)
			
			# Connect to the smell's animation_completed signal if it exists
			if not smell.is_connected("animation_completed", _on_smell_animation_completed):
				smell.connect("animation_completed", _on_smell_animation_completed)
			
			# Call detect method on the smell
			if smell.has_method("detect"):
				smell.detect()
				
				# Set detected flag
				if "detected" in smell:
					smell.detected = true
				
				# Note: We no longer need to emit the signal here as it will be handled by the connected callback
				if debug_mode:
					print("Detected smell: ", smell.smell_name, " (", smell.smell_type, ")")
			else:
				if debug_mode:
					print("Smell object doesn't have detect method!")
	
	# Clear the pending smells list
	pending_smells = []

# New function to handle the animation_completed signal from smells
func _on_smell_animation_completed(smell_data):
	# Extract smell information from the data
	var smell_text = smell_data.message if "message" in smell_data else "Something smells..."
	var smell_type = smell_data.type if "type" in smell_data else "neutral"
	
	if debug_mode:
		print("SMELL SIGNAL: Player received smell_animation_completed with data: ", smell_data)
		print("SMELL SIGNAL: Player emitting smell_detected signal with:")
		print("SMELL SIGNAL: - Message: '" + smell_text + "'")
		print("SMELL SIGNAL: - Type: '" + smell_type + "'")
	
	# Emit the signal with smell information
	emit_signal("smell_detected", smell_text, smell_type)

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
