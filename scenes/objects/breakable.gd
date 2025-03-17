extends StaticBody2D

var exploded = false

func _ready():
	# Set up breakable properties
	pass

# Called when a projectile collides with this breakable
func handle_projectile_collision(projectile):
	if not exploded:
		explode()
		# Don't affect the projectile's path, it passes through

func explode():
	exploded = true
	# Play explosion particles
	$ExplosionParticles.emitting = true
	
	# Hide sprite and disable collision
	$Sprite2D.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Set up a timer to free the object after particles finish
	var timer = Timer.new()
	timer.wait_time = $ExplosionParticles.lifetime + 0.1
	timer.one_shot = true
	timer.connect("timeout", queue_free)
	add_child(timer)
	timer.start()