extends Node

# Paths to different scenes
const MAIN_SCENE_PATH = "res://scenes/main/main.tscn"
const TESTING_SCENE_PATH = "res://scenes/main/testing.tscn"

# Switch to the main scene
func switch_to_main():
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	print("Switched to main scene")

# Switch to the testing scene
func switch_to_testing():
	get_tree().change_scene_to_file(TESTING_SCENE_PATH)
	print("Switched to testing scene")
	
# Get current scene path
func get_current_scene_path() -> String:
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_filename = current_scene.scene_file_path
		return scene_filename
	return ""

# Check if currently in testing scene
func is_testing_scene() -> bool:
	return get_current_scene_path() == TESTING_SCENE_PATH

# Check if currently in main scene
func is_main_scene() -> bool:
	return get_current_scene_path() == MAIN_SCENE_PATH