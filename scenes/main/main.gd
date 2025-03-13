extends Node2D

# UI scene for displaying messages
var ui_scene = preload("res://scenes/UI/UI.tscn")
var ui_instance

func _ready():
	# Create UI instance
	ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	
	# Connect player's smell detection signal to UI
	if $nose:
		$nose.connect("smell_detected", _on_smell_detected)

# Called when the player detects a smell
func _on_smell_detected(smell_text, smell_type):
	# Pass the smell message to the UI
	ui_instance.show_smell_message(smell_text, smell_type) 