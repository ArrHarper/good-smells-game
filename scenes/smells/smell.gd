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
@export var particles_color: Color = Color(1, 1, 1)
var particle_system
signal animation_completed(smell_data) # Signal to notify when animation is done

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
	
	# Set up visual particles but make them hidden initially
	setup_particles()
	
	# Hide particles initially - set the visibility directly
	if particle_system:
		particle_system.emitting = false
	
	# Connect signal
	connect("body_entered", _on_body_entered)
	
	# Debug
	print("Smell initialized: " + smell_name + " (type: " + smell_type + ")")

func setup_particles():
	# Create particle effect for the smell
	particle_system = GPUParticles2D.new()
	var particles_material = ParticleProcessMaterial.new()
	
	# Configure the particle system with enhanced properties
	particles_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particles_material.emission_sphere_radius = 15.0 # Increased from 10.0
	particles_material.direction = Vector3(0, -1, 0)
	particles_material.spread = 60.0 # Increased from 45.0
	particles_material.gravity = Vector3(0, -30, 0) # Stronger upward gravity
	particles_material.initial_velocity_min = 20.0 # Increased from 10.0
	particles_material.initial_velocity_max = 40.0 # Increased from 20.0
	
	# Set color based on smell type
	if smell_type == "good":
		particles_material.color = Color(0.2, 0.8, 0.2, 0.8) # More vivid green
	elif smell_type == "bad":
		particles_material.color = Color(0.8, 0.2, 0.2, 0.8) # Red
	elif smell_type == "epic":
		particles_material.color = Color(0.8, 0.2, 0.8, 0.8) # Purple
	else:
		particles_material.color = Color(0.8, 0.8, 0.8, 0.8) # Light gray for neutral
	
	# Add scale variation to particles
	particles_material.scale_min = 1.0
	particles_material.scale_max = 2.5
	
	# Add a bit of turbulence/randomness
	particles_material.turbulence_enabled = true
	particles_material.turbulence_noise_strength = 1.0
	particles_material.turbulence_noise_scale = 1.5
	
	# Apply material and add to scene
	particle_system.process_material = particles_material
	particle_system.amount = 24 # Increased from 16
	particle_system.lifetime = 2.5 # Slightly longer lifetime
	particle_system.explosiveness = 0.2 # Add some burst effect
	particle_system.one_shot = false
	particle_system.local_coords = false
	
	# Ensure default modulate is fully visible, we'll control visibility with emitting
	particle_system.modulate = Color(1, 1, 1, 1)
	
	add_child(particle_system)

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

# New function to detect and animate the smell when player uses smell ability
func detect():
	if not detected and not collected:
		detected = true
		print("Smell detected: " + smell_name)
		
		# Show particles rising with animation
		if particle_system:
			# Set the color explicitly based on smell type
			var material = particle_system.process_material
			if smell_type == "good":
				material.color = Color(0.2, 0.8, 0.2, 0.8) # More vivid green
			elif smell_type == "bad":
				material.color = Color(0.8, 0.2, 0.2, 0.8) # Red
			elif smell_type == "epic":
				material.color = Color(0.8, 0.2, 0.8, 0.8) # Purple
			else:
				material.color = Color(0.8, 0.8, 0.8, 0.8) # Light gray for neutral
			
			# Start emitting particles immediately
			particle_system.emitting = true
			
			# Calculate particle animation offsets for isometric perspective
			var start_pos = Vector2(0, -isometric_height_offset - 10)
			var mid_pos = Vector2(0, -isometric_height_offset - 30)
			var end_pos = Vector2(0, -isometric_height_offset - 50)
			
			# Create rising and fading animation with proper sequencing
			var tween = create_tween()
			
			# First rise up more dramatically
			tween.tween_property(particle_system, "position", mid_pos, animation_duration * 0.5)
			
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
			
			# Then continue rising while fading out
			tween.tween_property(particle_system, "position", end_pos, animation_duration * 0.5)
			tween.parallel().tween_property(particle_system, "modulate", Color(1, 1, 1, 0), animation_duration * 0.5)
			
			# After animation completes, mark as collected
			tween.tween_callback(func():
				# Then mark as collected
				mark_collected()
			)

# Called when the smell animation is complete
func mark_collected():
	if not collected:
		collected = true
		print("Smell collected: " + smell_name)
		
		# Here we can add any additional logic needed when a smell is collected
		# For example, update a score counter, play a sound, etc. 