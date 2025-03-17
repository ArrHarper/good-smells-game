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
		
	# Handle collision with other objects
	queue_free()

func _on_timer_timeout():
	# Destroy projectile after its lifetime expires
	queue_free()