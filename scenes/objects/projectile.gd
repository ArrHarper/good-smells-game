extends Area2D

var speed = 400
var direction = Vector2.RIGHT
var from_player = true

func _ready():
	# Give the projectile a random color
	var color = Color(randf(), randf(), randf())
	$MeshInstance2D.modulate = color

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body is Player and from_player:
		# Ignore collision with the player who fired it
		return
		
	# Handle wall collisions - these should bounce the projectile
	if body.has_method("handle_projectile_collision"):
		body.handle_projectile_collision(self)
		
		# If it's a breakable, we continue moving (no return)
		# If it's a wall, we want to bounce but NOT destroy the projectile (handled in wall.gd)
		if body.get_script().get_path().find("wall.gd") != -1:
			return
	
	# If it's not a special object with collision handling or it's a breakable,
	# destroy the projectile
	queue_free()

func _on_timer_timeout():
	# Destroy projectile after its lifetime expires
	queue_free()