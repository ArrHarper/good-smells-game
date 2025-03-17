extends StaticBody2D

func _ready():
	# Set up wall properties
	pass

# Called on collision with an Area2D
func handle_projectile_collision(projectile):
	# Calculate reflection direction
	var normal = (projectile.global_position - global_position).normalized()
	projectile.direction = projectile.direction.bounce(normal)
	
	# We tell the projectile to despawn after bouncing by triggering timer
	projectile.get_node("Timer").start(0.5)