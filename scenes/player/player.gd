extends CharacterBody2D

# Movement constants
const MOVE_SPEED = 300
# Isometric tile dimensions - update based on your specific tileset
const TILE_WIDTH = 32
const TILE_HEIGHT = 16

# 21x21 map with 0-based indexing means tiles go from 0 to 20
var min_tile_x = 0  # Leftmost tile
var max_tile_x = 20  # Rightmost tile 
var min_tile_y = 0  # Topmost tile
var max_tile_y = 20  # Bottommost tile

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

# Called when the node enters the scene tree for the first time
func _ready():
	original_y = position.y
	base_position_y = position.y  # Initialize base position
	
	# Set up smell action timer
	setup_smell_timer()
	
	# Set up smell detector
	setup_smell_detector()
	
	# Try to find map boundaries from parent scene
	detect_map_boundaries()
	
	# Start playing the default animation
	if has_node("IsoNoseSprite"):
		$IsoNoseSprite.play("noseFacingSouthEast")
	
	# Print initial position for debugging
	if debug_mode:
		print("Initial position: ", position)
		var initial_tile = Iso.world_to_tile(position, TILE_WIDTH, TILE_HEIGHT)
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

# Try to detect map boundaries from the parent scene
func detect_map_boundaries():
	# Get reference to the main scene and get boundaries from it if possible
	var main_scene = get_parent()
	if main_scene and main_scene.has_method("get_map_boundaries"):
		var bounds = main_scene.get_map_boundaries()
		min_tile_x = bounds.min_x
		max_tile_x = bounds.max_x
		min_tile_y = bounds.min_y
		max_tile_y = bounds.max_y
		
		if debug_mode:
			print("Updated map boundaries from main scene: ", bounds)
	else:
		# Use default map boundaries (21x21 map, anchored at top instead of center)
		min_tile_x = 0
		max_tile_x = 20
		min_tile_y = 0
		max_tile_y = 20
		
		if debug_mode:
			print("Using default map boundaries: ", min_tile_x, "-", max_tile_x, ", ", min_tile_y, "-", max_tile_y)
			
	# Adjust player position to be relative to the anchored map
	adjust_to_centered_map()

# Adjust player position to work with the centered map
func adjust_to_centered_map():
	if get_parent() and get_parent().has_node("IsometricMap"):
		# Get the map's position, which is the offset for the map
		var map_position = get_parent().get_node("IsometricMap").position
		
		# Adjust current player position to be relative to the map
		if debug_mode:
			print("Player position before adjustment: ", position)
			print("Map position: ", map_position)
			
		# Convert player position to tile coordinates for validation
		var player_tile = Iso.world_to_tile(position, TILE_WIDTH, TILE_HEIGHT)
		
		# Check if player is within allowed boundaries
		if not Iso.is_within_boundaries(
			position,
			min_tile_x, max_tile_x,
			min_tile_y, max_tile_y,
			TILE_WIDTH, TILE_HEIGHT
		):
			# If not, adjust to a valid position
			position = Iso.get_valid_position(
				position,
				min_tile_x, max_tile_x,
				min_tile_y, max_tile_y,
				TILE_WIDTH, TILE_HEIGHT
			)
			
		if debug_mode:
			print("Player position after adjustment: ", position)
			player_tile = Iso.world_to_tile(position, TILE_WIDTH, TILE_HEIGHT)
			print("Player is at tile: ", player_tile)

# Called every frame
func _process(delta):
	# Get input vector
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Convert input to isometric movement direction using the utility class
	var isometric_direction = Iso.get_isometric_direction(input_vector)
	
	# Apply movement
	velocity = isometric_direction * MOVE_SPEED if input_vector != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	
	# Update base Y position when we move vertically
	if abs(input_vector.y) > 0:
		base_position_y = global_position.y
	
	# Check boundaries and limit movement
	handle_boundary_checks()
	
	# Handle animations
	handle_animations(delta, input_vector, isometric_direction)
		
	# Smell ability - Space key for now, can be updated in project settings
	if Input.is_action_just_pressed("smell") and not is_smelling:
		start_smelling()

