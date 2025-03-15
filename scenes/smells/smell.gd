extends Area2D
class_name Smell

# Smell properties
@export var smell_name: String = "Generic Smell"
@export_enum("good", "bad", "epic", "neutral") var smell_type: String = "neutral"
@export var smell_message: String = "You smell something..."
@export var points: int = 0
@export var collected: bool = false
@export var detected: bool = false

# Visual representation variables
@export var particles_color: Color = Color("#CCCCCCE5") # Default color that can be overridden in editor
signal animation_completed(smell_data) # Signal to notify when animation is done
signal smell_detected(smell_info) # New signal to notify player to emit particles

# Isometric position adjustments - helps with correct positioning on isometric grid
@export var isometric_height_offset: float = 0.0 # Positive values will raise the smell's visual position

# Animation timing
var animation_duration = 1.6 # Total animation time in seconds
var message_delay = 0.8 # Time to wait before showing the message

func _ready():
	# Add to smell group so player can detect it
	add_to_group("smell")
	
	# Set up collision shape
	if not get_node_or_null("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 16
		collision.shape = shape
		add_child(collision)
	
	# Connect signal
	connect("body_entered", _on_body_entered)
	
	# Debug
	print("Smell initialized: " + smell_name + " (type: " + smell_type + ")")

func _on_body_entered(body):
	if body is CharacterBody2D and not collected:
		# This function no longer immediately collects the smell.
		# The player now needs to use their smell ability to detect it.
		print("Player entered smell area: " + smell_name)

# Public methods for the smell object
func get_smell_text():
	return smell_message

func get_smell_type():
	return smell_type

# Get the color for this smell type
func get_smell_color():
	# Use custom color if set
	if particles_color != Color("#CCCCCCE5"):
		return particles_color
	
	# Otherwise use type-based color
	if smell_type == "good":
		return Color("#33CC33E5") # Bright green with high alpha
	elif smell_type == "bad":
		return Color("#CC3333E5") # Bright red with high alpha
	elif smell_type == "epic":
		return Color("#CC33CCE5") # Bright purple with high alpha
	else:
		return Color("#CCCCCCE5") # Light gray with high alpha

# New function to detect and animate the smell when player uses smell ability
func detect():
	if not detected and not collected:
		detected = true
		print("Smell detected: " + smell_name)
		
		# Instead of handling particles here, emit a signal to the player
		# with all relevant smell information
		var smell_info = {
			"name": smell_name,
			"type": smell_type,
			"message": smell_message,
			"color": get_smell_color()
		}
		
		# Emit signal for the player to handle particles
		emit_signal("smell_detected", smell_info)
		
		# Create a timer to delay the message
		var timer = Timer.new()
		timer.wait_time = message_delay
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func():
			# Emit the smell signal after delay
			emit_signal("animation_completed", {"message": smell_message, "type": smell_type})
			timer.queue_free()
		)
		timer.start()
		
		# After animation completes, mark as collected
		var tween = create_tween()
		tween.tween_interval(animation_duration)
		tween.tween_callback(func():
			mark_collected()
		)

# Called when the smell animation is complete
func mark_collected():
	if not collected:
		collected = true
		print("Smell collected: " + smell_name)
		
		# Here we can add any additional logic needed when a smell is collected
		# For example, update a score counter, play a sound, etc. 