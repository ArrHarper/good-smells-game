extends CharacterBody2D

# Movement constants
const MOVE_SPEED = 300
# Isometric tile dimensions - update based on your specific tileset
const TILE_WIDTH = 32
const TILE_HEIGHT = 16

# Animation variables
var idle_time = 0
var move_time = 0
var original_y = 0
var base_position_y = 0  # Store the base Y position without animation offset
var facing_right = true
var is_smelling = false
var smell_timer = 0
var smell_duration = 1.0
var float_animation_active = true  # Control whether player sprite floats

# Debug mode - set to false when finished testing
var debug_mode = true

# Smell signal
signal smell_detected(smell_text, smell_type)

# Add tracking for last position to avoid excessive logging
var last_reported_tile_pos = Vector2i(-999, -999)
var position_report_timer = 0
var position_report_interval = 0.5  # Report position at most every half second

# Called when the node enters the scene tree for the first time
func _ready():
	original_y = position.y
	base_position_y = position.y  # Initialize base position
	
	# Set up smell action timer
	setup_smell_timer()
	
	# Set up smell detector
	setup_smell_detector()
	
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
		shape.radius = 64  # Match with visual smell radius
		collision_shape.shape = shape
		smell_detector.add_child(collision_shape)
		
		add_child(smell_detector)

# Called every frame
func _process(delta):
	# Get input vector
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Convert input to isometric movement direction using the utility class
	var isometric_direction = IsometricUtils.get_isometric_direction(input_vector)
	
	# Apply movement
	velocity = isometric_direction * MOVE_SPEED if input_vector != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	
	# Update base Y position when we move vertically
	if abs(input_vector.y) > 0:
		base_position_y = global_position.y
	
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
				print("Player tile position: ", current_tile_pos, " | World position: ", global_position)
				last_reported_tile_pos = current_tile_pos
		
	# Smell ability - Space key for now, can be updated in project settings
	if Input.is_action_just_pressed("smell") and not is_smelling:
		start_smelling()

# Handle sprite animations
func handle_animations(delta, input_vector):
	# Update IsoNoseSprite animation based on direction
	if has_node("IsoNoseSprite"):
		if input_vector.length() > 0:
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
		if float_animation_active:
			var y_offset = 0
			if input_vector.length() > 0:
				move_time += delta
				# Bouncing animation during movement
				y_offset = -sin(move_time * 10) * 3
			else:
				# Idle bobbing animation
				idle_time += delta
				y_offset = -sin(idle_time * 2) * 2
			
			# Apply animation to sprite's offset only, not affecting the actual body position
			$IsoNoseSprite.position.y = y_offset
		else:
			# Reset sprite position if animation is disabled
			$IsoNoseSprite.position.y = 0

func start_smelling():
	is_smelling = true
	
	# Start the smell animation here
	if has_node("IsoNoseSprite"):
		# Store current animation
		var current_anim = $IsoNoseSprite.animation
		
		# Play the smell animation
		if current_anim.begins_with("noseFacing"):
			# Extract the direction from the current animation
			var direction = current_anim.replace("noseFacing", "")
			# Play the corresponding smell animation
			$IsoNoseSprite.play("smell" + direction)
	
	# Activate the smell particles
	if has_node("SmellParticles"):
		$SmellParticles.emitting = true
	
	# Start the smell timer
	if has_node("SmellTimer"):
		$SmellTimer.start()
	
	# Check for smells nearby
	check_for_smells()

func _on_smell_timer_timeout():
	is_smelling = false
	
	# Return to normal animation
	if has_node("IsoNoseSprite"):
		# Get the current animation
		var current_anim = $IsoNoseSprite.animation
		
		if current_anim.begins_with("smell"):
			# Extract the direction from the current smell animation
			var direction = current_anim.replace("smell", "")
			# Return to normal facing animation
			$IsoNoseSprite.play("noseFacing" + direction)
	
	# Stop the smell particles
	if has_node("SmellParticles"):
		$SmellParticles.emitting = false

func check_for_smells():
	# Get all overlapping areas
	var smell_detector = get_node_or_null("SmellDetector")
	if smell_detector:
		var overlapping_areas = smell_detector.get_overlapping_areas()
		
		for area in overlapping_areas:
			if area.is_in_group("smell"):
				# If this is a smell area, get its information
				var smell_text = "Something smells..."
				var smell_type = "neutral"
				
				if area.has_method("get_smell_text"):
					smell_text = area.get_smell_text()
				
				if area.has_method("get_smell_type"):
					smell_type = area.get_smell_type()
				
				# Emit the signal with smell information
				emit_signal("smell_detected", smell_text, smell_type)
				
				# Debug output
				if debug_mode:
					print("Detected smell: ", smell_text, " (", smell_type, ")")
				
				# Only report the first smell for now
				# (Could aggregate all smells if we want to show multiple)
				break

# Update the z-index based on player's position
func update_z_index():
	# Use a fixed z-index value for the player to ensure it's always visible above map tiles
	z_index = 10
	
	# Debugging
	if debug_mode and velocity.length() > 0 and position_report_timer == 0:
		print("Player z-index fixed at: ", z_index)