# Check and enforce boundaries
func handle_boundary_checks():
	# Check if we're outside the boundaries and move back if needed
	var current_position = global_position
	
	# Use the utility class for tile coordinate conversion
	var current_tile = Iso.world_to_tile(current_position, TILE_WIDTH, TILE_HEIGHT)
	
	# Debug to see current position and tile
	if debug_mode and velocity != Vector2.ZERO:
		print("Current position: ", current_position, " Current tile: ", current_tile)
	
	# Check if we've moved outside allowed tile coordinates using the utility class
	if not Iso.is_within_boundaries(
		current_position, 
		min_tile_x, max_tile_x, 
		min_tile_y, max_tile_y,
		TILE_WIDTH, TILE_HEIGHT
	):
		if debug_mode:
			print("OUT OF BOUNDS! Limiting movement")
		
		# Get a valid position within boundaries using the utility class
		var new_pos = Iso.get_valid_position(
			current_position,
			min_tile_x, max_tile_x,
			min_tile_y, max_tile_y,
			TILE_WIDTH, TILE_HEIGHT
		)
		
		global_position = new_pos
		base_position_y = global_position.y  # Update base Y when hitting boundary

# Handle sprite animations
func handle_animations(delta, input_vector, isometric_direction):
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
		var scale_tween = create_tween()
		scale_tween.tween_property($IsoNoseSprite, "scale", Vector2(1.2, 1.2), 0.5)
		scale_tween.tween_property($IsoNoseSprite, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Add visual indicator for the "smell radius"
	setup_smell_radius()
	
	# Show the smell radius with animation
	if has_node("SmellRadius"):
		$SmellRadius.scale = Vector2.ZERO
		var radius_tween = create_tween()
		radius_tween.tween_property($SmellRadius, "scale", Vector2(1, 1), 0.5)
		radius_tween.tween_property($SmellRadius, "scale", Vector2(0, 0), 0.5)
	
	# Start the smell timer
	$SmellTimer.start()

# Setup the visual smell radius indicator
func setup_smell_radius():
	var smell_radius = 64  # Match with smell detector radius
	if not has_node("SmellRadius"):
		var radius_indicator = Node2D.new()
		radius_indicator.name = "SmellRadius"
		
		# Create a simple circle visual for the radius
		var radius_circle = Control.new()
		radius_circle.name = "RadiusCircle"
		radius_indicator.add_child(radius_circle)
		
		# Draw the circle in _process
		radius_circle.set_script(GDScript.new())
		radius_circle.get_script().source_code = """
extends Control

func _draw():
	draw_circle(Vector2.ZERO, %s, Color(0.5, 0.5, 1.0, 0.3))
	draw_arc(Vector2.ZERO, %s, 0, TAU, 32, Color(0.5, 0.5, 1.0, 0.7), 2)

func _process(_delta):
	queue_redraw()
""" % [smell_radius, smell_radius]
		
		add_child(radius_indicator)

func _on_smell_timer_timeout():
	is_smelling = false
	# Check for smells in the area
	check_for_smells()

func check_for_smells():
	# We'll use the Area2D collision system for detection
	# Use the SmellDetector Area2D child node instead of the CharacterBody2D
	
	var smell_found = false
	
	# Get all overlapping areas from our detector
	if has_node("SmellDetector"):
		var areas = $SmellDetector.get_overlapping_areas()
		
		# Check if any of the overlapping areas are smells
		for area in areas:
			if area is Smell and not area.collected:
				# Connect to animation completed signal if not already connected
				if not area.is_connected("animation_completed", _on_smell_animation_completed):
					area.connect("animation_completed", _on_smell_animation_completed)
				
				# Call the detect function to start animation
				area.detect()
				
				# No longer emitting the smell signal here - it will be emitted after animation
				smell_found = true
				break
	
	# If no smell found in the immediate area
	if not smell_found:
		emit_signal("smell_detected", "Nothing interesting here", "neutral")

# New function to handle the smell animation completion
func _on_smell_animation_completed(smell_data):
	# Now emit the smell signal with the message and type
	emit_signal("smell_detected", smell_data.message, smell_data.type)
