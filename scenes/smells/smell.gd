extends Area2D
class_name Smell

# Smell properties
@export var smell_name: String = "Generic Smell"
@export_enum("good", "bad", "epic", "neutral") var smell_type: String = "neutral"
@export var smell_message: String = "You smell something..."
@export var points: int = 0
@export var collected: bool = false

# Visual representation variables
@export var particles_color: Color = Color(1, 1, 1)
var particle_system

func _ready():
	# Set up collision shape
	if not get_node_or_null("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 16
		collision.shape = shape
		add_child(collision)
	
	# Set up visual particles
	setup_particles()
	
	# Connect signal
	connect("body_entered", _on_body_entered)

func setup_particles():
	# Create particle effect for the smell
	particle_system = GPUParticles2D.new()
	var particles_material = ParticleProcessMaterial.new()
	
	# Configure the particle system
	particles_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particles_material.emission_sphere_radius = 10.0
	particles_material.direction = Vector3(0, -1, 0)
	particles_material.spread = 45.0
	particles_material.gravity = Vector3(0, -20, 0)
	particles_material.initial_velocity_min = 10.0
	particles_material.initial_velocity_max = 20.0
	particles_material.color = particles_color
	
	# Apply material and add to scene
	particle_system.process_material = particles_material
	particle_system.amount = 16
	particle_system.lifetime = 2.0
	particle_system.local_coords = false
	add_child(particle_system)

func _on_body_entered(body):
	if body is CharacterBody2D and not collected:
		# Only interact with the player
		if body.has_signal("smell_detected"):
			body.emit_signal("smell_detected", smell_message, smell_type)
			collected = true
			
			# Visual feedback
			if particle_system:
				# Create collection effect
				var tween = create_tween()
				tween.tween_property(particle_system, "modulate", Color(1, 1, 1, 0), 1.0)
				tween.tween_callback(queue_free) 