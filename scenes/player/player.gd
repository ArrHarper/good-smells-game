extends CharacterBody2D

# Movement constants
const MOVE_SPEED = 300
const TILE_WIDTH = 64
const TILE_HEIGHT = 32

# Tilemap boundaries - defines the allowed area for movement
const MIN_TILE_X = 0  # Leftmost tile
const MAX_TILE_X = 4  # Rightmost tile (5 tiles wide)
const MIN_TILE_Y = -6  # Adjusted to match the top of the green area
const MAX_TILE_Y = -1  # Adjusted to match the bottom of the green area

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
	# Create timer for smell action
	var timer = Timer.new()
	timer.name = "SmellTimer"
	timer.wait_time = smell_duration
	timer.one_shot = true
	timer.connect("timeout", _on_smell_timer_timeout)
	add_child(timer)
	
	# Create smell detector area if it doesn't exist
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
	
	# Print initial position for debugging
	if debug_mode:
		print("Initial position: ", position)
		var initial_tile = world_to_tile_coords(position)
		print("Initial tile: ", initial_tile)

# Convert world position to tilemap coordinates
# This function translates the character's world position to tile coordinates
func world_to_tile_coords(world_pos):
	# Calculate tile coordinates based on tile dimensions
	var tile_x = int(floor(world_pos.x / TILE_WIDTH))
	var tile_y = int(floor(world_pos.y / TILE_HEIGHT))
	
	return Vector2i(tile_x, tile_y)

# Called every frame
func _process(delta):
	# Movement logic
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Basic movement implementation - apply directly
	velocity = direction * MOVE_SPEED
	
	# Apply movement
	move_and_slide()
	
	# Update base Y position when we move vertically
	if abs(direction.y) > 0:
		base_position_y = global_position.y
	
	# Now check if we've moved into an invalid area and move back if needed
	var current_position = global_position
	var current_tile = world_to_tile_coords(current_position)
	
	# Debug to see current position and tile
	if debug_mode:
		print("Current position: ", current_position, " Current tile: ", current_tile)
	
	# Check if we've moved outside allowed tile coordinates
	var out_of_bounds = false
	if current_tile.x < MIN_TILE_X or current_tile.x > MAX_TILE_X or current_tile.y < MIN_TILE_Y or current_tile.y > MAX_TILE_Y:
		out_of_bounds = true
	
	# If out of bounds, move back to previous position
	if out_of_bounds:
		if debug_mode:
			print("OUT OF BOUNDS! Limiting movement")
			
		# Calculate where the player should be moved back to
		if current_tile.x < MIN_TILE_X:
			global_position.x = MIN_TILE_X * TILE_WIDTH + TILE_WIDTH / 2
		elif current_tile.x > MAX_TILE_X:
			global_position.x = MAX_TILE_X * TILE_WIDTH + TILE_WIDTH / 2
			
		if current_tile.y < MIN_TILE_Y:
			global_position.y = MIN_TILE_Y * TILE_HEIGHT + TILE_HEIGHT / 2
			base_position_y = global_position.y  # Update base Y when hitting boundary
		elif current_tile.y > MAX_TILE_Y:
			global_position.y = MAX_TILE_Y * TILE_HEIGHT + TILE_HEIGHT / 2
			base_position_y = global_position.y  # Update base Y when hitting boundary
	
	# Handle sprite animation - applied only to the sprite, not the entire node
	if float_animation_active:
		var y_offset = 0
		if direction.length() > 0:
			move_time += delta
			# Bouncing animation during movement
			y_offset = -sin(move_time * 10) * 3
			
			# Flip sprite based on direction
			if direction.x > 0:
				facing_right = true
				$Sprite2D.flip_h = false
			elif direction.x < 0:
				facing_right = false
				$Sprite2D.flip_h = true
		else:
			# Idle bobbing animation
			idle_time += delta
			y_offset = -sin(idle_time * 2) * 2
		
		# Apply animation to sprite's offset only, not affecting the actual body position
		$Sprite2D.position.y = y_offset
	else:
		# Reset sprite position if animation is disabled
		$Sprite2D.position.y = 0
		
		# Still handle sprite flipping for direction
		if direction.x > 0:
			facing_right = true
			$Sprite2D.flip_h = false
		elif direction.x < 0:
			facing_right = false
			$Sprite2D.flip_h = true
	
	# Smell ability - Space key for now, can be updated in project settings
	if Input.is_action_just_pressed("smell") and not is_smelling:
		start_smelling()

func start_smelling():
	is_smelling = true
	
	# Start the smell animation here
	var scale_tween = create_tween()
	scale_tween.tween_property($Sprite2D, "scale", Vector2(1.2, 1.2), 0.5)
	scale_tween.tween_property($Sprite2D, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Add visual indicator for the "smell radius"
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
	
	# Show the smell radius with animation
	if has_node("SmellRadius"):
		$SmellRadius.scale = Vector2.ZERO
		var radius_tween = create_tween()
		radius_tween.tween_property($SmellRadius, "scale", Vector2(1, 1), 0.5)
		radius_tween.tween_property($SmellRadius, "scale", Vector2(0, 0), 0.5)
	
	# Start the smell timer
	$SmellTimer.start()

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
