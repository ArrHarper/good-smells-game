extends Node

# Paths to different scenes
const MAIN_SCENE_PATH = "res://scenes/main/main.tscn"
const TESTING_SCENE_PATH = "res://scenes/main/testing.tscn"
const TESTING2_SCENE_PATH = "res://scenes/main/testing2.tscn"

# Switch to the main scene
func switch_to_main():
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	print("Switched to main scene")

# Switch to the testing scene
func switch_to_testing():
	get_tree().change_scene_to_file(TESTING_SCENE_PATH)
	print("Switched to testing scene")
	
# Switch to the testing2 scene
func switch_to_testing2():
	get_tree().change_scene_to_file(TESTING2_SCENE_PATH)
	print("Switched to testing2 scene")
	
# Cycle through the available scenes
func cycle_scenes():
	var current_path = get_current_scene_path()
	
	if current_path == MAIN_SCENE_PATH:
		switch_to_testing()
	elif current_path == TESTING_SCENE_PATH:
		switch_to_testing2()
	else:
		switch_to_main()
	
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

# Check if currently in testing2 scene
func is_testing2_scene() -> bool:
	return get_current_scene_path() == TESTING2_SCENE_PATH

# Check if currently in main scene
func is_main_scene() -> bool:
	return get_current_scene_path() == MAIN_SCENE_PATH