extends CanvasLayer

func _ready():
	# Hide smell message initially
	$SmellLabel.visible = false

func show_smell_message(text, type):
	$SmellLabel.text = text
	$SmellLabel.visible = true
	
	# Change color based on type
	match type:
		"good":
			$SmellLabel.add_theme_color_override("font_color", Color(0, 1, 0))
		"bad":
			$SmellLabel.add_theme_color_override("font_color", Color(1, 0, 0))
		_:
			$SmellLabel.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Hide message after a delay
	$MessageTimer.start()

func _on_message_timer_timeout():
	$SmellLabel.visible = false
