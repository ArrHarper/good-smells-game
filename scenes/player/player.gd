extends CharacterBody2D

# Movement constants
const MOVE_SPEED = 300
const TILE_WIDTH = 64
const TILE_HEIGHT = 32

# Animation variables
var idle_time = 0
var move_time = 0
var original_y = 0
var facing_right = true
var is_smelling = false
var smell_timer = 0
var smell_duration = 1.0

# Smell signal
signal smell_detected(smell_text, smell_type)

# Called when the node enters the scene tree for the first time
func _ready():
	original_y = position.y
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
		
		# Copy the collision shape from the player
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = $CollisionShape2D.shape.duplicate()
		smell_detector.add_child(collision_shape)
		
		add_child(smell_detector)

# Called every frame
func _process(delta):
	# Movement logic
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * MOVE_SPEED
	
	# Apply movement
	move_and_slide()
	
	# Handle animation
	if direction.length() > 0:
		move_time += delta
		# Bouncing animation during movement
		position.y = original_y - sin(move_time * 10) * 3
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
		position.y = original_y - sin(idle_time * 2) * 2
	
	# Smell ability - Space key for now, can be updated in project settings
	if Input.is_action_just_pressed("smell") and not is_smelling:
		start_smelling()

func start_smelling():
	is_smelling = true
	
	# Start the smell animation here
	var scale_tween = create_tween()
	scale_tween.tween_property($Sprite2D, "scale", Vector2(1.2, 1.2), 0.5)
	scale_tween.tween_property($Sprite2D, "scale", Vector2(1.0, 1.0), 0.5)
	
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
				# Trigger the smell
				emit_signal("smell_detected", area.smell_message, area.smell_type)
				area.collected = true
				smell_found = true
				break
	
	# If no smell found in the immediate area
	if not smell_found:
		emit_signal("smell_detected", "Nothing interesting here", "neutral")
