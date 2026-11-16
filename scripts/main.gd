extends Control
## Entry point for the playable tutorial.

@export var progress_path: String = "user://stage_progress.cfg"

func _ready() -> void:
	get_node("/root/Sfx").stop_combat()
	get_window().min_size = Vector2i(1152, 648)
	print("FirstGodotGameTowerDefence: Godot + GDScript ready.")
	$Center/Menu/Start.pressed.connect(_start_tutorial)
	$Center/Menu/Levels/Level1.pressed.connect(_start_stage_one)
	$Center/Menu/Levels/Level2.pressed.connect(_start_stage_two)
	var progress := ConfigFile.new()
	if progress.load(progress_path) == OK and progress.get_value("levels", "stage_one_complete", false):
		$Center/Menu/Levels/Level1.text = "✓ Level 1"
		$Center/Menu/Levels/Line1.modulate = Color("ffd474")
		$Center/Menu/Levels/Level2.disabled = false
		$Center/Menu/Levels/Level2.text = "✓ Level 2" if progress.get_value("levels", "stage_two_complete", false) else "Level 2"
		$Center/Menu/Levels/Level2.tooltip_text = "Play Level 2"
	$Center/Menu/Quit.pressed.connect(Music.quit_game)


func _start_tutorial() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")


func _start_stage_one() -> void:
	get_tree().change_scene_to_file("res://scenes/stage_one.tscn")

func _start_stage_two() -> void:
	get_tree().change_scene_to_file("res://scenes/stage_two.tscn")
